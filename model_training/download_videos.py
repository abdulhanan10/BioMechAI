import subprocess
import os
import glob
import sys

# 10 YouTube search queries per exercise
# yt-dlp will download 15 videos for each query
# This totals 150 videos per exercise, resulting in 1050 videos total across 7 exercises

EXERCISES = {
    'squat': [
        'ytsearch1:squat exercise tutorial proper form',
        'ytsearch1:how to do squats correctly beginner',
        'ytsearch1:squat workout technique slow motion',
        'ytsearch1:bodyweight squat form guide',
        'ytsearch1:squat exercise side view full body',
        'ytsearch1:perfect squat form demonstration',
        'ytsearch1:squat reps workout home exercise',
        'ytsearch1:squat exercise front view tutorial',
        'ytsearch1:deep squat proper technique',
        'ytsearch1:squat exercise slow motion side angle',
    ],
    'pushup': [
        'ytsearch1:push up exercise proper form tutorial',
        'ytsearch1:how to do push ups correctly beginner',
        'ytsearch1:push up workout slow motion side view',
        'ytsearch1:perfect push up form demonstration',
        'ytsearch1:push up technique full body visible',
        'ytsearch1:push up reps workout home',
        'ytsearch1:pushup exercise side angle view',
        'ytsearch1:push up form guide slow motion',
        'ytsearch1:standard push up tutorial',
        'ytsearch1:push up exercise full range motion',
    ],
    'jumping_jack': [
        'ytsearch1:jumping jacks exercise tutorial',
        'ytsearch1:jumping jacks proper form beginner',
        'ytsearch1:jumping jacks workout slow motion',
        'ytsearch1:how to do jumping jacks correctly',
        'ytsearch1:jumping jacks full body exercise',
        'ytsearch1:jumping jack cardio exercise tutorial',
        'ytsearch1:jumping jacks workout reps',
        'ytsearch1:jumping jacks form guide',
        'ytsearch1:jumping jacks home workout',
        'ytsearch1:jumping jack exercise demonstration',
    ],
    'bicep_curl': [
        'ytsearch1:bicep curl exercise proper form',
        'ytsearch1:how to do bicep curls correctly',
        'ytsearch1:bicep curl slow motion side view',
        'ytsearch1:dumbbell curl technique tutorial',
        'ytsearch1:bicep curl workout beginner guide',
        'ytsearch1:arm curl exercise form demonstration',
        'ytsearch1:bicep curl full range motion',
        'ytsearch1:bicep curl workout reps',
        'ytsearch1:proper bicep curl technique',
        'ytsearch1:bicep curl exercise side angle',
    ],
    'lunge': [
        'ytsearch1:lunge exercise proper form tutorial',
        'ytsearch1:how to do lunges correctly beginner',
        'ytsearch1:forward lunge slow motion side view',
        'ytsearch1:lunge workout technique guide',
        'ytsearch1:perfect lunge form demonstration',
        'ytsearch1:lunge exercise full body visible',
        'ytsearch1:lunge reps workout home',
        'ytsearch1:lunge form side angle view',
        'ytsearch1:bodyweight lunge exercise tutorial',
        'ytsearch1:lunge exercise slow motion',
    ],
    'plank': [
        'ytsearch1:plank exercise proper form tutorial',
        'ytsearch1:how to do plank correctly beginner',
        'ytsearch1:plank hold exercise side view',
        'ytsearch1:perfect plank form demonstration',
        'ytsearch1:plank exercise full body visible',
        'ytsearch1:plank workout core exercise',
        'ytsearch1:plank position guide',
        'ytsearch1:plank exercise form mistakes',
        'ytsearch1:forearm plank tutorial',
        'ytsearch1:plank exercise side angle',
    ],
    'high_knees': [
        'ytsearch1:high knees exercise proper form',
        'ytsearch1:how to do high knees correctly',
        'ytsearch1:high knees workout slow motion',
        'ytsearch1:high knees cardio exercise tutorial',
        'ytsearch1:high knees running in place form',
        'ytsearch1:high knees exercise full body',
        'ytsearch1:high knees workout home cardio',
        'ytsearch1:high knees form guide',
        'ytsearch1:high knees exercise demonstration',
        'ytsearch1:high knees cardio workout reps',
    ],
}

OUTPUT_DIR = 'data/raw_videos'

# Ensure directories exist
for exercise in EXERCISES.keys():
    os.makedirs(os.path.join(OUTPUT_DIR, exercise), exist_ok=True)
    os.makedirs(os.path.join('data', 'landmarks', exercise), exist_ok=True)
os.makedirs('models', exist_ok=True)

for exercise, queries in EXERCISES.items():
    print(f'\nDownloading videos for: {exercise}')
    exercise_dir = os.path.join(OUTPUT_DIR, exercise)

    for i, query in enumerate(queries):
        output_template = os.path.join(
            exercise_dir, f'{exercise}_{i+1:02d}_%(autonumber)02d.mp4')

        existing_files = glob.glob(os.path.join(exercise_dir, f'{exercise}_{i+1:02d}_*.mp4'))
        if len(existing_files) >= 5: # If we have at least some, skip
            print(f'  Already exists (found {len(existing_files)} files)')
            continue

        query_15 = query.replace('ytsearch1:', 'ytsearch15:')
        print(f'  Downloading video set {i+1}/10 (15 videos each)...')
        cmd = [
            sys.executable, '-m', 'yt_dlp',
            query_15,
            '--format', 'mp4[height<=480]/best[height<=480]/best',
            '--output', output_template,
            '--no-playlist',
            '--quiet',
            '--max-filesize', '50m',
        ]
        try:
            subprocess.run(cmd, timeout=600, check=True)
            print(f'  Downloaded set {i+1}')
        except Exception as e:
            print(f'  Failed: {e}')

print('\nAll downloads complete!')
