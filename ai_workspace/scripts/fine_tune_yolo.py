from ultralytics import YOLO
import os

# Configuration
DATASET_YAML = r"c:\Users\M HATTA\.gemini\antigravity\scratch\nubi_final\ai_workspace\dataset\unified_food_v1\data.yaml"
BASE_MODEL = "yolov8n.pt"  # Use Nano model for performance on mobile
PROJECT_NAME = "nubi_food_detection"
EXPERIMENT_NAME = "v1_unified_fine_tune"

def train_model():
    print(f"Starting fine-tuning YOLO on {DATASET_YAML}...")
    
    # Load a pretrained YOLOv8n model
    model = YOLO(BASE_MODEL)
    
    # Fine-tune the model
    # We use augment=True and specific hyperparameters to handle diverse Indonesian cooking styles
    results = model.train(
        data=DATASET_YAML,
        epochs=100,
        imgsz=640,
        batch=16,
        project=PROJECT_NAME,
        name=EXPERIMENT_NAME,
        optimizer='Adam',
        lr0=0.01,
        augment=True,
        mosaic=1.0,  # Highly effective for food plates
        mixup=0.1,   # Helps with overlapping ingredients
        dropout=0.1, # Prevent overfitting on small datasets
        device=0      # 'cpu' if no GPU available
    )
    
    print("Fine-tuning complete. Model saved in project directory.")

if __name__ == "__main__":
    train_model()
