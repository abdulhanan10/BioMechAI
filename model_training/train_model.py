import numpy as np
import json
import os
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import joblib

EXERCISES = [
    'squat', 'pushup', 'jumping_jack',
    'bicep_curl', 'lunge', 'plank', 'high_knees'
]

EXERCISE_LABELS = {
    'squat':        'Squat',
    'pushup':       'Push-Up',
    'jumping_jack': 'Jumping Jack',
    'bicep_curl':   'Bicep Curl',
    'lunge':        'Lunge',
    'plank':        'Plank',
    'high_knees':   'High Knees',
}


def extract_features(landmarks):
    """
    Extract 50 biomechanical features from 90-frame clip.
    landmarks shape: (90, 33, 3)
    """
    lm = np.array(landmarks)  # (90, 33, 3)
    features = []

    # Key joint indices
    joints = {
        'l_shoulder': 11, 'r_shoulder': 12,
        'l_elbow':    13, 'r_elbow':    14,
        'l_wrist':    15, 'r_wrist':    16,
        'l_hip':      23, 'r_hip':      24,
        'l_knee':     25, 'r_knee':     26,
        'l_ankle':    27, 'r_ankle':    28,
    }

    def angle(a, b, c):
        """Angle at b in triangle a-b-c over all frames."""
        ba = lm[:, a, :2] - lm[:, b, :2]
        bc = lm[:, c, :2] - lm[:, b, :2]
        cos = np.sum(ba*bc, axis=1) / (
            np.linalg.norm(ba, axis=1) *
            np.linalg.norm(bc, axis=1) + 1e-9)
        return np.degrees(np.arccos(np.clip(cos, -1, 1)))

    # 8 joint angle sequences over time
    angle_seqs = {
        'knee_l':     angle(23, 25, 27),
        'knee_r':     angle(24, 26, 28),
        'elbow_l':    angle(11, 13, 15),
        'elbow_r':    angle(12, 14, 16),
        'hip_l':      angle(11, 23, 25),
        'hip_r':      angle(12, 24, 26),
        'shoulder_l': angle(13, 11, 23),
        'shoulder_r': angle(14, 12, 24),
    }

    # For each angle: mean, std, min, max, range
    for name, seq in angle_seqs.items():
        features.extend([
            np.mean(seq),
            np.std(seq),
            np.min(seq),
            np.max(seq),
            np.max(seq) - np.min(seq),  # range of motion
        ])
    # 40 features so far

    # Velocity features (rate of change)
    for name, seq in angle_seqs.items():
        velocity = np.diff(seq)
        features.append(np.mean(np.abs(velocity)))  # avg speed
    # 48 features

    # Symmetry feature
    knee_sym = np.mean(np.abs(
        angle_seqs['knee_l'] - angle_seqs['knee_r']))
    shoulder_sym = np.mean(np.abs(
        angle_seqs['shoulder_l'] - angle_seqs['shoulder_r']))
    features.append(knee_sym)
    features.append(shoulder_sym)
    # 50 features total

    return np.array(features)


# Load all data
X = []
y = []

print('Loading landmark data...')
for exercise in EXERCISES:
    landmark_dir = f'data/landmarks/{exercise}'
    if not os.path.exists(landmark_dir):
        print(f'  No data for {exercise}')
        continue

    files = [f for f in os.listdir(landmark_dir)
             if f.endswith('.json')]
    print(f'  {exercise}: {len(files)} clips')

    for fname in files:
        fpath = os.path.join(landmark_dir, fname)
        try:
            with open(fpath) as f:
                data = json.load(f)
            features = extract_features(data['landmarks'])
            X.append(features)
            y.append(exercise)
        except Exception as e:
            print(f'  Error: {fname}: {e}')

X = np.array(X)
y = np.array(y)

print(f'\nTotal samples: {len(X)}')
print(f'Features per sample: {X.shape[1]}')
print(f'Class distribution:')
for ex in EXERCISES:
    count = np.sum(y == ex)
    print(f'  {ex}: {count}')

# Encode labels
le = LabelEncoder()
y_enc = le.fit_transform(y)

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Train test split
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y_enc,
    test_size=0.2,
    random_state=42,
    stratify=y_enc
)

print('\nTraining Random Forest model...')
model = RandomForestClassifier(
    n_estimators=200,
    max_depth=15,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1
)
model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
accuracy = np.mean(y_pred == y_test)
print(f'\nTest Accuracy: {accuracy*100:.1f}%')
print('\nClassification Report:')
print(classification_report(
    y_test, y_pred,
    target_names=le.classes_))

# Cross validation
cv_scores = cross_val_score(model, X_scaled, y_enc, cv=5)
print(f'Cross-validation: {cv_scores.mean()*100:.1f}% '
      f'(+/- {cv_scores.std()*100:.1f}%)')

# Save model
os.makedirs('models', exist_ok=True)
joblib.dump(model,  'models/exercise_classifier.pkl')
joblib.dump(scaler, 'models/scaler.pkl')
joblib.dump(le,     'models/label_encoder.pkl')
print('\nModel saved to models/')

# Confusion matrix plot
cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(10, 8))
plt.imshow(cm, cmap='Blues')
plt.title('Confusion Matrix — BioMechAI Exercise Classifier')
plt.colorbar()
ticks = range(len(le.classes_))
plt.xticks(ticks, le.classes_, rotation=45)
plt.yticks(ticks, le.classes_)
for i in range(len(le.classes_)):
    for j in range(len(le.classes_)):
        plt.text(j, i, str(cm[i, j]),
                 ha='center', va='center',
                 color='white' if cm[i, j] > cm.max()/2
                 else 'black')
plt.tight_layout()
plt.savefig('models/confusion_matrix.png', dpi=150)
print('Confusion matrix saved.')
