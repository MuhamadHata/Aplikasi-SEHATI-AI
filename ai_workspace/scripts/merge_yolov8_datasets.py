import os
import shutil
import yaml
from pathlib import Path

# Paths
BASE_DIR = r"E:\Nubi\ai_workspace\dataset"
OUTPUT_DIR = os.path.join(BASE_DIR, "unified_yolo_dataset")

DATASETS = [
    {
        "path": "Food Recognation.v4-roboflow-instant-2--eval-.yolov8-obb",
        "names": {
            0: 'Ayam Goreng', 1: 'Bakso', 2: 'Bubur Ayam', 3: 'Cakwe', 4: 'Dadar Gulung',
            5: 'Ikan Goreng', 6: 'Klepon', 7: 'Lontong Sayur', 8: 'Martabak Manis', 9: 'Mie Goreng',
            10: 'Nasi Padang', 11: 'Rendang', 12: 'Risol', 13: 'Rujak', 14: 'Rujak Buah',
            15: 'Sayur Asem', 16: 'Soto Ayam', 17: 'nasi goreng', 18: 'pecel lele', 19: 'rawon', 20: 'sate'
        }
    },
    {
        "path": "Indonesia Food.v1i.yolov8",
        "names": {
            0: 'Ayam Bakar', 1: 'Ayam Goreng', 2: 'Bakso', 3: 'Capcay', 4: 'Donat',
            5: 'Ikan Bakar', 6: 'Ikan Goreng', 7: 'Kentang Goreng', 8: 'Kentang Rebus', 9: 'Nasi Putih',
            10: 'Puding', 11: 'Rendang', 12: 'Roti Tawar', 13: 'Sate', 14: 'Sayur Sop',
            15: 'Tahu Goreng', 16: 'Telur Ceplok', 17: 'Telur Dadar', 18: 'Telur Rebus', 19: 'Tempe Goreng', 20: 'Tumis kangkung'
        }
    },
    {
        "path": "Indonesia-Food.v2i.yolov8",
        "names": {
            0: 'Nasi Putih', 1: 'rendang sapi'
        }
    }
]

# Alias map for fixing inconsistencies across datasets
ALIAS_MAP = {
    'rendang sapi': 'Rendang',
    'nasi goreng': 'Nasi Goreng',
    'sate': 'Sate',
    'pecel lele': 'Pecel Lele',
    'rawon': 'Rawon',
    'tumis kangkung': 'Tumis Kangkung'
}

UNIFIED_CLASSES = []

def normalize_name(name):
    # Lowercase then title case, then check alias
    n = name.strip().title()
    if name.lower() in ALIAS_MAP:
        n = ALIAS_MAP[name.lower()]
    elif name in ALIAS_MAP:
        n = ALIAS_MAP[name]
    return n

def build_unified_classes():
    global UNIFIED_CLASSES
    unique_classes = set()
    for ds in DATASETS:
        for idx, name in ds['names'].items():
            unique_classes.add(normalize_name(name))
    
    UNIFIED_CLASSES = sorted(list(unique_classes))
    print(f"Total unified classes: {len(UNIFIED_CLASSES)}")
    for i, c in enumerate(UNIFIED_CLASSES):
        print(f" {i}: {c}")

def ensure_output_directories():
    for split in ['train', 'valid', 'test']:
        os.makedirs(os.path.join(OUTPUT_DIR, split, 'images'), exist_ok=True)
        os.makedirs(os.path.join(OUTPUT_DIR, split, 'labels'), exist_ok=True)

def merge_datasets():
    image_counter = 0
    for ds_idx, ds in enumerate(DATASETS):
        ds_path = os.path.join(BASE_DIR, ds['path'])
        if not os.path.exists(ds_path):
            print(f"Warning: Dataset path does not exist skipping... {ds_path}")
            continue
            
        print(f"Merging dataset: {ds['path']}...")
        
        # Build local index to unified index map
        local_to_unified = {}
        for local_idx, name in ds['names'].items():
            normalized = normalize_name(name)
            unified_idx = UNIFIED_CLASSES.index(normalized)
            local_to_unified[local_idx] = unified_idx
            
        for split in ['train', 'valid', 'test']:
            img_dir = os.path.join(ds_path, split, 'images')
            lbl_dir = os.path.join(ds_path, split, 'labels')
            
            # Note: roboflow sometimes exports validation as 'valid' instead of val, while images inside are still test/train/val.
            # Handle possible naming variations
            if not os.path.exists(img_dir):
                if split == 'valid' and os.path.exists(os.path.join(ds_path, 'val', 'images')):
                    img_dir = os.path.join(ds_path, 'val', 'images')
                    lbl_dir = os.path.join(ds_path, 'val', 'labels')
                else:
                    continue
            
            for file_name in os.listdir(img_dir):
                if not file_name.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp')):
                    continue
                
                # New unique filename to prevent clashes
                name, ext = os.path.splitext(file_name)
                new_file_name = f"ds{ds_idx}_{name}_{image_counter}{ext}"
                new_lbl_name = f"ds{ds_idx}_{name}_{image_counter}.txt"
                image_counter += 1
                
                # Copy Image
                shutil.copy(os.path.join(img_dir, file_name), os.path.join(OUTPUT_DIR, split, 'images', new_file_name))
                
                # Read and map labels
                lbl_file = name + '.txt'
                lbl_path = os.path.join(lbl_dir, lbl_file)
                if os.path.exists(lbl_path):
                    with open(lbl_path, 'r') as fr:
                        lines = fr.readlines()
                        
                    with open(os.path.join(OUTPUT_DIR, split, 'labels', new_lbl_name), 'w') as fw:
                        for line in lines:
                            parts = line.strip().split()
                            if len(parts) >= 5: 
                                local_class = int(parts[0])
                                if local_class in local_to_unified:
                                    
                                    # Handle OBB to HBB (if parts > 5, usually 9: class x1 y1 x2 y2 x3 y3 x4 y4)
                                    if len(parts) == 9:
                                        coords = [float(p) for p in parts[1:]]
                                        xs = coords[0::2]
                                        ys = coords[1::2]
                                        x_min, x_max = min(xs), max(xs)
                                        y_min, y_max = min(ys), max(ys)
                                        xc = (x_min + x_max) / 2.0
                                        yc = (y_min + y_max) / 2.0
                                        w = x_max - x_min
                                        h = y_max - y_min
                                        
                                        # Clamp to [0.0, 1.0]
                                        xc = max(0.0, min(1.0, xc))
                                        yc = max(0.0, min(1.0, yc))
                                        w = max(0.0, min(1.0, w))
                                        h = max(0.0, min(1.0, h))
                                        
                                        parts = [str(local_class), f"{xc:.6f}", f"{yc:.6f}", f"{w:.6f}", f"{h:.6f}"]
                                    else:
                                        parts[0] = str(local_to_unified[local_class])
                                        # Ensure any classic box isn't out of bounds either
                                        if len(parts) == 5:
                                            parts[1] = f"{max(0.0, min(1.0, float(parts[1]))):.6f}"
                                            parts[2] = f"{max(0.0, min(1.0, float(parts[2]))):.6f}"
                                            parts[3] = f"{max(0.0, min(1.0, float(parts[3]))):.6f}"
                                            parts[4] = f"{max(0.0, min(1.0, float(parts[4]))):.6f}"
                                            
                                    fw.write(" ".join(parts) + "\n")

def write_yaml():
    yaml_path = os.path.join(OUTPUT_DIR, 'data.yaml')
    data = {
        'path': OUTPUT_DIR,
        'train': 'train/images',
        'val': 'valid/images',
        'test': 'test/images',
        'nc': len(UNIFIED_CLASSES),
        'names': {i: name for i, name in enumerate(UNIFIED_CLASSES)}
    }
    with open(yaml_path, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)
    print(f"data.yaml written to {yaml_path}")

if __name__ == "__main__":
    build_unified_classes()
    ensure_output_directories()
    merge_datasets()
    write_yaml()
    print("Dataset Merge Complete!")
