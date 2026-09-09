"""
Script untuk memperbaiki dataset fine-tuning deteksi makanan/minuman
Menambahkan deskripsi visual, konteks, dan format yang lebih efisien
"""

import json
import random
from pathlib import Path

# Deskripsi visual untuk kategori makanan Indonesia
VISUAL_DESCRIPTORS = {
    "nasi": ["putih", "bulir-bulir", "mengkilap", "tekstur lembut"],
    "ayam": ["coklat keemasan", "kulit renyah", "daging putih", "bumbu kuning"],
    "ikan": ["sisik mengkilap", "daging putih", "mata jernih", "sirip"],
    "sayur": ["hijau segar", "daun", "batang", "warna cerah"],
    "gorengan": ["coklat keemasan", "berminyak", "renyah", "tepung"],
    "sambal": ["merah", "cabai", "pedas", "pasta"],
    "tempe": ["putih", "fermentasi", "kotak", "kedelai"],
    "tahu": ["putih", "lembut", "kotak", "kedelai"],
    "rendang": ["coklat gelap", "daging", "santan", "bumbu kental"],
    "soto": ["kuah kuning", "kaldu", "sayuran", "daging"],
    "bakso": ["bulat", "kenyal", "kuah", "daging giling"],
    "mie": ["panjang", "kuning", "keriting", "basah/kering"],
    "sate": ["tusuk bambu", "bakar", "bumbu kacang", "daging kotak"],
    "gado-gado": ["sayur rebus", "bumbu kacang", "telur", "lontong"],
    "nasi goreng": ["nasi coklat", "telur", "sayuran", "kecap"],
    "buah": ["segar", "warna cerah", "kulit", "daging buah"],
    "minuman": ["cair", "gelas", "botol", "warna"],
    "kue": ["manis", "tekstur lembut", "warna-warni", "dekorasi"],
    "roti": ["coklat keemasan", "empuk", "ragi", "gandum"],
    "kerupuk": ["renyah", "tipis", "kering", "mengembang"]
}

def detect_food_category(food_name):
    """Deteksi kategori makanan berdasarkan nama"""
    name_lower = food_name.lower()
    
    for category, descriptors in VISUAL_DESCRIPTORS.items():
        if category in name_lower:
            return category, descriptors
    
    # Default kategori
    if any(x in name_lower for x in ["ikan", "udang", "cumi", "kepiting"]):
        return "ikan", VISUAL_DESCRIPTORS["ikan"]
    elif any(x in name_lower for x in ["ayam", "bebek", "burung"]):
        return "ayam", VISUAL_DESCRIPTORS["ayam"]
    elif any(x in name_lower for x in ["sapi", "kambing", "daging"]):
        return "rendang", VISUAL_DESCRIPTORS["rendang"]
    elif any(x in name_lower for x in ["daun", "sayur", "kangkung", "bayam"]):
        return "sayur", VISUAL_DESCRIPTORS["sayur"]
    elif any(x in name_lower for x in ["goreng", "keripik", "kripik"]):
        return "gorengan", VISUAL_DESCRIPTORS["gorengan"]
    elif any(x in name_lower for x in ["buah", "jeruk", "apel", "pisang"]):
        return "buah", VISUAL_DESCRIPTORS["buah"]
    elif any(x in name_lower for x in ["susu", "teh", "kopi", "jus"]):
        return "minuman", VISUAL_DESCRIPTORS["minuman"]
    
    return "makanan umum", ["warna khas", "tekstur", "bentuk"]

def create_improved_prompt(food_name, category, calories, protein, fat, carbs, visual_desc):
    """Buat prompt yang lebih baik untuk deteksi makanan"""
    
    # Pilih 2-3 deskriptor visual
    selected_visuals = random.sample(visual_desc, min(3, len(visual_desc)))
    visual_text = ", ".join(selected_visuals)
    
    # Tentukan ukuran porsi berdasarkan kalori
    if calories < 100:
        portion = "porsi kecil"
    elif calories < 300:
        portion = "porsi sedang"
    else:
        portion = "porsi besar"
    
    # Input prompt yang lebih natural
    prompts = [
        f"Identifikasi makanan: {food_name}",
        f"Apa ini? Terlihat seperti {food_name}",
        f"Deteksi makanan dengan ciri: {visual_text}",
        f"Makanan {category} yang terlihat {visual_text}",
        f"Scan nutrisi: {food_name}"
    ]
    
    input_text = random.choice(prompts)
    
    # Output yang lebih ringkas dan informatif
    output_parts = [
        f"[FOOD] {food_name}",
        f"[NUTRITION] {calories} kkal | P:{protein}g | L:{fat}g | K:{carbs}g",
        f"[VISUAL] {visual_text}",
        f"[PORTION] {portion}"
    ]
    
    # Tambah warning jika tinggi kalori/lemak
    if calories > 400:
        output_parts.append("[WARNING] Tinggi kalori")
    if fat > 20:
        output_parts.append("[WARNING] Tinggi lemak")
    if carbs > 50:
        output_parts.append("[WARNING] Tinggi karbohidrat")
    
    output_text = " | ".join(output_parts)
    
    return {"text_input": input_text, "output": output_text}

def improve_dataset(input_file, output_file):
    """Perbaiki dataset dengan format baru"""
    
    improved_data = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip():
                continue
                
            data = json.loads(line)
            
            # Parse data lama
            output = data['output']
            lines = output.split('\n')
            
            food_name = lines[0].replace('Makanan: ', '').strip()
            
            # Extract nutrisi dengan error handling
            calories = 0
            protein = 0
            fat = 0
            carbs = 0
            
            for line in lines:
                try:
                    if '- Kalori:' in line:
                        calories = float(line.split(':')[1].replace('kkal', '').strip())
                    elif '- Protein:' in line:
                        protein = float(line.split(':')[1].replace('g', '').strip())
                    elif '- Lemak:' in line:
                        fat = float(line.split(':')[1].replace('g', '').strip())
                    elif '- Karbohidrat:' in line:
                        carbs = float(line.split(':')[1].replace('g', '').strip())
                except (ValueError, IndexError):
                    continue
            
            # Skip jika data tidak lengkap
            if calories == 0:
                continue
            
            # Deteksi kategori dan visual
            category, visual_desc = detect_food_category(food_name)
            
            # Buat prompt baru
            improved = create_improved_prompt(
                food_name, category, calories, protein, fat, carbs, visual_desc
            )
            
            improved_data.append(improved)
            
            # Augmentasi: buat variasi prompt
            if random.random() < 0.3:  # 30% data dapat augmentasi
                improved2 = create_improved_prompt(
                    food_name, category, calories, protein, fat, carbs, visual_desc
                )
                improved_data.append(improved2)
    
    # Tulis dataset baru
    with open(output_file, 'w', encoding='utf-8') as f:
        for item in improved_data:
            f.write(json.dumps(item, ensure_ascii=False) + '\n')
    
    return len(improved_data)

def main():
    base_path = Path(__file__).parent.parent / 'finetuned_datasets'
    
    print("[*] Memperbaiki dataset fine-tuning...")
    
    # Perbaiki semua dataset
    for split in ['train', 'validation', 'test']:
        input_file = base_path / f'{split}.jsonl'
        output_file = base_path / f'{split}_improved.jsonl'
        
        if input_file.exists():
            count = improve_dataset(input_file, output_file)
            print(f"[OK] {split}: {count} sampel (improved)")
    
    print("\n[INFO] Dataset baru:")
    print("- Format lebih ringkas")
    print("- Deskripsi visual ditambahkan")
    print("- Prompt lebih natural")
    print("- Augmentasi variasi prompt")
    print("\n[TIP] Gunakan file *_improved.jsonl untuk fine-tuning")

if __name__ == "__main__":
    main()
