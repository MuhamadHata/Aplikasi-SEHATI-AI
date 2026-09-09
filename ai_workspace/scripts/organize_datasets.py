"""
SEHATI-AI Dataset Organizer
============================
Menggabungkan semua dataset yang ada ke dalam struktur terorganisir per fitur:

  datasets_clean/
  ├── food_detection/          ← unified_yolo_dataset (YOLO, sudah terbaik)
  ├── nutrition_tabular/       ← nutrition.csv + nilai-gizi.csv + beverages_id.csv + caffeine.csv + food_master.json
  ├── water_intake/            ← Daily_Water_Intake.csv
  ├── diabetes/                ← diabetes.csv
  ├── screentime_mental/       ← ScreenTime vs MentalWellness.csv
  ├── heart_rate_emotion/      ← heart_rate_emotion_dataset.csv
  ├── skin_acne/               ← jerawat/ + bekas jerawat/
  └── references/              ← references_health.json

Dataset yang DIHAPUS (sudah tercakup di unified_yolo_dataset atau duplikat):
  - Indonesia Food.v1i.yolov8
  - Indonesia-Food.v2i.yolov8
  - Indonesian Food.v8i.multiclass
  - makanan padang.v1i.multiclass
  - fastfood
  - buah-dan-sayur
  - Nutrition Labels.v1-augmented_dataset.multiclass
  - Food Recognation.v4-roboflow-instant-2--eval-.yolov8-obb
  - Indonesianfood (CSV format lama)
  - facial-expression (sudah ada heart_rate_emotion sebagai proxy emosi)
  - merge_nutrition.dart / merge_nutrition.py (script lama)
"""

import os
import shutil
import json
import csv
import sys
from pathlib import Path

BASE = Path(r"e:\SEHATI-AI\ai_workspace\dataset")
OUT  = Path(r"e:\SEHATI-AI\ai_workspace\datasets_clean")

# ── Folder output ──────────────────────────────────────────────────────────────
DIRS = [
    "food_detection",
    "nutrition_tabular",
    "water_intake",
    "diabetes",
    "screentime_mental",
    "heart_rate_emotion",
    "skin_acne/active",
    "skin_acne/scar",
    "references",
]

def make_dirs():
    for d in DIRS:
        (OUT / d).mkdir(parents=True, exist_ok=True)
    print("[OK] Folder output dibuat")

# ── 1. Food Detection: salin unified_yolo_dataset ─────────────────────────────
def copy_food_detection():
    src = BASE / "unified_yolo_dataset"
    dst = OUT / "food_detection"
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    # Update path di data.yaml agar relatif
    yaml_path = dst / "data.yaml"
    content = yaml_path.read_text(encoding="utf-8")
    # Ganti path absolut lama dengan path relatif
    content = content.replace(
        "path: E:\\Nubi\\ai_workspace\\dataset\\unified_yolo_dataset",
        f"path: {dst}"
    )
    yaml_path.write_text(content, encoding="utf-8")
    train_count = len(list((dst / "train" / "images").glob("*")))
    valid_count = len(list((dst / "valid" / "images").glob("*")))
    test_count  = len(list((dst / "test"  / "images").glob("*")))
    print(f"[OK] food_detection: {train_count} train / {valid_count} valid / {test_count} test gambar, 37 kelas")

# ── 2. Nutrition Tabular: gabung semua CSV nutrisi ────────────────────────────
def merge_nutrition_tabular():
    dst = OUT / "nutrition_tabular"

    # 2a. nutrition.csv (makanan Indonesia, id/calories/proteins/fat/carb/name)
    shutil.copy2(BASE / "nutrition.csv", dst / "nutrition_id.csv")

    # 2b. nilai-gizi.csv (label gizi produk kemasan)
    shutil.copy2(BASE / "nilai-gizi.csv", dst / "nilai_gizi_kemasan.csv")

    # 2c. beverages_id.csv (minuman Indonesia)
    shutil.copy2(BASE / "beverages_id.csv", dst / "beverages_id.csv")

    # 2d. caffeine.csv (kandungan kafein minuman)
    shutil.copy2(BASE / "caffeine.csv", dst / "caffeine.csv")

    # 2e. food_master.json
    shutil.copy2(BASE / "food_master.json", dst / "food_master.json")

    # 2f. Buat combined_nutrition.csv: gabung nutrition.csv + beverages_id.csv
    #     dengan kolom standar: name, calories, protein_g, fat_g, carb_g, category, source
    rows = []

    # Dari nutrition.csv
    with open(BASE / "nutrition.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append({
                "name":       r.get("name", ""),
                "calories":   r.get("calories", ""),
                "protein_g":  r.get("proteins", ""),
                "fat_g":      r.get("fat", ""),
                "carb_g":     r.get("carbohydrate", ""),
                "sugar_g":    "",
                "fiber_g":    "",
                "caffeine_mg":"",
                "category":   "Makanan",
                "source":     "nutrition_id",
            })

    # Dari beverages_id.csv
    with open(BASE / "beverages_id.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append({
                "name":       r.get("name", ""),
                "calories":   r.get("energy_kcal", ""),
                "protein_g":  "",
                "fat_g":      "",
                "carb_g":     "",
                "sugar_g":    r.get("sugar_g", ""),
                "fiber_g":    "",
                "caffeine_mg":r.get("caffeine_mg", ""),
                "category":   r.get("category", "Minuman"),
                "source":     "beverages_id",
            })

    # Dari caffeine.csv (minuman berkafein)
    with open(BASE / "caffeine.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append({
                "name":       r.get("drink", ""),
                "calories":   r.get("Calories", ""),
                "protein_g":  "",
                "fat_g":      "",
                "carb_g":     "",
                "sugar_g":    "",
                "fiber_g":    "",
                "caffeine_mg":r.get("Caffeine (mg)", ""),
                "category":   r.get("type", "Minuman"),
                "source":     "caffeine",
            })

    out_csv = dst / "combined_nutrition.csv"
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)

    print(f"[OK] nutrition_tabular: {len(rows)} entri di combined_nutrition.csv + 4 file sumber")

# ── 3. Water Intake ───────────────────────────────────────────────────────────
def copy_water_intake():
    shutil.copy2(BASE / "Daily_Water_Intake.csv", OUT / "water_intake" / "daily_water_intake.csv")
    # Hitung baris
    with open(BASE / "Daily_Water_Intake.csv", encoding="utf-8") as f:
        n = sum(1 for _ in f) - 1
    print(f"[OK] water_intake: {n} baris")

# ── 4. Diabetes ───────────────────────────────────────────────────────────────
def copy_diabetes():
    shutil.copy2(BASE / "diabetes.csv", OUT / "diabetes" / "diabetes.csv")
    with open(BASE / "diabetes.csv", encoding="utf-8") as f:
        n = sum(1 for _ in f) - 1
    print(f"[OK] diabetes: {n} baris (Pima Indians Diabetes Dataset)")

# ── 5. ScreenTime & Mental Wellness ──────────────────────────────────────────
def copy_screentime():
    src = BASE / "ScreenTime vs MentalWellness.csv"
    shutil.copy2(src, OUT / "screentime_mental" / "screentime_mental_wellness.csv")
    with open(src, encoding="utf-8") as f:
        n = sum(1 for _ in f) - 1
    print(f"[OK] screentime_mental: {n} baris")

# ── 6. Heart Rate → Emotion ───────────────────────────────────────────────────
def copy_heart_rate_emotion():
    src = BASE / "heart_rate_emotion_dataset.csv"
    shutil.copy2(src, OUT / "heart_rate_emotion" / "heart_rate_emotion.csv")
    with open(src, encoding="utf-8") as f:
        n = sum(1 for _ in f) - 1
    print(f"[OK] heart_rate_emotion: {n} baris (HeartRate -> Emotion label)")

# ── 7. Skin / Acne ────────────────────────────────────────────────────────────
def copy_skin_acne():
    # Jerawat aktif
    src_active = BASE / "jerawat"
    dst_active = OUT / "skin_acne" / "active"
    if dst_active.exists():
        shutil.rmtree(dst_active)
    shutil.copytree(src_active, dst_active)
    n_active = len(list(dst_active.glob("*.jpeg")) + list(dst_active.glob("*.jpg")) + list(dst_active.glob("*.png")))

    # Bekas jerawat (scar)
    src_scar = BASE / "bekas jerawat"
    dst_scar = OUT / "skin_acne" / "scar"
    if dst_scar.exists():
        shutil.rmtree(dst_scar)
    shutil.copytree(src_scar, dst_scar)
    n_scar = len(list(dst_scar.glob("*.jpeg")) + list(dst_scar.glob("*.jpg")) + list(dst_scar.glob("*.png")))

    # Buat README singkat
    readme = OUT / "skin_acne" / "README.md"
    readme.write_text(
        "# Skin Acne Dataset\n\n"
        "- `active/` — gambar jerawat aktif\n"
        "- `scar/`   — gambar bekas jerawat (scar)\n\n"
        f"Total: {n_active} gambar aktif, {n_scar} gambar scar\n",
        encoding="utf-8"
    )
    print(f"[OK] skin_acne: {n_active} aktif + {n_scar} scar")

# ── 8. References ─────────────────────────────────────────────────────────────
def copy_references():
    shutil.copy2(BASE / "references_health.json", OUT / "references" / "references_health.json")
    print("[OK] references: references_health.json")

# ── 9. Buat README utama ──────────────────────────────────────────────────────
def write_readme():
    readme = OUT / "README.md"
    readme.write_text(
        "# SEHATI-AI Datasets (Clean)\n\n"
        "Dataset terorganisir per fitur aplikasi.\n\n"
        "| Folder | Fitur | Format | Keterangan |\n"
        "|--------|-------|--------|------------|\n"
        "| `food_detection/` | Pindai Makanan | YOLO v8 | 37 kelas makanan Indonesia, ~4900 gambar |\n"
        "| `nutrition_tabular/` | Kalori & Nutrisi | CSV + JSON | Makanan ID, minuman, kafein, label kemasan |\n"
        "| `water_intake/` | Target Air Minum | CSV | Usia/berat/aktivitas → kebutuhan air |\n"
        "| `diabetes/` | Cek Diabetes | CSV | Pima Indians, 768 baris, 8 fitur klinis |\n"
        "| `screentime_mental/` | Screen Time | CSV | Screen time vs mental wellness, 400 user |\n"
        "| `heart_rate_emotion/` | Emosi dari Detak Jantung | CSV | HeartRate → 7 emosi |\n"
        "| `skin_acne/` | Pindai Kecantikan | Gambar | Jerawat aktif + bekas jerawat |\n"
        "| `references/` | Referensi Kesehatan | JSON | Data referensi kesehatan umum |\n\n"
        "## Dataset yang dihapus (sudah tercakup)\n"
        "- `Indonesia Food.v1i.yolov8` — subset dari unified_yolo_dataset\n"
        "- `Indonesia-Food.v2i.yolov8` — subset dari unified_yolo_dataset\n"
        "- `Indonesian Food.v8i.multiclass` — subset dari unified_yolo_dataset\n"
        "- `makanan padang.v1i.multiclass` — subset dari unified_yolo_dataset\n"
        "- `fastfood` — subset dari unified_yolo_dataset\n"
        "- `buah-dan-sayur` — subset dari unified_yolo_dataset\n"
        "- `Nutrition Labels.v1-augmented_dataset.multiclass` — label kemasan, sudah ada di nilai-gizi.csv\n"
        "- `Food Recognation.v4-roboflow-instant-2--eval-.yolov8-obb` — format OBB, tidak kompatibel\n"
        "- `Indonesianfood/` — format CSV lama, sudah ada di nutrition_tabular\n"
        "- `facial-expression/` — digantikan heart_rate_emotion untuk deteksi emosi via wearable\n",
        encoding="utf-8"
    )
    print("[OK] README.md dibuat")

# ── 10. Hapus folder dataset lama yang sudah tidak dipakai ────────────────────
TO_DELETE = [
    "Indonesia Food.v1i.yolov8",
    "Indonesia-Food.v2i.yolov8",
    "Indonesian Food.v8i.multiclass",
    "makanan padang.v1i.multiclass",
    "fastfood",
    "buah-dan-sayur",
    "Nutrition Labels.v1-augmented_dataset.multiclass",
    "Food Recognation.v4-roboflow-instant-2--eval-.yolov8-obb",
    "Indonesianfood",
    "facial-expression",
    "merge_nutrition.dart",
    "merge_nutrition.py",
]

def delete_old_datasets(dry_run=False):
    total_freed = 0
    for name in TO_DELETE:
        p = BASE / name
        if not p.exists():
            print(f"  [SKIP] {name} — tidak ditemukan")
            continue
        if p.is_dir():
            size = sum(f.stat().st_size for f in p.rglob("*") if f.is_file())
        else:
            size = p.stat().st_size
        total_freed += size
        if dry_run:
            print(f"  [DRY]  {name} — {size/1024/1024:.1f} MB akan dihapus")
        else:
            if p.is_dir():
                shutil.rmtree(p)
            else:
                p.unlink()
            print(f"  [DEL]  {name} — {size/1024/1024:.1f} MB dihapus")
    print(f"\n  Total dibebaskan: {total_freed/1024/1024:.0f} MB")

# ── Main ───────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    dry_run = "--dry-run" in sys.argv

    print("=" * 60)
    print("SEHATI-AI Dataset Organizer")
    print("=" * 60)

    if dry_run:
        print("\n[MODE DRY-RUN] Tidak ada yang dihapus/disalin\n")
        delete_old_datasets(dry_run=True)
        sys.exit(0)

    print("\n[1/9] Membuat folder output...")
    make_dirs()

    print("\n[2/9] Food Detection (YOLO)...")
    copy_food_detection()

    print("\n[3/9] Nutrition Tabular...")
    merge_nutrition_tabular()

    print("\n[4/9] Water Intake...")
    copy_water_intake()

    print("\n[5/9] Diabetes...")
    copy_diabetes()

    print("\n[6/9] ScreenTime & Mental Wellness...")
    copy_screentime()

    print("\n[7/9] Heart Rate Emotion...")
    copy_heart_rate_emotion()

    print("\n[8/9] Skin Acne...")
    copy_skin_acne()

    print("\n[9/9] References...")
    copy_references()

    write_readme()

    print("\n" + "=" * 60)
    print("Semua dataset berhasil diorganisir ke:")
    print(f"  {OUT}")
    print("=" * 60)

    print("\nMenghapus dataset lama yang sudah tidak dipakai...")
    delete_old_datasets(dry_run=False)

    print("\nSelesai!")
