import numpy as np
from sklearn.ensemble import RandomForestClassifier

X_train, y_train = [], []
np.random.seed(42)
for _ in range(150):
    for class_idx in range(7):
        base_features = np.zeros(21)
        if class_idx == 0:
            base_features[12:15] = 0.5
            base_features[18:21] = 0.6
        elif class_idx == 1:
            base_features[15:18] = 0.7
        elif class_idx == 2:
            base_features[0:6] = 0.8
            base_features[6:12] = 0.8
        elif class_idx == 3:
            base_features[6:12] = 0.5
            base_features[18:21] = 0.7
        elif class_idx == 4:
            base_features[0:6] = 0.6
            base_features[15:18] = 0.2
        elif class_idx == 5:
            base_features[6:12] = 0.9
            base_features[18:21] = 0.9
        
        sample = np.random.normal(base_features, 0.1)
        sample = np.abs(sample)
        X_train.append(sample)
        y_train.append(class_idx)
        
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Simulate real squat (massive variance compared to 0.5)
real_squat = np.zeros(21)
real_squat[12:15] = 3.0
real_squat[18:21] = 4.0

probs = model.predict_proba([real_squat])[0]
print("Real Squat Probs:", probs)
print("Top Class:", np.argmax(probs))

real_jj = np.zeros(21)
real_jj[0:6] = 5.0
real_jj[6:12] = 4.0
probs = model.predict_proba([real_jj])[0]
print("Real JJ Probs:", probs)
print("Top Class:", np.argmax(probs))
