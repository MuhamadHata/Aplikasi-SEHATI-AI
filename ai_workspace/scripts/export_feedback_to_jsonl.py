#!/usr/bin/env python3
"""
export_feedback_to_jsonl.py
===========================
Mengambil koreksi nutrisi user dari Supabase (tabel ai_feedback),
memvalidasinya, lalu mengkonversinya ke format JSONL untuk fine-tuning Gemini.

Filosofi:
  Koreksi user → JSONL training data → Fine-tune Gemini
  Pengetahuan akhirnya tersimpan di BOBOT MODEL AI, bukan database.

Penggunaan:
  python scripts/export_feedback_to_jsonl.py [--dry-run] [--min-records 10]

Requirements:
  pip install supabase python-dotenv
"""

import json
import argparse
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional

# ── Setup logging ─────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S',
)
log = logging.getLogger(__name__)

# ── Paths ─────────────────────────────────────────────────────────────────
WORKSPACE_DIR = Path(__file__).parent.parent
DATASET_DIR   = WORKSPACE_DIR / "finetuned_datasets"
TRAIN_JSONL   = DATASET_DIR / "train.jsonl"
LOG_DIR       = WORKSPACE_DIR / "logs"

# ── Validasi range nutrisi (anti noise/outlier) ───────────────────────────
NUTRISI_RANGES = {
    "calories":    (0,   5000),   # kkal
    "protein":     (0,   500),    # gram
    "carbs":       (0,   700),    # gram
    "fat":         (0,   500),    # gram
    "fiber":       (0,   200),    # gram
    "sugarGrams":  (0,   400),    # gram
    "caffeineMg":  (0,   1500),   # mg
}


def load_supabase_client():
    """Load Supabase service client (butuh service_role untuk bypass RLS)."""
    try:
        import os
        from dotenv import load_dotenv
        load_dotenv(WORKSPACE_DIR / ".env")

        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_SERVICE_KEY")  # BUKAN anon key!

        if not url or not key:
            raise ValueError(
                "Set SUPABASE_URL dan SUPABASE_SERVICE_KEY di .env\n"
                "Dapatkan service_role key dari: Supabase Dashboard → Settings → API"
            )

        from supabase import create_client
        return create_client(url, key)
    except ImportError:
        log.error("Jalankan: pip install supabase python-dotenv")
        raise


def validate_record(record: dict) -> tuple[bool, str]:
    """
    Validasi satu record feedback sebelum dijadikan training data.
    Return: (is_valid, reason)
    """
    correction = record.get("user_correction", {})

    # Periksa semua field wajib ada
    required = ["calories", "protein", "carbs", "fat"]
    for field in required:
        if field not in correction:
            return False, f"Field '{field}' tidak ada"

    # Periksa range realistis
    for field, (min_val, max_val) in NUTRISI_RANGES.items():
        val = correction.get(field)
        if val is not None:
            try:
                v = float(val)
                if not (min_val <= v <= max_val):
                    return False, f"{field}={v} di luar range [{min_val},{max_val}]"
            except (TypeError, ValueError):
                return False, f"{field} bukan angka valid: {val}"

    # Kalori tidak boleh 0 untuk makanan nyata
    calories = float(correction.get("calories", 0))
    if calories == 0:
        food = record.get("food_name", "")
        if "air putih" not in food.lower():  # air putih memang 0 kalori
            return False, "Kalori 0 untuk makanan non-air (mencurigakan)"

    return True, "OK"


def feedback_to_jsonl(record: dict) -> Optional[dict]:
    """
    Konversi satu record feedback ke format JSONL Gemini fine-tuning.
    Return None jika tidak valid.
    """
    is_valid, reason = validate_record(record)
    if not is_valid:
        log.warning(f"Skip record ID={record.get('id','?')}: {reason}")
        return None

    food_name  = record.get("food_name", "Makanan Tidak Dikenal")
    correction = record.get("user_correction", {})
    pred       = record.get("ai_prediction", {})

    # Tentukan kategori kalori
    cal = float(correction.get("calories", 0))
    if cal < 100:
        category = "Makanan Rendah Kalori"
    elif cal < 300:
        category = "Makanan Sedang Kalori"
    else:
        category = "Makanan Tinggi Kalori"

    # Build JSONL entry (format sama dengan train.jsonl existing)
    text_input = (
        f"Berikan informasi nutrisi untuk makanan berikut:\n"
        f"Nama: {food_name}\n"
        f"Kategori: {category}\n"
        f"Informasi nutrisi:"
    )

    def fmt(val, decimals=1):
        try:
            return round(float(val), decimals)
        except (TypeError, ValueError):
            return 0.0

    serving = correction.get("serving") or pred.get("serving") or "1 porsi"

    output_lines = [
        f"Makanan: {food_name}",
        f"Kategori: {category}",
        f"Nutrisi per {serving}:",
        f"- Kalori: {fmt(correction.get('calories'), 0)} kkal",
        f"- Protein: {fmt(correction.get('protein'))}g",
        f"- Lemak: {fmt(correction.get('fat'))}g",
        f"- Karbohidrat: {fmt(correction.get('carbs'))}g",
        f"- Serat: {fmt(correction.get('fiber'))}g",
        f"- Gula: {fmt(correction.get('sugarGrams'))}g",
    ]
    caffeine = correction.get("caffeineMg", 0)
    if caffeine and float(caffeine) > 0:
        output_lines.append(f"- Kafein: {fmt(caffeine, 0)}mg")

    # Tambahkan metadata source untuk transparansi
    output_lines.append(f"Sumber: Koreksi pengguna NuBi (terverifikasi)")

    return {
        "text_input": text_input,
        "output": "\n".join(output_lines) + "\n",
    }


def export_feedbacks(dry_run: bool = False, min_records: int = 1) -> int:
    """
    Utama: ambil feedback dari Supabase, validasi, export ke JSONL.
    Return: jumlah record yang berhasil dieksport.
    """
    log.info("═" * 55)
    log.info("NuBi AI Feedback → JSONL Exporter")
    log.info(f"Mode: {'DRY RUN (tidak ada yang disimpan)' if dry_run else 'LIVE'}")
    log.info("═" * 55)

    # ── Connect Supabase ─────────────────────────────────────────────────
    sb = load_supabase_client()

    # ── Ambil feedback yang belum dieksport ──────────────────────────────
    log.info("Mengambil feedback dari Supabase...")
    response = sb.table("ai_feedback") \
        .select("*") \
        .eq("is_exported", False) \
        .order("created_at") \
        .execute()

    records = response.data or []
    log.info(f"Ditemukan {len(records)} feedback baru.")

    if len(records) < min_records:
        log.warning(
            f"Hanya {len(records)} record, minimum {min_records} diperlukan. "
            "Kumpulkan lebih banyak koreksi dulu."
        )
        return 0

    # ── Validasi dan konversi ────────────────────────────────────────────
    jsonl_entries = []
    exported_ids  = []

    for rec in records:
        entry = feedback_to_jsonl(rec)
        if entry:
            jsonl_entries.append(entry)
            exported_ids.append(rec["id"])

    log.info(f"Valid: {len(jsonl_entries)} / {len(records)} record.")

    if not jsonl_entries:
        log.warning("Tidak ada entry valid. Selesai.")
        return 0

    # ── Tampilkan preview ────────────────────────────────────────────────
    log.info("\n── Preview (3 entri pertama) ──")
    for entry in jsonl_entries[:3]:
        log.info(f"INPUT : {entry['text_input'][:80]}...")
        log.info(f"OUTPUT: {entry['output'][:120]}...")
        log.info("---")

    if dry_run:
        log.info(f"\n[DRY RUN] {len(jsonl_entries)} entri TIDAK disimpan.")
        return len(jsonl_entries)

    # ── Append ke train.jsonl ─────────────────────────────────────────────
    DATASET_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    with open(TRAIN_JSONL, "a", encoding="utf-8") as f:
        for entry in jsonl_entries:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    log.info(f"✅ Ditambahkan {len(jsonl_entries)} entri ke {TRAIN_JSONL}")

    # ── Simpan log export ─────────────────────────────────────────────────
    export_log = LOG_DIR / f"export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(export_log, "w", encoding="utf-8") as f:
        json.dump({
            "exported_at": datetime.now().isoformat(),
            "count": len(jsonl_entries),
            "record_ids": exported_ids,
        }, f, indent=2)

    # ── Mark sebagai exported di Supabase ─────────────────────────────────
    if exported_ids:
        sb.table("ai_feedback") \
            .update({"is_exported": True}) \
            .in_("id", exported_ids) \
            .execute()
        log.info(f"✅ Marked {len(exported_ids)} records as exported.")

    # ── Hitung total training data ────────────────────────────────────────
    total_lines = sum(1 for _ in open(TRAIN_JSONL, encoding="utf-8"))
    log.info(f"\n📊 Total training data: {total_lines} contoh")
    log.info(f"🎯 Siap fine-tune jika ≥ 100 contoh (saat ini: {total_lines})")

    return len(jsonl_entries)


# ═══════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Export AI feedback dari Supabase ke JSONL training data"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview saja tanpa menyimpan atau mengubah database",
    )
    parser.add_argument(
        "--min-records",
        type=int,
        default=1,
        help="Minimum jumlah feedback sebelum export (default: 1)",
    )
    args = parser.parse_args()

    count = export_feedbacks(dry_run=args.dry_run, min_records=args.min_records)
    print(f"\n✅ Export selesai: {count} entri")
