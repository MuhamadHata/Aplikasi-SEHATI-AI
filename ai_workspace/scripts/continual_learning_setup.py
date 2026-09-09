"""
Progressive Learning & Anti-Catastrophic Forgetting Script
Purpose: Implement techniques to prevent catastrophic forgetting when fine-tuning models

Techniques:
1. Rehearsal-Based Learning (Replay Buffer)
2. Elastic Weight Consolidation (EWC)
3. Progressive Neural Networks
4. Knowledge Distillation
5. Continual Learning Framework
"""

import os
import json
import pandas as pd
import numpy as np
from typing import List, Dict, Tuple
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class ContinualLearningManager:
    """Manages continual learning to prevent catastrophic forgetting"""
    
    def __init__(self, dataset_dir: str):
        self.dataset_dir = dataset_dir
        self.task_history = []
        self.weight_importance = {}
        
    def create_task_sequences(self, jsonl_path: str, num_tasks: int = 3) -> List[Dict]:
        """
        Create sequential tasks to simulate continual learning
        Each task represents learning different food categories
        """
        logger.info(f"\n=== CREATING TASK SEQUENCES ({num_tasks} tasks) ===")
        
        records = []
        with open(jsonl_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    records.append(json.loads(line))
        
        # Categorize by calorie ranges
        task_groups = {
            'task_0_lowcal': [],      # <200 kkal
            'task_1_mediumcal': [],   # 200-400 kkal  
            'task_2_highcal': [],     # >400 kkal
        }
        
        for record in records:
            output = record['output']
            for line in output.split('\n'):
                if 'Kalori:' in line and 'kkal' in line:
                    try:
                        value = float(line.split(':')[1].split('kkal')[0].strip())
                        if value < 200:
                            task_groups['task_0_lowcal'].append(record)
                        elif value < 400:
                            task_groups['task_1_mediumcal'].append(record)
                        else:
                            task_groups['task_2_highcal'].append(record)
                    except:
                        pass
                    break
        
        tasks = []
        for task_id, (task_name, task_records) in enumerate(task_groups.items()):
            if task_records:
                task = {
                    'task_id': task_id,
                    'task_name': task_name,
                    'num_samples': len(task_records),
                    'description': self._get_task_description(task_name),
                    'data': task_records[:50],  # Limit samples per task
                    'order': task_id
                }
                tasks.append(task)
                logger.info(f"Task {task_id}: {task_name} - {len(task_records)} samples")
        
        return tasks
    
    def _get_task_description(self, task_name: str) -> str:
        """Get human-readable task description"""
        descriptions = {
            'task_0_lowcal': 'Low-calorie foods (< 200 kkal)',
            'task_1_mediumcal': 'Medium-calorie foods (200-400 kkal)',
            'task_2_highcal': 'High-calorie foods (> 400 kkal)'
        }
        return descriptions.get(task_name, task_name)
    
    def create_replay_buffer(self, task_sequences: List[Dict], buffer_size_per_task: int = 20) -> Dict:
        """
        Create replay buffer for rehearsal-based learning
        Stores samples from previous tasks to prevent forgetting
        """
        logger.info(f"\n=== CREATING REPLAY BUFFER ===")
        logger.info(f"Buffer size per task: {buffer_size_per_task}")
        
        replay_buffer = {
            'capacity': buffer_size_per_task * len(task_sequences),
            'per_task_capacity': buffer_size_per_task,
            'tasks': {}
        }
        
        for task in task_sequences:
            task_id = task['task_id']
            task_name = task['task_name']
            
            # Select random samples to store in buffer
            num_samples = min(buffer_size_per_task, len(task['data']))
            buffer_samples = np.random.choice(
                len(task['data']), 
                size=num_samples, 
                replace=False
            )
            
            replay_buffer['tasks'][task_id] = {
                'task_name': task_name,
                'buffer': [task['data'][i] for i in buffer_samples],
                'buffer_size': num_samples
            }
            
            logger.info(f"Task {task_id} ({task_name}): {num_samples} samples in replay buffer")
        
        return replay_buffer
    
    def create_elastic_weight_consolidation_plan(self, task_sequences: List[Dict]) -> Dict:
        """
        Prepare Elastic Weight Consolidation (EWC) strategy
        Identifies important weights that should be protected from change
        """
        logger.info(f"\n=== PREPARING ELASTIC WEIGHT CONSOLIDATION (EWC) ===")
        
        ewc_plan = {
            'description': 'EWC protects important weights from previous tasks',
            'importance_threshold': 0.3,  # Weights with importance > 0.3 are protected
            'lambda_ewc': 0.4,  # Strength of EWC regularization
            'tasks': {}
        }
        
        for task in task_sequences:
            task_id = task['task_id']
            task_name = task['task_name']
            
            # Simulate weight importance scores
            # In practice, these come from Fisher Information Matrix
            weight_importance = {
                'embedding_layer': 0.8,      # Embeddings are important
                'attention_weights': 0.7,    # Attention mechanisms
                'output_layer': 0.5,         # Output layer less important (task-specific)
                'auxiliary_layers': 0.2,    # Auxiliary layers least important
            }
            
            ewc_plan['tasks'][task_id] = {
                'task_name': task_name,
                'weight_importance': weight_importance,
                'protected_layers': [
                    layer for layer, importance in weight_importance.items()
                    if importance > ewc_plan['importance_threshold']
                ],
                'flexible_layers': [
                    layer for layer, importance in weight_importance.items()
                    if importance <= ewc_plan['importance_threshold']
                ]
            }
            
            logger.info(f"Task {task_id}: Protected layers: {ewc_plan['tasks'][task_id]['protected_layers']}")
            logger.info(f"Task {task_id}: Flexible layers: {ewc_plan['tasks'][task_id]['flexible_layers']}")
        
        return ewc_plan
    
    def create_knowledge_distillation_plan(self, task_sequences: List[Dict]) -> Dict:
        """
        Create knowledge distillation strategy to transfer knowledge from old to new tasks
        """
        logger.info(f"\n=== CREATING KNOWLEDGE DISTILLATION PLAN ===")
        
        plan = {
            'description': 'Knowledge distillation transfers old knowledge to new tasks',
            'distillation_temperature': 3.0,  # Higher = softer probability distribution
            'alpha': 0.5,  # Balance between new task loss and distillation loss
            'task_pairs': []
        }
        
        # Create knowledge transfer paths
        for i in range(len(task_sequences) - 1):
            transfer = {
                'from_task': task_sequences[i]['task_id'],
                'from_task_name': task_sequences[i]['task_name'],
                'to_task': task_sequences[i+1]['task_id'],
                'to_task_name': task_sequences[i+1]['task_name'],
                'knowledge_type': [
                    'feature_representations',  # Transfer learned features
                    'attention_patterns',       # Transfer attention mechanisms
                    'conceptual_relationships'  # Transfer category relationships
                ]
            }
            plan['task_pairs'].append(transfer)
            
            logger.info(f"Knowledge path: {transfer['from_task_name']} -> {transfer['to_task_name']}")
        
        return plan
    
    def create_progressive_training_schedule(self, task_sequences: List[Dict]) -> Dict:
        """
        Create progressive training schedule with rehearsal
        """
        logger.info(f"\n=== CREATING PROGRESSIVE TRAINING SCHEDULE ===")
        
        schedule = {
            'strategy': 'Progressive task learning with rehearsal',
            'phases': []
        }
        
        for task_idx, task in enumerate(task_sequences):
            phase = {
                'phase': task_idx + 1,
                'primary_task': {
                    'task_id': task['task_id'],
                    'task_name': task['task_name'],
                    'samples': len(task['data']),
                    'target': f"Learn {task['task_name'].lower()}"
                },
                'rehearsal_tasks': [],
                'training_config': {
                    'epochs': 3 + task_idx,  # Slightly more epochs for complex tasks
                    'batch_size': 32,
                    'learning_rate': 1e-4 * (0.9 ** task_idx),  # Decay learning rate
                    'replay_ratio': min(0.3 * (task_idx + 1), 0.5),  # Increase replay content
                },
                'regularization': {
                    'dropout': 0.3,
                    'l2_lambda': 0.01 + 0.01 * task_idx,  # Increase regularization
                    'ewc_lambda': 0.4 if task_idx > 0 else 0,  # EWC for subsequent tasks
                }
            }
            
            # Add previous tasks to rehearsal
            if task_idx > 0:
                phase['rehearsal_tasks'] = [
                    {
                        'task_id': prev_task['task_id'],
                        'task_name': prev_task['task_name'],
                        'ratio': 1.0 / (task_idx + 1)  # Balanced sampling
                    }
                    for prev_task in task_sequences[:task_idx]
                ]
            
            schedule['phases'].append(phase)
            
            logger.info(f"Phase {task_idx + 1}: {task['task_name']}")
            logger.info(f"  Primary samples: {len(task['data'])}")
            logger.info(f"  Rehearsal tasks: {[t['task_name'] for t in phase['rehearsal_tasks']]}")
        
        return schedule
    
    def create_continual_learning_config(self, output_path: str, 
                                        replay_buffer: Dict,
                                        ewc_plan: Dict,
                                        distillation_plan: Dict,
                                        training_schedule: Dict) -> str:
        """
        Create comprehensive continual learning configuration
        """
        logger.info(f"\n=== CREATING CONTINUAL LEARNING CONFIG ===")
        
        config = {
            'purpose': 'Continual learning framework to prevent catastrophic forgetting',
            'techniques': [
                'Replay-Buffer (Rehearsal)',
                'Elastic Weight Consolidation',
                'Knowledge Distillation',
                'Progressive Learning'
            ],
            'replay_buffer': replay_buffer,
            'elastic_weight_consolidation': ewc_plan,
            'knowledge_distillation': distillation_plan,
            'training_schedule': training_schedule,
            'monitoring': {
                'track_per_task_metrics': True,
                'alert_on_performance_drop': True,
                'performance_drop_threshold': 5,  # Alert if >5% drop
                'forward_transfer': 'Monitor how well new tasks learn from old',
                'backward_transfer': 'Monitor if learning new tasks hurts old performance'
            }
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        
        logger.info(f"Continual learning config saved to {output_path}")
        return output_path
    
    def create_training_guide(self, output_path: str) -> str:
        """Create comprehensive guide for continual learning training"""
        logger.info(f"\n=== CREATING TRAINING GUIDE ===")
        
        guide = """# Continual Learning Training Guide

## Objective
Train food dataset model on sequential tasks without catastrophic forgetting.

## Anti-Catastrophic Forgetting Techniques

### 1. Rehearsal-Based Learning (Replay Buffer)
**How it works:**
- Store representative samples from previous tasks
- Mix previous task samples with current task during training
- Prevents model from forgetting patterns learned in earlier tasks

**Implementation:**
```
For each epoch of task t:
    For each batch in current task:
        main_batch = sample from task_t
        replay_batch = sample from replay_buffer (previous tasks)
        combined_batch = main_batch + replay_batch
        train on combined_batch
```

**Benefits:**
- Simple and computationally efficient
- Empirically effective for many domains
- No modification to model architecture needed

**Drawbacks:**
- Requires storing previous data (memory overhead)
- May not scale well with many tasks

### 2. Elastic Weight Consolidation (EWC)
**How it works:**
- Identify important weights for each task (via Fisher Information Matrix)
- Protect important weights from older tasks when learning new tasks
- Add regularization term to loss: λ * Σ(F_i * (w_i - w_i*)²)

**Implementation:**
```
After training task t:
    1. Compute Fisher Information Matrix F_t
    2. Store old weights w_t* and importance F_t
    
When training task t+1:
    loss = main_loss + λ * Σ(F_t * (w - w_t*)²)
```

**Benefits:**
- Protects learned knowledge mathematically
- Parameter-efficient
- Works well with pre-trained models

**Drawbacks:**
- Requires Fisher Information computation (expensive)
- Can constrain learning of new tasks too much if λ too high

### 3. Knowledge Distillation
**How it works:**
- Train student model on new task with guidance from teacher model trained on old tasks
- Transfer learned representations and attention patterns
- Use soft targets (T=3.0) for smoother probability distributions

**Implementation:**
```
loss = α * L_new_task + (1-α) * KL_divergence(teacher_out, student_out)
```

**Benefits:**
- Natural way to transfer knowledge
- Student can be smaller/faster
- Flexible knowledge transfer

**Drawbacks:**
- Requires maintaining old model
- Additional computational cost during training

### 4. Progressive Neural Networks
**How it works:**
- Old layers frozen, new layers added for new tasks
- Lateral connections allow new layers to access old representations
- Preserves old knowledge while learning new tasks

**Architecture:**
```
Task 1: [Layer1] -> [Layer2] -> [Output1]
Task 2: [Layer1] -> [Layer2] + [NewLayer2] -> [Output2]
                      ↗ (lateral connection)
Task 3: [Layer1] -> [Layer2] + [NewLayer2] + [NewLayer3] -> [Output3]
```

**Benefits:**
- Guarantees no catastrophic forgetting
- Efficient use of learned features
- Can handle unlimited tasks

**Drawbacks:**
- Model size grows with tasks
- May be overkill for few tasks

## Recommended Training Procedure

### Phase 1: Low-Calorie Foods Learning
- **Main Task**: Learn patterns of low-calorie foods
- **Data**: Low-calorie subset
- **Epochs**: 3
- **No Rehearsal**: First task
- **Regularization**: Standard (L2=0.01, Dropout=0.3)

### Phase 2: Medium-Calorie Foods Learning
- **Main Task**: Learn patterns of medium-calorie foods
- **Data**: Medium-calorie subset
- **Epochs**: 4
- **Rehearsal**: 30% data from Phase 1
- **Regularization**: Enhanced (L2=0.02, Dropout=0.3, EWC=0.4)

### Phase 3: High-Calorie Foods Learning
- **Main Task**: Learn patterns of high-calorie foods
- **Data**: High-calorie subset
- **Epochs**: 5
- **Rehearsal**: 50% data from Phases 1-2
- **Regularization**: Maximum (L2=0.03, Dropout=0.3, EWC=0.4)

## Monitoring During Training

### Metrics to Track
1. **Task Performance**
   - Accuracy on current task
   - Loss on current task
   - Metrics per category within task

2. **Backward Transfer**
   - Evaluate on Phase 1 data after Phase 2
   - Evaluate on Phase 1-2 data after Phase 3
   - Alert if >5% performance drop

3. **Forward Transfer**
   - Does Phase 1 learning help Phase 2?
   - Does Phase 1-2 learning help Phase 3?
   - Positive values indicate good transfer

4. **Replay Buffer Effectiveness**
   - Loss on replay buffer samples
   - Accuracy on replayed old tasks
   - Should remain stable

## Red Flags & Solutions

| Problem | Indicator | Solution |
|---------|-----------|----------|
| Catastrophic Forgetting | 10%+ drop on old tasks | Increase replay ratio, increase EWC lambda |
| Slow New Task Learning | New task loss not decreasing | Decrease EWC lambda, reduce L2 regularization |
| Overfitting on New Task | High train acc, low val acc | Increase dropout, increase data augmentation |
| Memory Issues | OOM errors | Reduce replay buffer size, reduce batch size |
| Diverging Loss | Loss becomes NaN/Inf | Lower learning rate, enable gradient clipping |

## Validation Strategy

### Cross-Task Validation
- After each phase, validate on all previous tasks
- Ensure consistent performance across all task groups

### Stratified Evaluation
- Evaluate per calorie category
- Ensure model works well across different food types

### Robustness Testing
- Test on out-of-distribution samples
- Test on edge cases (extreme calories, unusual distributions)

## Expected Results

### Without Anti-Catastrophic Forgetting
- Phase 1 accuracy: 85%
- Phase 2 accuracy: 82%
- Phase 1 accuracy after Phase 2: 45% (FORGETTING!)
- Phase 3 accuracy: 80%
- Phase 1 accuracy after Phase 3: 25% (SEVERE FORGETTING!)

### With Anti-Catastrophic Forgetting Techniques
- Phase 1 accuracy: 85%
- Phase 2 accuracy: 82%
- Phase 1 accuracy after Phase 2: 80% (maintained!)
- Phase 3 accuracy: 81%
- Phase 1 accuracy after Phase 3: 78% (preserved!)

## Quick Reference

### Key Hyperparameters
- **Replay Ratio**: Start 30%, increase to 50%
- **EWC Lambda**: 0.4 (balance between old and new)
- **Learning Rate**: 1e-4, decay by 0.9x per phase
- **L2 Regularization**: 0.01 → 0.03 (increase gradually)
- **Dropout**: 0.3 (constant)

### Debug Checklist
- [ ] Data leakage checked (no overlap in tasks)
- [ ] Replay buffer samples verified
- [ ] Fisher Information computed correctly
- [ ] Loss functions properly combined
- [ ] Validation on all tasks after each phase
- [ ] Random seeds fixed for reproducibility
"""
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(guide)
        
        logger.info(f"Training guide saved to {output_path}")
        return output_path
    
    def run_complete_setup(self, dataset_dir: str, output_dir: str):
        """Run complete continual learning setup"""
        logger.info("\n" + "="*70)
        logger.info("SETTING UP CONTINUAL LEARNING FRAMEWORK")
        logger.info("="*70)
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Create task sequences
        tasks = self.create_task_sequences(
            os.path.join(dataset_dir, 'train.jsonl'),
            num_tasks=3
        )
        
        # Create replay buffer
        replay_buffer = self.create_replay_buffer(tasks, buffer_size_per_task=20)
        
        # Create EWC plan
        ewc_plan = self.create_elastic_weight_consolidation_plan(tasks)
        
        # Create distillation plan
        distillation_plan = self.create_knowledge_distillation_plan(tasks)
        
        # Create training schedule
        training_schedule = self.create_progressive_training_schedule(tasks)
        
        # Create configuration
        config_path = self.create_continual_learning_config(
            os.path.join(output_dir, 'continual_learning_config.json'),
            replay_buffer, ewc_plan, distillation_plan, training_schedule
        )
        
        # Create guide
        guide_path = self.create_training_guide(
            os.path.join(output_dir, 'CONTINUAL_LEARNING_GUIDE.md')
        )
        
        logger.info("\n" + "="*70)
        logger.info("CONTINUAL LEARNING SETUP COMPLETE!")
        logger.info("="*70)
        logger.info(f"\nOutputs saved to: {output_dir}")
        logger.info(f"✓ continual_learning_config.json")
        logger.info(f"✓ CONTINUAL_LEARNING_GUIDE.md")
        
        return {
            'config_path': config_path,
            'guide_path': guide_path,
            'tasks': tasks
        }


if __name__ == "__main__":
    DATASET_DIR = os.path.join(os.path.dirname(__file__), "../finetuned_datasets")
    OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "../continual_learning")
    
    manager = ContinualLearningManager(DATASET_DIR)
    results = manager.run_complete_setup(DATASET_DIR, OUTPUT_DIR)
    
    logger.info("\n✓ Continual learning framework ready!")
    logger.info("Review CONTINUAL_LEARNING_GUIDE.md for training instructions.")
