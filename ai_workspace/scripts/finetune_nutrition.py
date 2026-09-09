"""
SEHATI-AI Nutrition Dataset Fine-tuning
=========================================
Membangun:
  1. nutrition_lookup.json  - lookup cepat nama makanan -> nutrisi
  2. nutrition_fewshot.jsonl - contoh few-shot untuk prompt AI
  3. nutrition_index.json   - index fuzzy search (nama -> id)

Sumber data:
  - combined_nutrition.csv  (1971 entri: makanan ID + minuman + kafein)
  - nilai_gizi_kemasan.csv  (1651 entri: produk kemasan)
  - food_master.json        (data master makanan)

Output ke: datasets_clean/nutrition_tabular/finetuned/
"""

import csv
import json
import re
import unicodedata
from pathlib import Path
from collections import defaultdict

BASE    = Path(r"e:\SEHATI-AI\ai_workspace\datasets_clean\nutrition_tabular")
OUT_DIR = BASE / "finetuned"
OUT_DIR.mkdir(exist_ok=True)

# ── Helper ─────────────────────────────────────────────────────────────────────

def normalize(text: str) -> str:
    """Lowercase, hapus aksen, hapus karakter non-alfanumerik."""
    text = text.lower().strip()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()

def calorie_category(kcal: float) -> str:
    if kcal < 100:   return "Sangat Rendah Kalori"
    if kcal < 200:   return "Rendah Kalori"
    if kcal < 300:   return "Sedang Kalori"
    if kcal < 500:   return "Tinggi Kalori"
    return "Sangat Tinggi Kalori"

def nutrition_flags(kcal, protein, fat, carb) -> list:
    flags = []
    if protein >= 15:  flags.append("Tinggi Protein")
    if fat >= 20:      flags.append("Tinggi Lemak")
    if carb >= 50:     flags.append("Tinggi Karbohidrat")
    if kcal >= 500:    flags.append("Tinggi Kalori")
    if kcal < 50:      flags.append("Rendah Kalori")
    return flags

def safe_float(val, default=0.0) -> float:
    try:
        return float(str(val).replace(",", ".").strip())
    except (ValueError, TypeError):
        return default

# ── 1. Load combined_nutrition.csv ────────────────────────────────────────────

print("[1/4] Memuat combined_nutrition.csv...")
entries = []
seen_names = set()

with open(BASE / "combined_nutrition.csv", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        name = row.get("name", "").strip()
        if not name or name in seen_names:
            continue
        seen_names.add(name)

        kcal    = safe_float(row.get("calories"))
        protein = safe_float(row.get("protein_g"))
        fat     = safe_float(row.get("fat_g"))
        carb    = safe_float(row.get("carb_g"))
        sugar   = safe_float(row.get("sugar_g"))
        fiber   = safe_float(row.get("fiber_g"))
        caffeine= safe_float(row.get("caffeine_mg"))
        cat     = row.get("category", "Makanan").strip()
        source  = row.get("source", "").strip()

        entries.append({
            "name":        name,
            "name_norm":   normalize(name),
            "calories":    round(kcal, 1),
            "protein_g":   round(protein, 1),
            "fat_g":       round(fat, 1),
            "carb_g":      round(carb, 1),
            "sugar_g":     round(sugar, 1),
            "fiber_g":     round(fiber, 1),
            "caffeine_mg": round(caffeine, 1),
            "category":    cat,
            "cal_category":calorie_category(kcal),
            "flags":       nutrition_flags(kcal, protein, fat, carb),
            "source":      source,
        })

print(f"   {len(entries)} entri dimuat dari combined_nutrition.csv")

# ── 2. Load nilai_gizi_kemasan.csv (tambah produk kemasan) ────────────────────

print("[2/4] Memuat nilai_gizi_kemasan.csv...")
kemasan_count = 0

with open(BASE / "nilai_gizi_kemasan.csv", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        name = row.get("name", "").strip()
        if not name or name in seen_names:
            continue
        seen_names.add(name)

        kcal    = safe_float(row.get("energy_kcal"))
        protein = safe_float(row.get("protein_g"))
        fat     = safe_float(row.get("fat_g"))
        carb    = safe_float(row.get("carbohydrate_g"))
        sugar   = safe_float(row.get("sugar_g"))
        fiber   = safe_float(row.get("fiber_g"))
        sodium  = safe_float(row.get("sodium_mg"))
        mfr     = row.get("manufacturer", "").strip()

        entries.append({
            "name":        name,
            "name_norm":   normalize(name),
            "calories":    round(kcal, 1),
            "protein_g":   round(protein, 1),
            "fat_g":       round(fat, 1),
            "carb_g":      round(carb, 1),
            "sugar_g":     round(sugar, 1),
            "fiber_g":     round(fiber, 1),
            "caffeine_mg": 0.0,
            "sodium_mg":   round(sodium, 1),
            "category":    "Produk Kemasan",
            "cal_category":calorie_category(kcal),
            "flags":       nutrition_flags(kcal, protein, fat, carb),
            "manufacturer":mfr,
            "source":      "nilai_gizi_kemasan",
        })
        kemasan_count += 1

print(f"   {kemasan_count} entri ditambahkan dari nilai_gizi_kemasan.csv")
print(f"   Total: {len(entries)} entri")

# ── 3. Bangun nutrition_lookup.json ───────────────────────────────────────────

print("[3/4] Membangun nutrition_lookup.json...")

lookup = {}
for e in entries:
    # Key utama: nama asli
    lookup[e["name"]] = e
    # Key alternatif: nama ternormalisasi
    if e["name_norm"] != e["name"].lower():
        lookup[e["name_norm"]] = e

lookup_path = OUT_DIR / "nutrition_lookup.json"
with open(lookup_path, "w", encoding="utf-8") as f:
    json.dump(lookup, f, ensure_ascii=False, indent=2)

print(f"   {len(lookup)} keys di nutrition_lookup.json")

# ── 4. Bangun nutrition_index.json (untuk fuzzy search di Flutter) ────────────

print("[4/4] Membangun nutrition_index.json & few-shot JSONL...")

# Index: list of {name, name_norm, calories, category} untuk search cepat
index = [
    {
        "name":      e["name"],
        "name_norm": e["name_norm"],
        "calories":  e["calories"],
        "category":  e["category"],
    }
    for e in entries
]

index_path = OUT_DIR / "nutrition_index.json"
with open(index_path, "w", encoding="utf-8") as f:
    json.dump(index, f, ensure_ascii=False)

print(f"   {len(index)} entri di nutrition_index.json")

# ── 5. Bangun few-shot JSONL untuk Groq/Gemini ────────────────────────────────

# Format: setiap baris = 1 contoh prompt-response
# Dipakai sebagai few-shot examples dalam system prompt AI

def make_prompt(entry: dict) -> str:
    return f"Berikan informasi nutrisi lengkap untuk: {entry['name']}"

def make_response(entry: dict) -> str:
    flags_str = ", ".join(entry["flags"]) if entry["flags"] else "Seimbang"
    caffeine_str = f"\n- Kafein: {entry['caffeine_mg']} mg" if entry.get("caffeine_mg", 0) > 0 else ""
    sugar_str    = f"\n- Gula: {entry['sugar_g']} g" if entry.get("sugar_g", 0) > 0 else ""
    fiber_str    = f"\n- Serat: {entry['fiber_g']} g" if entry.get("fiber_g", 0) > 0 else ""

    return (
        f"**{entry['name']}** ({entry['category']})\n"
        f"Kategori Kalori: {entry['cal_category']}\n\n"
        f"Nutrisi per 100g/sajian:\n"
        f"- Kalori: {entry['calories']} kkal\n"
        f"- Protein: {entry['protein_g']} g\n"
        f"- Lemak: {entry['fat_g']} g\n"
        f"- Karbohidrat: {entry['carb_g']} g"
        f"{sugar_str}{fiber_str}{caffeine_str}\n\n"
        f"Catatan: {flags_str}"
    )

# Pilih sampel representatif: 5 per kategori kalori
from random import seed, sample
seed(42)

by_cat = defaultdict(list)
for e in entries:
    by_cat[e["cal_category"]].append(e)

fewshot_samples = []
for cat, items in by_cat.items():
    fewshot_samples.extend(sample(items, min(5, len(items))))

# Tambah sampel khusus: makanan yang sering dideteksi YOLO (37 kelas)
yolo_classes = [
    "Ayam Goreng", "Bakso", "Nasi Goreng", "Mie Goreng", "Soto Ayam",
    "Rendang", "Tempe Goreng", "Tahu Goreng", "Telur Ceplok", "Sate",
]
for name in yolo_classes:
    match = next((e for e in entries if name.lower() in e["name"].lower()), None)
    if match and match not in fewshot_samples:
        fewshot_samples.append(match)

jsonl_path = OUT_DIR / "nutrition_fewshot.jsonl"
with open(jsonl_path, "w", encoding="utf-8") as f:
    for e in fewshot_samples:
        record = {
            "messages": [
                {"role": "user",      "content": make_prompt(e)},
                {"role": "assistant", "content": make_response(e)},
            ]
        }
        f.write(json.dumps(record, ensure_ascii=False) + "\n")

print(f"   {len(fewshot_samples)} contoh di nutrition_fewshot.jsonl")

# ── 6. Bangun system_prompt.txt untuk AI ──────────────────────────────────────

# Ambil 10 contoh terbaik (campuran kategori) untuk system prompt
system_examples = fewshot_samples[:10]
examples_text = "\n\n".join(
    f"User: {make_prompt(e)}\nAssistant: {make_response(e)}"
    for e in system_examples
)

system_prompt = f"""Kamu adalah asisten nutrisi SEHATI-AI yang ahli dalam makanan dan minuman Indonesia.

Tugasmu:
1. Memberikan informasi nutrisi akurat berdasarkan database {len(entries)} makanan/minuman Indonesia
2. Menghitung estimasi kalori dari foto makanan yang terdeteksi
3. Memberikan saran diet yang personal dan kontekstual

Panduan respons:
- Selalu sertakan: kalori, protein, lemak, karbohidrat
- Tambahkan peringatan jika makanan tinggi kalori/lemak/gula
- Gunakan satuan per 100g kecuali ada info porsi spesifik
- Bahasa Indonesia yang ramah dan mudah dipahami

Contoh respons yang benar:
{examples_text}

Database nutrisi tersedia untuk {len(entries)} item. Jika makanan tidak ada di database, estimasi berdasarkan bahan-bahan yang terlihat.
"""

prompt_path = OUT_DIR / "system_prompt.txt"
with open(prompt_path, "w", encoding="utf-8") as f:
    f.write(system_prompt)

# ── 7. Ringkasan ──────────────────────────────────────────────────────────────

print()
print("=" * 60)
print("Nutrition Fine-tuning selesai!")
print("=" * 60)
print(f"Output di: {OUT_DIR}")
print()
print("File yang dihasilkan:")
for p in sorted(OUT_DIR.iterdir()):
    size_kb = p.stat().st_size / 1024
    print(f"  {p.name:<35} {size_kb:>8.1f} KB")

print()
print("Statistik dataset:")
cats = defaultdict(int)
for e in entries:
    cats[e["cal_category"]] += 1
for cat, count in sorted(cats.items(), key=lambda x: -x[1]):
    print(f"  {cat:<30} {count:>5} entri")

print()
print("Integrasi ke Flutter:")
print("  1. Salin finetuned/ ke assets/nutrition/")
print("  2. Gunakan nutrition_lookup.json untuk lookup langsung")
print("  3. Gunakan nutrition_index.json untuk search/autocomplete")
print("  4. Gunakan system_prompt.txt sebagai system prompt Groq/Gemini")
