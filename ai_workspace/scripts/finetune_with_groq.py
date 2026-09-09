"""
Fine-tune model dengan Groq API menggunakan dataset improved
"""

import json
import os
import sys
from pathlib import Path
import requests
import time

def load_jsonl(file_path):
    """Load JSONL file"""
    data = []
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                data.append(json.loads(line))
    return data

def finetune_with_groq(train_file, val_file, api_key):
    """
    Fine-tune dengan Groq API
    Note: Groq saat ini belum support fine-tuning API seperti OpenAI
    Script ini akan prepare data dan memberikan instruksi
    """
    
    print("\n" + "="*60)
    print("GROQ FINE-TUNING PREPARATION")
    print("="*60)
    
    # Load data
    print(f"\n[INFO] Loading training data: {train_file}")
    train_data = load_jsonl(train_file)
    print(f"[OK] Loaded {len(train_data)} training samples")
    
    print(f"\n[INFO] Loading validation data: {val_file}")
    val_data = load_jsonl(val_file)
    print(f"[OK] Loaded {len(val_data)} validation samples")
    
    # Groq info
    print("\n" + "="*60)
    print("IMPORTANT: Groq Fine-Tuning Information")
    print("="*60)
    print("""
Groq saat ini belum menyediakan public fine-tuning API seperti OpenAI.

Namun, Anda bisa menggunakan dataset improved ini untuk:

1. **Prompt Engineering dengan Groq**
   - Gunakan dataset sebagai few-shot examples
   - Inject examples ke dalam prompt
   - Groq models (Llama, Mixtral) sangat baik dengan few-shot learning

2. **Fine-tune dengan Platform Lain**
   - OpenAI (GPT-3.5/4)
   - Google Gemini
   - Anthropic Claude
   - Hugging Face (open source models)

3. **Local Fine-tuning**
   - Download Llama 3 / Mixtral
   - Fine-tune dengan LoRA/QLoRA
   - Deploy sendiri

Dataset Anda sudah siap dalam format yang kompatibel!
""")
    
    # Show example
    print("\n" + "="*60)
    print("EXAMPLE: Few-Shot Prompting dengan Groq")
    print("="*60)
    
    # Create few-shot prompt
    examples = train_data[:3]  # Take 3 examples
    
    few_shot_prompt = "Anda adalah AI ahli nutrisi makanan Indonesia. Berikut contoh:\n\n"
    
    for i, ex in enumerate(examples, 1):
        few_shot_prompt += f"Contoh {i}:\n"
        few_shot_prompt += f"Input: {ex['text_input']}\n"
        few_shot_prompt += f"Output: {ex['output']}\n\n"
    
    few_shot_prompt += "Sekarang, jawab pertanyaan berikut:\n"
    few_shot_prompt += "Input: Identifikasi makanan: Nasi Goreng\n"
    few_shot_prompt += "Output:"
    
    print(few_shot_prompt)
    
    # Test with Groq API
    print("\n" + "="*60)
    print("TESTING dengan Groq API")
    print("="*60)
    
    try:
        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "llama-3.3-70b-versatile",  # atau "mixtral-8x7b-32768"
            "messages": [
                {
                    "role": "system",
                    "content": "Anda adalah AI ahli nutrisi makanan Indonesia yang memberikan informasi nutrisi lengkap."
                },
                {
                    "role": "user",
                    "content": few_shot_prompt
                }
            ],
            "temperature": 0.3,
            "max_tokens": 500
        }
        
        print("[INFO] Mengirim request ke Groq API...")
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            answer = result['choices'][0]['message']['content']
            
            print("\n[SUCCESS] Response dari Groq:")
            print("-" * 60)
            print(answer)
            print("-" * 60)
            
            print("\n✅ Groq API berfungsi dengan baik!")
            print("✅ Few-shot learning berhasil!")
            
        else:
            print(f"\n[ERROR] Groq API error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"\n[ERROR] Gagal test Groq API: {e}")
    
    # Save few-shot template
    template_file = Path(train_file).parent / "groq_fewshot_template.txt"
    with open(template_file, 'w', encoding='utf-8') as f:
        f.write(few_shot_prompt)
    
    print(f"\n[INFO] Few-shot template disimpan: {template_file}")
    
    # Recommendations
    print("\n" + "="*60)
    print("REKOMENDASI NEXT STEPS")
    print("="*60)
    print("""
1. **Gunakan Few-Shot Learning dengan Groq** (Recommended)
   - Inject 3-5 examples ke setiap prompt
   - Groq models sangat baik dengan few-shot
   - Gratis dan cepat!

2. **Fine-tune dengan OpenAI**
   ```bash
   # Upload dataset
   openai api fine_tunes.create \\
     -t train_improved.jsonl \\
     -v validation_improved.jsonl \\
     -m gpt-3.5-turbo
   ```

3. **Fine-tune dengan Gemini**
   - Gunakan Google AI Studio
   - Upload dataset improved
   - Fine-tune Gemini 1.5

4. **Local Fine-tuning (Advanced)**
   ```bash
   # Download Llama 3
   # Fine-tune dengan LoRA
   # Deploy dengan vLLM/Ollama
   ```

Dataset Anda sudah optimal untuk semua opsi di atas!
""")
    
    return True

def main():
    # Get API key
    api_key = os.getenv("NUBI_GROQ_KEYS")
    if not api_key:
        print("[ERROR] NUBI_GROQ_KEYS tidak ditemukan!")
        print("Set dengan: $env:NUBI_GROQ_KEYS=\"gsk_your_key\"")
        return
    
    # Get dataset paths
    base_dir = Path(__file__).parent.parent / "finetuned_datasets"
    train_file = base_dir / "train_improved.jsonl"
    val_file = base_dir / "validation_improved.jsonl"
    
    if not train_file.exists():
        print(f"[ERROR] Training file tidak ditemukan: {train_file}")
        print("Jalankan improve_food_detection_dataset.py terlebih dahulu")
        return
    
    if not val_file.exists():
        print(f"[ERROR] Validation file tidak ditemukan: {val_file}")
        return
    
    # Run fine-tuning
    finetune_with_groq(str(train_file), str(val_file), api_key)

if __name__ == "__main__":
    main()
