#!/usr/bin/env python3
"""
trigger_finetune.py
===================
Memicu fine-tuning model Gemini menggunakan dataset JSONL yang dikumpulkan
dari koreksi user NuBi. Pengetahuan tentang nutrisi akan tersimpan di
BOBOT MODEL AI (bukan database) setelah proses ini selesai.

Tahapan:
  1. Periksa apakah dataset cukup (threshold: 100 contoh)
  2. Upload dataset ke Google AI Studio
  3. Buat tuning job
  4. Monitor status hingga selesai
  5. Simpan model name ke config

Penggunaan:
  python scripts/trigger_finetune.py [--force] [--threshold 50]

Requirements:
  pip install google-generativeai python-dotenv
"""

import json
import time
import argparse
import logging
from pathlib import Path
from datetime import datetime

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
CONFIG_FILE   = WORKSPACE_DIR / "continual_learning" / "tuned_model_config.json"
LOG_DIR       = WORKSPACE_DIR / "logs"

# ── Konfigurasi fine-tuning ───────────────────────────────────────────────
TUNING_CONFIG = {
    "base_model":    "models/gemini-1.5-flash-001-tuning",  # model yang bisa di-tune
    "display_name":  f"nubi-food-nutrition-{datetime.now().strftime('%Y%m%d')}",
    "epoch_count":   5,         # jumlah epoch (lebih sedikit = lebih cepat, kurang overfit)
    "batch_size":    4,         # ukuran batch
    "learning_rate": 0.001,     # learning rate
}

# ── Replay buffer: ambil sebagian data lama untuk prevent forgetting ───────
REPLAY_BUFFER_SIZE = 50   # jumlah contoh lama yang selalu disertakan


def count_jsonl_lines(path: Path) -> int:
    """Hitung jumlah baris di file JSONL."""
    if not path.exists():
        return 0
    with open(path, encoding="utf-8") as f:
        return sum(1 for line in f if line.strip())


def load_training_data(path: Path) -> list[dict]:
    """Load semua training data dari JSONL."""
    if not path.exists():
        return []
    data = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    data.append(json.loads(line))
                except json.JSONDecodeError:
                    log.warning(f"Skip baris tidak valid: {line[:50]}")
    return data


def prepare_dataset_with_replay(all_data: list[dict]) -> list[dict]:
    """
    Implementasi Replay Buffer untuk Continual Learning.

    Strategi: Mix data lama (replay) + data baru untuk mencegah
    catastrophic forgetting pada pengetahuan makanan sebelumnya.
    """
    if len(all_data) <= REPLAY_BUFFER_SIZE:
        return all_data

    # Ambil sebagian data lama (contoh pertama = paling lama / paling terverifikasi)
    old_data = all_data[:REPLAY_BUFFER_SIZE]
    # Semua data baru
    new_data = all_data[REPLAY_BUFFER_SIZE:]

    import random
    random.shuffle(old_data)
    random.shuffle(new_data)

    merged = old_data + new_data
    log.info(f"Replay buffer: {len(old_data)} lama + {len(new_data)} baru = {len(merged)} total")
    return merged


def create_tuning_job(api_key: str, training_data: list[dict]) -> str:
    """Buat fine-tuning job di Google AI Studio via API."""
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)

        log.info(f"Membuat tuning job: {TUNING_CONFIG['display_name']}")
        log.info(f"Base model: {TUNING_CONFIG['base_model']}")
        log.info(f"Training examples: {len(training_data)}")

        # Format data untuk Gemini tuning API
        examples = []
        for item in training_data:
            examples.append(
                genai.protos.TuningExample(
                    text_input=item["text_input"],
                    output=item["output"],
                )
            )

        operation = genai.create_tuned_model(
            source_model=TUNING_CONFIG["base_model"],
            training_data=examples,
            id=TUNING_CONFIG["display_name"],
            epoch_count=TUNING_CONFIG["epoch_count"],
            batch_size=TUNING_CONFIG["batch_size"],
            learning_rate=TUNING_CONFIG["learning_rate"],
        )

        log.info(f"✅ Tuning job dibuat! Operation: {operation.operation.name}")
        return operation.operation.name

    except Exception as e:
        log.error(f"Gagal membuat tuning job: {e}")
        raise


def monitor_tuning_job(api_key: str, operation_name: str, timeout_hours: int = 6) -> str:
    """
    Monitor progress fine-tuning hingga selesai.
    Return: nama model yang sudah di-tune (jika berhasil)
    """
    import google.generativeai as genai
    genai.configure(api_key=api_key)

    log.info(f"Monitoring job: {operation_name}")
    log.info(f"Timeout: {timeout_hours} jam")

    start_time = time.time()
    timeout_secs = timeout_hours * 3600
    check_interval = 60  # cek setiap 1 menit

    for attempt in range(int(timeout_secs / check_interval)):
        elapsed = time.time() - start_time
        elapsed_min = int(elapsed / 60)

        try:
            model_name = operation_name.replace("operations/", "tunedModels/")
            model = genai.get_tuned_model(model_name)

            state = str(model.state)
            log.info(f"[{elapsed_min}min] Status: {state}")

            if "ACTIVE" in state:
                log.info(f"✅ Fine-tuning SELESAI! Model: {model.name}")
                return model.name

            if "FAILED" in state or "CANCELLED" in state:
                log.error(f"❌ Fine-tuning GAGAL. Status: {state}")
                raise RuntimeError(f"Tuning job gagal: {state}")

        except Exception as e:
            if "ACTIVE" in str(e) or "FAILED" in str(e):
                raise
            log.debug(f"Cek status gagal (attempt {attempt}): {e}")

        time.sleep(check_interval)

    raise TimeoutError(f"Fine-tuning timeout setelah {timeout_hours} jam")


def save_model_config(model_name: str, training_count: int):
    """Simpan nama model baru ke config untuk digunakan oleh app."""
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)

    config = {
        "tuned_model_name": model_name,
        "tuned_at": datetime.now().isoformat(),
        "training_examples": training_count,
        "base_model": TUNING_CONFIG["base_model"],
        "note": (
            "Gunakan model ini via API: genai.GenerativeModel(model_name). "
            "Ganti NUBI_GEMINI_KEYS di app jika model baru lebih akurat."
        ),
    }

    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

    log.info(f"✅ Config model disimpan ke {CONFIG_FILE}")
    log.info(f"   Model name: {model_name}")


def trigger_finetune(force: bool = False, threshold: int = 100) -> bool:
    """
    Fungsi utama: cek dataset, siapkan data, trigger fine-tuning.
    Return: True jika fine-tuning berhasil, False jika di-skip.
    """
    import os
    from dotenv import load_dotenv
    load_dotenv(WORKSPACE_DIR / ".env")

    api_key = os.environ.get("GOOGLE_AI_STUDIO_KEY")
    if not api_key:
        log.error(
            "Set GOOGLE_AI_STUDIO_KEY di .env\n"
            "Dapatkan dari: https://aistudio.google.com/app/apikey"
        )
        return False

    log.info("═" * 55)
    log.info("NuBi AI — Gemini Fine-Tuning Trigger")
    log.info("═" * 55)

    # ── Periksa jumlah training data ──────────────────────────────────────
    total = count_jsonl_lines(TRAIN_JSONL)
    log.info(f"Total training examples: {total}")
    log.info(f"Threshold fine-tuning: {threshold}")

    if total < threshold and not force:
        log.warning(
            f"Belum cukup data ({total} < {threshold}). "
            "Kumpulkan lebih banyak koreksi dari pengguna, "
            "atau gunakan --force untuk memaksa tuning."
        )
        return False

    LOG_DIR.mkdir(parents=True, exist_ok=True)

    # ── Load dan siapkan dataset dengan replay buffer ─────────────────────
    all_data = load_training_data(TRAIN_JSONL)
    training_data = prepare_dataset_with_replay(all_data)

    log.info(f"\n📊 Dataset summary:")
    log.info(f"   Total examples: {len(training_data)}")
    log.info(f"   Epoch: {TUNING_CONFIG['epoch_count']}")
    log.info(f"   Learning rate: {TUNING_CONFIG['learning_rate']}")

    # ── Buat dan monitor tuning job ────────────────────────────────────────
    operation_name = create_tuning_job(api_key, training_data)

    log.info("\n⏳ Menunggu fine-tuning selesai (bisa memakan waktu 1-3 jam)...")
    model_name = monitor_tuning_job(api_key, operation_name)

    # ── Simpan config ─────────────────────────────────────────────────────
    save_model_config(model_name, len(training_data))

    log.info("\n" + "═" * 55)
    log.info("🎉 Fine-tuning BERHASIL!")
    log.info(f"   Model baru: {model_name}")
    log.info("\nLangkah selanjutnya:")
    log.info("  1. Test model baru via Google AI Studio")
    log.info("  2. Jika akurat, update konfigurasi di Flutter app")
    log.info("  3. Rebuild dan re-release APK")
    log.info("═" * 55)
    return True


# ═══════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Trigger Gemini fine-tuning dari dataset koreksi user NuBi"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Paksa fine-tuning meski belum mencapai threshold",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=100,
        help="Minimum jumlah training examples sebelum fine-tune (default: 100)",
    )
    args = parser.parse_args()

    success = trigger_finetune(force=args.force, threshold=args.threshold)
    exit(0 if success else 1)
