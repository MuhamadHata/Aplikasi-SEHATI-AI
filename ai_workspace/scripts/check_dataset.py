import os, sys, glob
sys.stdout.reconfigure(encoding='utf-8')

import yaml

# Load class names
with open('ai_workspace/datasets_clean/food_detection/data.yaml', encoding='utf-8') as f:
    yaml_data = yaml.safe_load(f)
names = yaml_data.get('names', {})

print("=== RINGKASAN DATASET SEHATI-AI ===\n")

# Hitung gambar dan anotasi per split
for split in ['train', 'valid', 'test']:
    img_dir = f'ai_workspace/datasets_clean/food_detection/{split}/images'
    lbl_dir = f'ai_workspace/datasets_clean/food_detection/{split}/labels'
    imgs = len(glob.glob(os.path.join(img_dir, '*.*')))
    lbls = len(glob.glob(os.path.join(lbl_dir, '*.txt')))
    print(f"  {split:6s}: {imgs:5d} gambar, {lbls:5d} label files")

print()

# Hitung distribusi kelas di train
label_dir = 'ai_workspace/datasets_clean/food_detection/train/labels'
class_counts = {}
total_bbox = 0
for lf in glob.glob(os.path.join(label_dir, '*.txt')):
    with open(lf) as f:
        for line in f:
            line = line.strip()
            if line:
                cls_id = int(line.split()[0])
                class_counts[cls_id] = class_counts.get(cls_id, 0) + 1
                total_bbox += 1

print(f"=== DISTRIBUSI KELAS DI TRAINING SET ===")
print(f"Total bbox annotations: {total_bbox}")
print(f"Total kelas unik: {len(class_counts)} dari {len(names)} kelas\n")

sorted_cls = sorted(class_counts.items(), key=lambda x: -x[1])
for cls_id, count in sorted_cls:
    name = names.get(cls_id, f'cls_{cls_id}')
    bar = '#' * min(count // 20, 30)
    print(f"  [{cls_id:2d}] {name:30s}: {count:5d} {bar}")

# Kelas yang TIDAK ada di training
missing = [cid for cid in names.keys() if cid not in class_counts]
if missing:
    print(f"\n=== KELAS YANG TIDAK ADA ANOTASI DI TRAINING ===")
    for cid in missing:
        print(f"  [{cid:2d}] {names[cid]} - BELUM TERLATIH!")

# Statistik khusus Nasi Padang
nasi_padang_id = None
for k, v in names.items():
    if v == "Nasi Padang":
        nasi_padang_id = k
        break

print(f"\n=== STATUS NASI PADANG ===")
if nasi_padang_id is not None:
    count = class_counts.get(nasi_padang_id, 0)
    print(f"  Class ID: {nasi_padang_id}")
    print(f"  Jumlah anotasi training: {count}")
    if count == 0:
        print("  STATUS: ❌ TIDAK ADA DATA TRAINING - Model TIDAK bisa mengenali Nasi Padang!")
    elif count < 100:
        print(f"  STATUS: ⚠️  DATA SANGAT SEDIKIT ({count}) - Deteksi akan tidak akurat")
    else:
        print(f"  STATUS: ✅ Data cukup ({count} anotasi)")
else:
    print("  STATUS: ❌ Nasi Padang tidak ada dalam kelas YOLO!")

# Cek dataset Makanan Padang yang belum digabung
print("\n=== STATUS DATASET MAKANAN PADANG (BELUM DIGABUNG) ===")
padang_train = 'ai_workspace/dataset/makanan padang.v1i.multiclass/train'
if os.path.isdir(padang_train):
    imgs = len([f for f in os.listdir(padang_train) if f.lower().endswith(('.jpg','.png','.jpeg'))])
    print(f"  makanan padang.v1i.multiclass/train: {imgs} gambar")
    classes_csv = os.path.join(padang_train, '_classes.csv')
    if os.path.exists(classes_csv):
        with open(classes_csv) as f:
            header = f.readline()
            classes = header.strip().split(',')[1:]
            print(f"  Kelas: {classes}")
else:
    print("  Folder tidak ditemukan")

print("\n=== MODEL YANG SUDAH DILATIH ===")
model_files = [
    ('sehati_ai_backend/best.pt', 'Current Active'),
    ('sehati_ai_backend/runs/detect/SehatiAI_Food_Phase2/weights/best.pt', 'SehatiAI Phase2 (terbaru)'),
    ('sehati_ai_backend/runs/detect/Nubi_Food_Detection/v3_finetune/weights/best.pt', 'v3 Finetune'),
]
for mf, label in model_files:
    if os.path.exists(mf):
        size_mb = os.path.getsize(mf) / (1024*1024)
        print(f"  ✅ {label}: {mf} ({size_mb:.1f} MB)")
    else:
        print(f"  ❌ {label}: tidak ditemukan")
