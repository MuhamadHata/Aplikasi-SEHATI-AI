import csv
import json
import os

def prepare_diabetes_dataset(csv_path, jsonl_path):
    # Features from diabetes.csv:
    # Pregnancies,Glucose,BloodPressure,SkinThickness,Insulin,BMI,DiabetesPedigreeFunction,Age,Outcome
    # Outcome 1 = Diabetes, 0 = No Diabetes
    
    if not os.path.exists(csv_path):
        print(f"File not found: {csv_path}")
        return

    with open(csv_path, 'r', encoding='utf-8') as f_in, open(jsonl_path, 'w', encoding='utf-8') as f_out:
        reader = csv.DictReader(f_in)
        for row in reader:
            try:
                # We turn the row into a prompt instruction
                prompt = (f"Pregnancies: {row['Pregnancies']}, "
                          f"Glucose: {row['Glucose']}, "
                          f"BloodPressure: {row['BloodPressure']}, "
                          f"SkinThickness: {row['SkinThickness']}, "
                          f"Insulin: {row['Insulin']}, "
                          f"BMI: {row['BMI']}, "
                          f"DiabetesPedigreeFunction: {row['DiabetesPedigreeFunction']}, "
                          f"Age: {row['Age']}")
                
                # Output based on outcome
                outcome = int(row['Outcome'])
                if outcome == 1:
                    result = "Terindikasi Positif Diabetes (Risiko Tinggi)"
                else:
                    result = "Negatif Diabetes (Risiko Rendah)"
                
                # Gemini fine-tuning format
                # Using simple text-to-text format for AI Studio
                # {"text_input": "...", "output": "..."}
                json_line = {
                    "text_input": prompt,
                    "output": result
                }
                
                f_out.write(json.dumps(json_line) + "\n")
            except Exception as e:
                print(f"Error processing row: {e}")

    print(f"Successfully created: {jsonl_path} for Diabetes dataset")


def prepare_nutrition_dataset(csv_path, jsonl_path):
    # Features from nutrition.csv:
    # id,calories,proteins,fat,carbohydrate,name,image
    
    if not os.path.exists(csv_path):
        print(f"File not found: {csv_path}")
        return

    with open(csv_path, 'r', encoding='utf-8') as f_in, open(jsonl_path, 'w', encoding='utf-8') as f_out:
        reader = csv.DictReader(f_in)
        for row in reader:
            try:
                name = row.get('name', '').strip()
                if not name:
                    continue
                
                prompt = f"Berapa nutrisi dari makanan/minuman {name}?"
                
                # Create structured output
                nutrisi = {
                    "calories": float(row.get('calories', 0) or 0),
                    "protein": float(row.get('proteins', 0) or 0),
                    "fat": float(row.get('fat', 0) or 0),
                    "carbs": float(row.get('carbohydrate', 0) or 0),
                    "ingredients": [], # Add logic here if dataset has ingredients later
                    "sugarGrams": 0.0, # Not provided in dataset but required by prompt structure
                    "caffeineMg": 0,
                }
                
                result = json.dumps(nutrisi)
                
                json_line = {
                    "text_input": prompt,
                    "output": result
                }
                
                f_out.write(json.dumps(json_line) + "\n")
            except Exception as e:
                # Silently skip bad rows
                pass

    print(f"Successfully created: {jsonl_path} for Nutrition dataset")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dataset_dir = os.path.join(base_dir, 'dataset')
    
    diabetes_csv = os.path.join(dataset_dir, 'diabetes.csv')
    diabetes_jsonl = os.path.join(dataset_dir, 'diabetes_finetune.jsonl')
    
    nutrition_csv = os.path.join(dataset_dir, 'nutrition.csv')
    nutrition_jsonl = os.path.join(dataset_dir, 'nutrition_finetune.jsonl')
    
    prepare_diabetes_dataset(diabetes_csv, diabetes_jsonl)
    prepare_nutrition_dataset(nutrition_csv, nutrition_jsonl)
    
    print("\nFile .jsonl siap! Anda bisa mengunggah file ini ke Google AI Studio untuk model Tuning.")
