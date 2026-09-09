"""
SEHATI-AI — Auto-Labeling YOLO untuk Gambar Baru
=================================================
Script ini membuat label YOLO (.txt) secara otomatis dari nama file gambar,
TANPA perlu Roboflow atau anotasi manual.

Cara kerja:
  - Nama file = "pisang_goreng_0001.jpg"
  - Script tahu kelas = "Pisang Goreng" (dari mapping nama)
  - Buat label YOLO: class_id cx cy w h (full-image bounding box: 0.5 0.5 1.0 1.0)

Ini disebut "weak labeling" — akurasi tidak seperfect anotasi manual, 
tapi sangat efektif sebagai titik awal training YOLO untuk kelas baru.

Jalankan SETELAH download_new_class_images.py selesai:
  python ai_workspace/scripts/auto_label_new_images.py
"""

import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

# ─── Path ─────────────────────────────────────────────────────────────────────
BASE_DIR    = Path(__file__).parent.parent.parent
DATASET_DIR = BASE_DIR / "ai_workspace" / "datasets_clean" / "food_detection"

# ─── Mapping: nama_file_prefix → class_id (sesuai data.yaml urutan 0-66) ─────
# Kelas lama (0-36) sudah punya label dari dataset Roboflow sebelumnya
# Kelas baru (37-66) ini yang perlu di-auto-label
CLASS_MAP = {
    # Prefix nama file  : class_id (sesuai data.yaml)
    "pisang_goreng"     : 37,
    "onde_onde"         : 38,
    "lumpia"            : 39,
    "cireng"            : 40,
    "batagor"           : 41,
    "siomay"            : 42,
    "pempek"            : 43,
    "tahu_bulat"        : 44,
    "cilok"             : 45,
    "kue_cubit"         : 46,
    "kroket"            : 47,
    "es_teh_manis"      : 48,
    "es_jeruk"          : 49,
    "kopi_susu"         : 50,
    "wedang_jahe"       : 51,
    "es_dawet"          : 52,
    "susu_kedelai"      : 53,
    "jus_buah"          : 54,
    "laksa"             : 55,
    "ketoprak"          : 56,
    "nasi_bakar"        : 57,
    "nasi_tim"          : 58,
    "kolak"             : 59,
    "gado_gado"         : 60,
    "pisang"            : 61,
    "semangka"          : 62,
    "mangga"            : 63,
    "pepaya"            : 64,
    "ubi_goreng"        : 65,
    "nugget_ayam"       : 66,
}

# Label YOLO full-image bounding box (cx cy w h, semua normalized 0-1)
# Artinya: bounding box menutupi seluruh gambar
FULL_IMAGE_BOX = "0.500000 0.500000 1.000000 1.000000"


def find_class_id(filename: str) -> int | None:
    """
    Cari class_id berdasarkan prefix nama file.
    Contoh: "pisang_goreng_0003.jpg" -> prefix "pisang_goreng" -> 37
    """
    stem = Path(filename).stem.lower()  # tanpa ekstensi, lowercase
    # Coba match dari yang paling panjang dulu (greedy match)
    best_match = None
    best_len = 0
    for prefix, class_id in CLASS_MAP.items():
        if stem.startswith(prefix) and len(prefix) > best_len:
            best_match = class_id
            best_len = len(prefix)
    return best_match


def auto_label_folder(img_dir: Path, lbl_dir: Path) -> tuple[int, int, int]:
    """
    Buat file label .txt untuk semua gambar di img_dir.
    Return: (labeled, skipped_existing, skipped_unknown)
    """
    lbl_dir.mkdir(parents=True, exist_ok=True)
    labeled = skipped_existing = skipped_unknown = 0

    images = list(img_dir.glob("*.jpg")) + list(img_dir.glob("*.jpeg")) + \
             list(img_dir.glob("*.png")) + list(img_dir.glob("*.webp"))

    for img_path in sorted(images):
        lbl_path = lbl_dir / (img_path.stem + ".txt")

        # Skip jika label sudah ada DAN tidak kosong (sudah punya anotasi manual)
        if lbl_path.exists() and lbl_path.stat().st_size > 0:
            skipped_existing += 1
            continue

        class_id = find_class_id(img_path.name)
        if class_id is None:
            skipped_unknown += 1
            continue

        # Tulis label YOLO: <class_id> <cx> <cy> <w> <h>
        lbl_path.write_text(f"{class_id} {FULL_IMAGE_BOX}\n", encoding="utf-8")
        labeled += 1

    return labeled, skipped_existing, skipped_unknown


def main():
    print("=" * 65)
    print("SEHATI-AI -- Auto-Labeling YOLO (Full-Image Bounding Box)")
    print("=" * 65)
    print(f"Dataset : {DATASET_DIR}")
    print(f"Kelas   : {len(CLASS_MAP)} kelas baru (ID 37-66)")
    print()

    total_labeled = total_existing = total_unknown = 0

    for split in ["train", "valid", "test"]:
        img_dir = DATASET_DIR / split / "images"
        lbl_dir = DATASET_DIR / split / "labels"

        if not img_dir.exists():
            print(f"[SKIP] {split}/images tidak ditemukan")
            continue

        labeled, existing, unknown = auto_label_folder(img_dir, lbl_dir)
        total_labeled   += labeled
        total_existing  += existing
        total_unknown   += unknown

        print(f"[{split.upper():5s}] Dibuat: {labeled:4d} label | "
              f"Sudah ada: {existing:4d} | Tidak dikenal: {unknown:4d}")

    print()
    print(f"Total label baru dibuat : {total_labeled}")
    print(f"Label sudah ada (skip)  : {total_existing}")
    print(f"Gambar tidak dikenal    : {total_unknown}")
    print()

    if total_labeled > 0:
        print("[OK] Auto-labeling selesai! Siap untuk training.")
        print()
        print("LANGKAH BERIKUTNYA:")
        print("  Jalankan training GPU:")
        print("  python sehati_ai_backend/finetune_food_detection.py")
    else:
        print("[!!] Tidak ada label baru dibuat.")
        print("     Pastikan download_new_class_images.py sudah selesai dulu.")

    print("=" * 65)


if __name__ == "__main__":
    main()
