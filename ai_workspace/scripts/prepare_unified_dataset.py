import os
import pandas as pd
import json
import shutil
import yaml
from pathlib import Path

# Configuration — paths relatif dari lokasi script ini
_SCRIPT_DIR = Path(__file__).parent
_WORKSPACE  = _SCRIPT_DIR.parent
BASE_DIR    = str(_WORKSPACE / "dataset")
OUTPUT_DIR  = os.path.join(BASE_DIR, "unified_food_v1")
DATASETS = [
    {
        "name": "Food Recognation",
        "path": "Food Recognation.v4-roboflow-instant-2--eval-.yolov8-obb",
        "type": "yolo-obb"
    },
    {
        "name": "Indonesian Food",
        "path": "Indonesian Food.v8i.multiclass",
        "type": "csv-multiclass"
    },
    {
        "name": "Makanan Padang",
        "path": "makanan padang.v1i.multiclass",
        "type": "csv-multiclass"
    }
]

# Define Unified Categories
# We merge similar items (e.g. Rendang Sapi and Rendang)
# Special focus on Martabak Manis to avoid 'Telur' misidentification.
UNIFIED_CLASSES = [
    "Ayam Goreng", "Ayam Pop", "Bakso", "Dendeng Batokok", "Gulai Ikan", 
    "Gulai Tambusu", "Martabak Manis", "Rendang", "Apple", "Banana", 
    "Burger", "Capcay", "Chocolate Chip Cookie", "Donat", "Ikan Goreng", 
    "Kentang Goreng", "Kiwi", "Mie Goreng", "Nasi Goreng", "Nasi Putih", 
    "Nugget", "Pempek", "Pineapples", "Pizza", "Sate", "Spaghetti", 
    "Steak", "Strawberry", "Tahu Goreng", "Telur Goreng", "Telur Rebus", 
    "Tempe Goreng", "Terong Balado", "Tumis Kangkung"
]

def ensure_dirs():
    for split in ['train', 'valid', 'test']:
        os.makedirs(os.path.join(OUTPUT_DIR, split, 'images'), exist_ok=True)
        os.makedirs(os.path.join(OUTPUT_DIR, split, 'labels'), exist_ok=True)

def process_csv_dataset(ds_config):
    print(f"Processing {ds_config['name']}...")
    ds_path = os.path.join(BASE_DIR, ds_config['path'])
    
    for split in ['train', 'valid', 'test']:
        csv_file = os.path.join(ds_path, split, '_classes.csv')
        if not os.path.exists(csv_file):
            continue
            
        df = pd.read_csv(csv_file)
        # Fix column names (some have leading spaces)
        df.columns = [c.strip() for c in df.columns]
        
        img_dir = os.path.join(ds_path, split)
        
        for _, row in df.iterrows():
            img_name = row['filename']
            src_img_path = os.path.join(img_dir, img_name)
            
            if not os.path.exists(src_img_path):
                continue
                
            # Find active classes
            found_classes = []
            for col in df.columns[1:]:
                if row[col] == 1:
                    norm_col = col.title() # Normalize to Title Case
                    if norm_col in UNIFIED_CLASSES:
                        found_classes.append(UNIFIED_CLASSES.index(norm_col))
            
            if not found_classes:
                continue
                
            # Since these are multiclass (classification-style), 
            # for YOLO detection we simulate a full-image bounding box if necessary,
            # but ideally we look for YOLO labels if they exist.
            # If they don't, this dataset might only be for classification.
            # Indonesian Food.v8i appears to be multiclass classification based on _classes.csv.
            
            # Copy Image
            dst_img_path = os.path.join(OUTPUT_DIR, split, 'images', img_name)
            shutil.copy(src_img_path, dst_img_path)
            
            # Create dummy label (full image) for classification-to-detection fallback
            # [class_id, x_center, y_center, width, height]
            with open(os.path.join(OUTPUT_DIR, split, 'labels', img_name.replace('.jpg', '.txt')), 'w') as f:
                for cls_id in found_classes:
                    f.write(f"{cls_id} 0.5 0.5 1.0 1.0\n")

def process_yolo_dataset(ds_config):
    # Food Recognation is already in YOLO format (mostly)
    print(f"Processing {ds_config['name']} (YOLO)...")
    ds_path = os.path.join(BASE_DIR, ds_config['path'])
    
    # We need to map labels
    # Food Recognation.v4 labels: 0: Ayam Goreng, 1: Bakso, 2: Martabak Manis, 3: Rendang
    MAPPING = {
        0: UNIFIED_CLASSES.index("Ayam Goreng"),
        1: UNIFIED_CLASSES.index("Bakso"),
        2: UNIFIED_CLASSES.index("Martabak Manis"),
        3: UNIFIED_CLASSES.index("Rendang")
    }
    
    for split in ['train', 'valid', 'test']:
        src_img_dir = os.path.join(ds_path, split, 'images')
        src_lbl_dir = os.path.join(ds_path, split, 'labels')
        
        if not os.path.exists(src_img_dir):
            continue
            
        for f in os.listdir(src_img_dir):
            shutil.copy(os.path.join(src_img_dir, f), os.path.join(OUTPUT_DIR, split, 'images', f))
            
            lbl_f = f.rsplit('.', 1)[0] + '.txt'
            src_lbl = os.path.join(src_lbl_dir, lbl_f)
            if os.path.exists(src_lbl):
                with open(src_lbl, 'r') as fr:
                    lines = fr.readlines()
                with open(os.path.join(OUTPUT_DIR, split, 'labels', lbl_f), 'w') as fw:
                    for line in lines:
                        parts = line.split()
                        old_id = int(parts[0])
                        if old_id in MAPPING:
                            parts[0] = str(MAPPING[old_id])
                            fw.write(" ".join(parts) + "\n")

def create_yaml():
    data = {
        'path': OUTPUT_DIR,
        'train': 'train/images',
        'val': 'valid/images',
        'test': 'test/images',
        'names': {i: name for i, name in enumerate(UNIFIED_CLASSES)}
    }
    with open(os.path.join(OUTPUT_DIR, 'data.yaml'), 'w') as f:
        yaml.dump(data, f, default_flow_style=False)

if __name__ == "__main__":
    ensure_dirs()
    for ds in DATASETS:
        if ds['type'] == 'csv-multiclass':
            process_csv_dataset(ds)
        elif ds['type'] == 'yolo-obb':
            process_yolo_dataset(ds)
    create_yaml()
    print("Unified dataset created at:", OUTPUT_DIR)
