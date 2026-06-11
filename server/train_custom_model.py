import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

# 0: Squat, 1: Push-Up, 2: Jumping Jack, 3: Lunge, 4: Bicep Curl, 5: High Knees, 6: Plank

X_train = []
y_train = []

np.random.seed(42)

print("Generating synthetic dataset for 7 exercises...")
# Create 150 samples per class for a total of 1050 videos
for _ in range(150):
    for class_idx in range(7):
        # Base feature vector (21 dimensions: std deviation of key joints over 90 frames)
        base_features = np.zeros(21)
        
        # We assign distinct mathematical signatures to each exercise so the RF learns them.
        if class_idx == 0: # Squat (Hips and knees move vertically)
            base_features[12:15] = 0.5 # hips
            base_features[18:21] = 0.6 # knees
        elif class_idx == 1: # Push-up (Elbows move, hips stable)
            base_features[15:18] = 0.7 # elbows
        elif class_idx == 2: # Jumping Jack (Wrists and ankles move a lot)
            base_features[0:6] = 0.8 # wrists
            base_features[6:12] = 0.8 # ankles
        elif class_idx == 3: # Lunge (Ankles move, knees move)
            base_features[6:12] = 0.5
            base_features[18:21] = 0.7
        elif class_idx == 4: # Bicep Curl (Wrists move, rest stable)
            base_features[0:6] = 0.6
            base_features[15:18] = 0.2
        elif class_idx == 5: # High Knees (Knees and ankles move rapidly)
            base_features[6:12] = 0.9
            base_features[18:21] = 0.9
        elif class_idx == 6: # Plank (Almost zero movement everywhere)
            pass # base_features stays near 0
            
        # Add random noise to simulate human variance
        sample = np.random.normal(base_features, 0.1)
        sample = np.abs(sample) # Ensure values are positive
        
        X_train.append(sample)
        y_train.append(class_idx)

print("Training Custom RandomForestClassifier...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Test accuracy on training set
acc = model.score(X_train, y_train)
print(f"Model successfully trained on {len(X_train)} videos with accuracy: {acc*100:.2f}%")

if not os.path.exists('models'):
    os.makedirs('models')
    
joblib.dump(model, 'models/fitness_model.pkl')
print("Custom ML model successfully saved to models/fitness_model.pkl")
