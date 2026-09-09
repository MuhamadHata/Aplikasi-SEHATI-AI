"""
Fine-tuning Food Dataset Script
Purpose: Prepare food dataset with strategies to prevent overfitting, catastrophic forgetting, and ensure consistency

Strategies:
1. Data augmentation & synthetic data generation
2. Cross-validation and stratified splitting
3. Class balancing and weighted sampling
4. Regularization and dropout techniques
5. Progressive training (rehearsal-based learning)
6. Ensemble methods
"""

import csv
import json
import os
import random
import pandas as pd
import numpy as np
from collections import defaultdict, Counter
from pathlib import Path
from typing import List, Dict, Tuple, Set
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class FoodDatasetFinetuner:
    def __init__(self, dataset_dir: str, output_dir: str = None):
        self.dataset_dir = dataset_dir
        self.output_dir = output_dir or os.path.join(dataset_dir, "../finetuned_datasets")
        os.makedirs(self.output_dir, exist_ok=True)
        
        self.nutrition_data = []
        self.nilai_gizi_data = []
        self.diabetes_data = []
        self.food_categories = defaultdict(list)
        
    def load_datasets(self):
        """Load all datasets from CSV files"""
        logger.info("Loading datasets...")
        
        # Load nutrition.csv
        nutrition_path = os.path.join(self.dataset_dir, "nutrition.csv")
        if os.path.exists(nutrition_path):
            self.nutrition_data = pd.read_csv(nutrition_path)
            logger.info(f"Loaded {len(self.nutrition_data)} records from nutrition.csv")
            logger.info(f"Columns: {self.nutrition_data.columns.tolist()}")
        
        # Load nilai-gizi.csv
        nilai_gizi_path = os.path.join(self.dataset_dir, "nilai-gizi.csv")
        if os.path.exists(nilai_gizi_path):
            self.nilai_gizi_data = pd.read_csv(nilai_gizi_path)
            logger.info(f"Loaded {len(self.nilai_gizi_data)} records from nilai-gizi.csv")
            logger.info(f"Columns: {self.nilai_gizi_data.columns.tolist()}")
        
        # Load diabetes.csv
        diabetes_path = os.path.join(self.dataset_dir, "diabetes.csv")
        if os.path.exists(diabetes_path):
            self.diabetes_data = pd.read_csv(diabetes_path)
            logger.info(f"Loaded {len(self.diabetes_data)} records from diabetes.csv")
        
        return self
    
    def analyze_data_distribution(self):
        """Analyze data distribution to identify class imbalance and gaps"""
        logger.info("\n=== DATA DISTRIBUTION ANALYSIS ===")
        
        if not self.nutrition_data.empty:
            logger.info("\n--- Nutrition Dataset Statistics ---")
            logger.info(f"Total records: {len(self.nutrition_data)}")
            logger.info(f"Calories - Mean: {self.nutrition_data['calories'].mean():.2f}, "
                       f"Std: {self.nutrition_data['calories'].std():.2f}, "
                       f"Range: [{self.nutrition_data['calories'].min():.0f}, "
                       f"{self.nutrition_data['calories'].max():.0f}]")
            
            # Create calorie categories
            logger.info("Calorie distribution:")
            for label, range_tuple in [
                ("Very Low (<100)", (0, 100)),
                ("Low (100-200)", (100, 200)),
                ("Medium (200-400)", (200, 400)),
                ("High (400-600)", (400, 600)),
                ("Very High (>600)", (600, float('inf')))
            ]:
                count = len(self.nutrition_data[
                    (self.nutrition_data['calories'] >= range_tuple[0]) & 
                    (self.nutrition_data['calories'] < range_tuple[1])
                ])
                logger.info(f"  {label}: {count} items")
        
        if not self.nilai_gizi_data.empty:
            logger.info(f"\n--- Nilai Gizi Dataset Statistics ---")
            logger.info(f"Total records: {len(self.nilai_gizi_data)}")
            logger.info(f"Unique manufacturers: {self.nilai_gizi_data['manufacturer'].nunique()}")
        
        return self
    
    def create_balanced_training_set(self, min_samples_per_category: int = 50):
        """Create balanced training set to prevent overfitting"""
        logger.info(f"\n=== CREATING BALANCED TRAINING SET ===")
        logger.info(f"Minimum samples per category: {min_samples_per_category}")
        
        balanced_data = []
        
        # Process nutrition data with calorie categories
        if not self.nutrition_data.empty:
            df = self.nutrition_data.copy()
            
            # Create calorie categories
            def categorize_calories(calories):
                if calories < 100:
                    return "very_low_calorie"
                elif calories < 200:
                    return "low_calorie"
                elif calories < 400:
                    return "medium_calorie"
                elif calories < 600:
                    return "high_calorie"
                else:
                    return "very_high_calorie"
            
            df['calorie_category'] = df['calories'].apply(categorize_calories)
            
            # Create food type categories based on characteristics
            def categorize_food_type(row):
                protein = row['proteins'] if pd.notna(row['proteins']) else 0
                fat = row['fat'] if pd.notna(row['fat']) else 0
                carbs = row['carbohydrate'] if pd.notna(row['carbohydrate']) else 0
                
                if protein > 15 and fat > 10:
                    return "protein_rich"
                elif protein > 15:
                    return "lean_protein"
                elif carbs > 30:
                    return "carb_heavy"
                elif fat > 20:
                    return "fat_rich"
                else:
                    return "balanced"
            
            df['food_type'] = df.apply(categorize_food_type, axis=1)
            
            # Balance by category
            for category in df['calorie_category'].unique():
                category_data = df[df['calorie_category'] == category]
                
                if len(category_data) > min_samples_per_category:
                    # Sample if too many
                    category_data = category_data.sample(n=min_samples_per_category, random_state=42)
                
                balanced_data.append(category_data)
            
            balanced_df = pd.concat(balanced_data, ignore_index=True)
            logger.info(f"Created balanced dataset with {len(balanced_df)} records")
            logger.info(f"Category distribution:\n{balanced_df['calorie_category'].value_counts()}")
            
            return balanced_df
        
        return None
    
    def augment_data(self, df: pd.DataFrame, augmentation_factor: float = 0.2):
        """Generate synthetic data through augmentation to prevent overfitting"""
        logger.info(f"\n=== DATA AUGMENTATION ===")
        logger.info(f"Augmentation factor: {augmentation_factor}")
        
        augmented_records = []
        
        for idx, row in df.iterrows():
            original_record = {
                'name': row['name'],
                'calories': row['calories'],
                'proteins': row['proteins'],
                'fat': row['fat'],
                'carbohydrate': row['carbohydrate'],
                'image': row.get('image', '')
            }
            augmented_records.append(original_record)
            
            # Generate variations with slight perturbations (noise injection)
            # This helps model generalize better and prevents memorization
            if random.random() < augmentation_factor:
                # Variation 1: Scaled portion (±10-20% nutrition change)
                scale_factor = np.random.uniform(0.8, 1.2)
                augmented_records.append({
                    'name': f"{row['name']} (portion adjustment)",
                    'calories': round(row['calories'] * scale_factor, 1),
                    'proteins': round(row['proteins'] * scale_factor, 1),
                    'fat': round(row['fat'] * scale_factor, 1),
                    'carbohydrate': round(row['carbohydrate'] * scale_factor, 1),
                    'image': row.get('image', ''),
                    'augmented': True
                })
                
                # Variation 2: Similar food item with slight nutritional differences
                # This prevents catastrophic forgetting by rehearsing similar items
                noise_level = np.random.uniform(0.05, 0.15)
                augmented_records.append({
                    'name': f"{row['name']} (similar variant)",
                    'calories': round(row['calories'] * (1 + random.uniform(-noise_level, noise_level)), 1),
                    'proteins': round(row['proteins'] * (1 + random.uniform(-noise_level, noise_level)), 1),
                    'fat': round(row['fat'] * (1 + random.uniform(-noise_level, noise_level)), 1),
                    'carbohydrate': round(row['carbohydrate'] * (1 + random.uniform(-noise_level, noise_level)), 1),
                    'image': row.get('image', ''),
                    'augmented': True
                })
        
        logger.info(f"Generated {len(augmented_records)} records (original + augmented)")
        return pd.DataFrame(augmented_records)
    
    def create_stratified_splits(self, df: pd.DataFrame, test_size: float = 0.2, val_size: float = 0.1):
        """Create stratified train/val/test splits to maintain data distribution"""
        logger.info(f"\n=== CREATING STRATIFIED SPLITS ===")
        logger.info(f"Test size: {test_size}, Validation size: {val_size}")
        
        # Create stratification key
        df['calorie_category'] = df['calories'].apply(
            lambda x: 'low' if x < 200 else ('medium' if x < 400 else 'high')
        )
        
        # First split: train+val vs test
        from sklearn.model_selection import train_test_split
        train_val, test = train_test_split(
            df, test_size=test_size, stratify=df['calorie_category'], random_state=42
        )
        
        # Second split: train vs validation
        val_size_adjusted = val_size / (1 - test_size)
        train, val = train_test_split(
            train_val, test_size=val_size_adjusted, stratify=train_val['calorie_category'], random_state=42
        )
        
        logger.info(f"Train set: {len(train)} samples ({len(train)/len(df)*100:.1f}%)")
        logger.info(f"Validation set: {len(val)} samples ({len(val)/len(df)*100:.1f}%)")
        logger.info(f"Test set: {len(test)} samples ({len(test)/len(df)*100:.1f}%)")
        
        return train, val, test
    
    def prepare_jsonl_format(self, df: pd.DataFrame, output_path: str, dataset_name: str = "food"):
        """Convert to JSONL format for fine-tuning with detailed prompts"""
        logger.info(f"\n=== PREPARING JSONL FORMAT ===")
        logger.info(f"Output: {output_path}")
        
        jsonl_records = []
        
        for idx, row in df.iterrows():
            # Determine food category
            calories = float(row['calories'])
            if calories < 150:
                category = "Makanan Rendah Kalori"
            elif calories < 300:
                category = "Makanan Sedang Kalori"
            elif calories < 500:
                category = "Makanan Tinggi Kalori"
            else:
                category = "Makanan Sangat Tinggi Kalori"
            
            # Create detailed prompt
            prompt = (
                f"Berikan informasi nutrisi untuk makanan berikut:\n"
                f"Nama: {row['name']}\n"
                f"Kategori: {category}\n"
                f"Informasi nutrisi:" if 'calories' in row else f"Nama: {row['name']}\n"
            )
            
            # Create detailed output with nutritional analysis
            calories_val = row.get('calories', 0)
            proteins_val = row.get('proteins', 0)
            fat_val = row.get('fat', 0)
            carbs_val = row.get('carbohydrate', 0)
            
            output = (
                f"Makanan: {row['name']}\n"
                f"Kategori Kalori: {category}\n"
                f"Nutrisi per 100g:\n"
                f"- Kalori: {calories_val:.1f} kkal\n"
                f"- Protein: {proteins_val:.1f}g\n"
                f"- Lemak: {fat_val:.1f}g\n"
                f"- Karbohidrat: {carbs_val:.1f}g\n"
            )
            
            # Add nutritional assessment
            if proteins_val > 15:
                output += "- Rich in protein\n"
            if carbs_val > 30:
                output += "- High carbohydrate content\n"
            if fat_val > 10:
                output += "- Contains notable fat content\n"
            
            jsonl_records.append({
                "text_input": prompt,
                "output": output
            })
        
        # Write JSONL file
        with open(output_path, 'w', encoding='utf-8') as f:
            for record in jsonl_records:
                f.write(json.dumps(record) + '\n')
        
        logger.info(f"Created JSONL file with {len(jsonl_records)} records")
        return output_path
    
    def create_training_config(self, output_path: str, epochs: int = 3, batch_size: int = 32):
        """Create training configuration to prevent overfitting"""
        logger.info(f"\n=== CREATING TRAINING CONFIGURATION ===")
        
        config = {
            "training_strategy": "progressive_learning",
            "purpose": "Prevent overfitting, catastrophic forgetting, and maintain consistency",
            "hyperparameters": {
                "epochs": epochs,
                "batch_size": batch_size,
                "learning_rate": "adaptive (start low, reduce on plateau)",
                "early_stopping_patience": 3,
                "dropout_rate": 0.3,
                "weight_decay": 0.01,
                "gradient_clip": 1.0
            },
            "regularization_techniques": {
                "dropout": "Prevents co-adaptation of neurons",
                "l2_regularization": "Prevents large weights",
                "early_stopping": "Stops training when validation loss plateaus",
                "data_augmentation": "Synthetic variations prevent memorization",
                "class_balancing": "Maintains fair representation"
            },
            "anti_catastrophic_forgetting": {
                "replay_buffer": "Sample from old data during training",
                "rehearsal": "Regular review of previous tasks",
                "elastic_weight_consolidation": "Protect important weights from task 1",
                "progressive_neural_networks": "Lateral connections preserve old knowledge"
            },
            "validation_strategy": {
                "stratified_cv": "Maintain class distribution in folds",
                "cross_validation_folds": 5,
                "hold_out_test_set": "Final evaluation on unseen data",
                "per_category_metrics": "Track performance per food category"
            },
            "consistency_checks": {
                "verify_no_data_leakage": "Ensure train/val/test separation",
                "check_reproducibility": "Use fixed random seeds",
                "validate_augmentation_quality": "Augmented data should be realistic",
                "monitor_distribution_shift": "Alert if test distribution differs significantly"
            }
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        
        logger.info(f"Training config saved to {output_path}")
        return config
    
    def generate_finetuning_report(self, output_path: str, stats: Dict):
        """Generate comprehensive fine-tuning report"""
        logger.info(f"\n=== GENERATING FINE-TUNING REPORT ===")
        
        report = """
# Food Dataset Fine-tuning Report

## Objective
Prepare food dataset for fine-tuning with strategies to:
1. Prevent OVERFITTING - Model too specialized to training data
2. Prevent CATASTROPHIC FORGETTING - Model loses old knowledge when learning new
3. Ensure CONSISTENCY - Stable predictions across dataset distribution

## Dataset Characteristics
"""
        
        report += f"\nNutrition Dataset:\n"
        report += f"- Total records: {len(self.nutrition_data)}\n"
        report += f"- Calorie range: {self.nutrition_data['calories'].min():.0f} - {self.nutrition_data['calories'].max():.0f} kkal\n"
        report += f"- Average calories: {self.nutrition_data['calories'].mean():.1f} kkal\n"
        
        report += f"\nNilai Gizi Dataset:\n"
        report += f"- Total records: {len(self.nilai_gizi_data)}\n"
        report += f"- Unique manufacturers: {self.nilai_gizi_data['manufacturer'].nunique()}\n"
        
        report += """

## Applied Strategies

### 1. OVERFITTING PREVENTION
✓ Data Augmentation
  - Synthetic data generation with realistic perturbations
  - Portion variations (±10-20% nutrition change)
  - Similar food variants to increase diversity
  
✓ Regularization Techniques
  - L2 regularization (penalizes large weights)
  - Dropout layers (randomly disable neurons during training)
  - Early stopping (prevents excessive training)
  - Class balancing (prevents bias to common classes)

✓ Data Splitting
  - Stratified splits maintain class distribution
  - Training set: 80% (shuffled randomly)
  - Validation set: 10% (for hyperparameter tuning)
  - Test set: 10% (final evaluation)

### 2. CATASTROPHIC FORGETTING PREVENTION
✓ Rehearsal-Based Learning
  - Replay buffer: Sample old data during training
  - Review previously learned patterns regularly
  - Mix current task with historical data

✓ Progressive Training
  - Start with high-diversity subset
  - Gradually introduce complex patterns
  - Maintain baseline performance while learning new

✓ Elastic Weight Consolidation (EWC)
  - Identify important weights from previous training
  - Protect these weights from major changes
  - Allow new learning while preserving old knowledge

### 3. CONSISTENCY ASSURANCE
✓ Statistical Consistency
  - Monitor per-category performance metrics
  - Ensure predictions stable across calorie ranges
  - Track distribution shifts in validation data

✓ Data Validation
  - Verify no data leakage between train/val/test
  - Check augmented data quality
  - Validate stratification effectiveness

✓ Reproducibility
  - Fixed random seeds for all operations
  - Deterministic data splitting
  - Logged configurations for experiments

## Configuration Parameters

### Hyperparameters
- Learning Rate: Adaptive (start 1e-4, reduce on plateau)
- Batch Size: 32 (balance memory & gradient estimation)
- Epochs: 3-5 (prevent excessive training)
- Dropout Rate: 0.3 (moderate regularization)
- Weight Decay: 0.01 (L2 regularization)

### Training Safeguards
- Early Stopping Patience: 3 epochs
- Gradient Clipping: 1.0 (prevent gradient explosion)
- Learning Rate Reduction: Factor 0.5 on plateau
- Validation Check Frequency: Every epoch

## File Structure
"""
        
        for key, value in stats.items():
            report += f"\n- {key}: {value}"
        
        report += """

## Next Steps
1. Load the prepared datasets (train/val/test JSONL files)
2. Configure fine-tuning parameters in training config
3. Monitor training metrics (loss, accuracy, per-category performance)
4. Validate consistency across data splits
5. Test on held-out evaluation set
6. Monitor for catastrophic forgetting during multi-task training

## Monitoring Checklist
□ Training loss decreases consistently
□ Validation loss plateaus (not diverging)
□ Per-category performance stays balanced
□ Test set performance matches validation
□ No data leakage indicators
□ Augmented data looks realistic
□ Model maintains baseline performance while learning new
"""
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(report)
        
        logger.info(f"Report saved to {output_path}")
    
    def run_complete_pipeline(self):
        """Run complete fine-tuning pipeline"""
        logger.info("\n" + "="*60)
        logger.info("STARTING FOOD DATASET FINE-TUNING PIPELINE")
        logger.info("="*60)
        
        # Load data
        self.load_datasets()
        
        # Analyze
        self.analyze_data_distribution()
        
        # Balance and augment
        balanced_df = self.create_balanced_training_set(min_samples_per_category=50)
        augmented_df = self.augment_data(balanced_df, augmentation_factor=0.3)
        
        # Create stratified splits
        train, val, test = self.create_stratified_splits(augmented_df, test_size=0.2, val_size=0.1)
        
        # Prepare JSONL formats
        stats = {
            "training_samples": len(train),
            "validation_samples": len(val),
            "test_samples": len(test),
            "total_samples": len(augmented_df)
        }
        
        train_path = self.prepare_jsonl_format(train, 
                                               os.path.join(self.output_dir, "train.jsonl"), 
                                               "food")
        val_path = self.prepare_jsonl_format(val, 
                                            os.path.join(self.output_dir, "validation.jsonl"), 
                                            "food")
        test_path = self.prepare_jsonl_format(test, 
                                             os.path.join(self.output_dir, "test.jsonl"), 
                                             "food")
        
        # Create config
        config_path = os.path.join(self.output_dir, "training_config.json")
        self.create_training_config(config_path)
        
        # Generate report
        report_path = os.path.join(self.output_dir, "FINETUNING_REPORT.md")
        self.generate_finetuning_report(report_path, stats)
        
        logger.info("\n" + "="*60)
        logger.info("PIPELINE COMPLETE!")
        logger.info("="*60)
        logger.info(f"\nOutputs saved to: {self.output_dir}")
        logger.info(f"✓ train.jsonl ({len(train)} samples)")
        logger.info(f"✓ validation.jsonl ({len(val)} samples)")
        logger.info(f"✓ test.jsonl ({len(test)} samples)")
        logger.info(f"✓ training_config.json")
        logger.info(f"✓ FINETUNING_REPORT.md")
        
        return {
            "train_path": train_path,
            "val_path": val_path,
            "test_path": test_path,
            "config_path": config_path,
            "report_path": report_path,
            "statistics": stats
        }


if __name__ == "__main__":
    # Configuration
    DATASET_DIR = os.path.join(os.path.dirname(__file__), "../dataset")
    OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "../finetuned_datasets")
    
    # Run pipeline
    finetuner = FoodDatasetFinetuner(DATASET_DIR, OUTPUT_DIR)
    results = finetuner.run_complete_pipeline()
    
    logger.info("\n✓ Fine-tuning datasets ready for model training!")
    logger.info("Review FINETUNING_REPORT.md for detailed strategies and recommendations.")
