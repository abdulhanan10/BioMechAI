from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import joblib
import os

app = Flask(__name__)
CORS(app)

# Load trained model
MODEL_PATH  = 'models/exercise_classifier.pkl'
SCALER_PATH = 'models/scaler.pkl'
ENCODER_PATH= 'models/label_encoder.pkl'

model, scaler, le = None, None, None

def load_model():
    global model, scaler, le
    try:
        model  = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
        le     = joblib.load(ENCODER_PATH)
        print('Model loaded successfully')
        print(f'Exercises: {list(le.classes_)}')
    except Exception as e:
        print(f'Model load failed: {e}')

def extract_features(landmarks):
    """Same feature extraction as training."""
    lm = np.array(landmarks)  # (90, 33, 3)

    def angle(a, b, c):
        ba = lm[:, a, :2] - lm[:, b, :2]
        bc = lm[:, c, :2] - lm[:, b, :2]
        cos = np.sum(ba*bc, axis=1) / (
            np.linalg.norm(ba, axis=1) *
            np.linalg.norm(bc, axis=1) + 1e-9)
        return np.degrees(np.arccos(np.clip(cos, -1, 1)))

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

    features = []
    for seq in angle_seqs.values():
        features.extend([
            np.mean(seq), np.std(seq),
            np.min(seq),  np.max(seq),
            np.max(seq) - np.min(seq),
        ])
    for seq in angle_seqs.values():
        features.append(np.mean(np.abs(np.diff(seq))))

    knee_sym = np.mean(np.abs(
        angle_seqs['knee_l'] - angle_seqs['knee_r']))
    shoulder_sym = np.mean(np.abs(
        angle_seqs['shoulder_l'] - angle_seqs['shoulder_r']))
    features.extend([knee_sym, shoulder_sym])

    return np.array(features).reshape(1, -1)


EXERCISE_DISPLAY_NAMES = {
    'squat':        'Squat',
    'pushup':       'Push-Up',
    'jumping_jack': 'Jumping Jack',
    'bicep_curl':   'Bicep Curl',
    'lunge':        'Lunge',
    'plank':        'Plank',
    'high_knees':   'High Knees',
}


@app.route('/classify', methods=['POST'])
def classify():
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500

    data = request.json
    if not data or 'landmarks' not in data:
        return jsonify({'error': 'No landmarks provided'}), 400

    landmarks = data['landmarks']

    # Pad or trim to exactly 90 frames
    if len(landmarks) < 90:
        last = landmarks[-1] if landmarks else [[0,0,0]]*33
        while len(landmarks) < 90:
            landmarks.append(last)
    landmarks = landmarks[:90]

    try:
        features = extract_features(landmarks)
        features_scaled = scaler.transform(features)
        probs = model.predict_proba(features_scaled)[0]
        top_idx = int(np.argmax(probs))
        top_label = le.classes_[top_idx]
        confidence = float(probs[top_idx])

        top3 = sorted(
            [{'exercise': EXERCISE_DISPLAY_NAMES.get(
                  le.classes_[i], le.classes_[i]),
              'confidence': float(probs[i])}
             for i in range(len(le.classes_))],
            key=lambda x: -x['confidence']
        )[:3]

        return jsonify({
            'exercise':   EXERCISE_DISPLAY_NAMES.get(
                              top_label, top_label),
            'confidence': confidence,
            'top3':       top3
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status':  'ok',
        'model':   'BioMechAI Custom Classifier',
        'loaded':  model is not None,
        'exercises': list(le.classes_) if le else []
    })


if __name__ == '__main__':
    load_model()
    print('Starting BioMechAI server on port 5000...')
    print('Find your IP with: ipconfig')
    app.run(host='0.0.0.0', port=5000, debug=False)
