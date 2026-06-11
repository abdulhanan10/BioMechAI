from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import joblib
import os

app = Flask(__name__)
CORS(app)

# Load trained model
MODEL_PATH  = 'models/fitness_model.pkl'

model = None

def load_model():
    global model
    try:
        model = joblib.load(MODEL_PATH)
        print('Custom fitness model loaded successfully')
    except Exception as e:
        print(f'Model load failed: {e}')

def extract_features(landmarks):
    """Extracts 21 features to match the synthetic 1050-video model."""
    lm = np.array(landmarks)  # (90, 33, 3)
    
    # Scale coordinates to increase std dev to match synthetic 0.0-1.0 range
    lm = lm * 5.0
    
    # wrists: left(15), right(16) -> 6 coords
    wrists_std = np.std(lm[:, [15, 16], :], axis=0).flatten()
    # ankles: left(27), right(28) -> 6 coords
    ankles_std = np.std(lm[:, [27, 28], :], axis=0).flatten()
    # hips: left(23) -> 3 coords
    hips_std = np.std(lm[:, 23, :], axis=0).flatten()
    # elbows: left(13) -> 3 coords
    elbows_std = np.std(lm[:, 13, :], axis=0).flatten()
    # knees: left(25) -> 3 coords
    knees_std = np.std(lm[:, 25, :], axis=0).flatten()
    
    features = np.concatenate([wrists_std, ankles_std, hips_std, elbows_std, knees_std])
    return np.array(features).reshape(1, -1)

EXERCISE_DISPLAY_NAMES = {
    0: 'Squat',
    1: 'Push-Up',
    2: 'Jumping Jack',
    3: 'Lunge',
    4: 'Bicep Curl',
    5: 'High Knees',
    6: 'Plank'
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
        probs = model.predict_proba(features)[0]
        top_idx = int(np.argmax(probs))
        confidence = float(probs[top_idx])

        top3 = sorted(
            [{'exercise': EXERCISE_DISPLAY_NAMES[i], 'confidence': float(probs[i])}
             for i in range(7)],
            key=lambda x: -x['confidence']
        )[:3]

        return jsonify({
            'exercise':   EXERCISE_DISPLAY_NAMES[top_idx],
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
        'exercises': list(EXERCISE_DISPLAY_NAMES.values())
    })


if __name__ == '__main__':
    load_model()
    print('Starting BioMechAI server on port 5000...')
    print('Find your IP with: ipconfig')
    app.run(host='0.0.0.0', port=5000, debug=False)
