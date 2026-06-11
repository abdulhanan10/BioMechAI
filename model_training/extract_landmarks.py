import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import numpy as np
import os
import json
from tqdm import tqdm

EXERCISES = [
    'squat', 'pushup', 'jumping_jack',
    'bicep_curl', 'lunge', 'plank', 'high_knees'
]

FRAMES_PER_CLIP = 90  # 3 seconds at 30 FPS
CLIPS_PER_VIDEO = 5   # extract 5 clips from each video

def extract_landmarks_from_video(video_path):
    cap = cv2.VideoCapture(video_path)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30

    all_frames_landmarks = []

    base_options = python.BaseOptions(model_asset_path='pose_landmarker_lite.task')
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        output_segmentation_masks=False,
        running_mode=vision.RunningMode.VIDEO
    )

    frame_index = 0
    with vision.PoseLandmarker.create_from_options(options) as landmarker:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            
            timestamp_ms = int((frame_index * 1000) / fps)
            result = landmarker.detect_for_video(mp_image, timestamp_ms)

            if result.pose_landmarks and len(result.pose_landmarks) > 0:
                landmarks = []
                for lm in result.pose_landmarks[0]:
                    landmarks.append([lm.x, lm.y, lm.z])
                all_frames_landmarks.append(landmarks)
            else:
                # No person detected - skip frame
                if all_frames_landmarks:
                    all_frames_landmarks.append(all_frames_landmarks[-1])  # repeat last

            frame_index += 1

    cap.release()
    return all_frames_landmarks  # shape: (total_frames, 33, 3)

def create_clips(all_landmarks, clips_count=5):
    clips = []
    total = len(all_landmarks)

    if total < FRAMES_PER_CLIP:
        return clips

    # Extract clips evenly distributed across video
    step = (total - FRAMES_PER_CLIP) // clips_count

    for i in range(clips_count):
        start = i * step
        end = start + FRAMES_PER_CLIP
        if end <= total:
            clip = all_landmarks[start:end]
            clips.append(clip)

    return clips

# Process all exercises
for exercise in EXERCISES:
    video_dir = f'data/raw_videos/{exercise}'
    landmark_dir = f'data/landmarks/{exercise}'

    if not os.path.exists(video_dir):
        print(f'No videos folder for {exercise}')
        continue

    videos = [f for f in os.listdir(video_dir)
              if f.endswith('.mp4')]
    print(f'\nProcessing {exercise}: {len(videos)} videos')

    clip_count = 0

    for video_file in tqdm(videos):
        video_path = os.path.join(video_dir, video_file)

        try:
            all_landmarks = extract_landmarks_from_video(video_path)
            clips = create_clips(all_landmarks, CLIPS_PER_VIDEO)

            for j, clip in enumerate(clips):
                clip_name = f'{video_file[:-4]}_clip{j:02d}.json'
                clip_path = os.path.join(landmark_dir, clip_name)

                with open(clip_path, 'w') as f:
                    json.dump({
                        'exercise': exercise,
                        'landmarks': clip,
                        'frames': len(clip)
                    }, f)

                clip_count += 1

        except Exception as e:
            print(f'  Error processing {video_file}: {e}')

    print(f'  Created {clip_count} clips for {exercise}')

print('\nLandmark extraction complete!')
