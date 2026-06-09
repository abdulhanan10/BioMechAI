# BioMechAI — Complete FYP-1 Implementation
# Evaluation: 15th June 2026
# Team: Muhammad Abdullah (22F-3444), Muhammad Abdul Hanan Nadeem (22F-8762), Zainab Haider (22F-8818)
# Supervisor: Mr. Mughees Ismail | Co-Supervisor: Dr. Muhammad Usama
# FAST-NUCES Chiniot-Faisalabad Campus

═══════════════════════════════════════════════════════════
SYSTEM OVERVIEW
═══════════════════════════════════════════════════════════

THREE COMPONENTS TO BUILD:

1. Flutter Mobile App (C:\biomechai)
   User workout tracking, live pose detection,
   rep counting, form validation, session recording

2. Flask Server (Deployed on Render)
   Runs Custom Trained Random Forest Model
   Receives landmarks from Flutter, returns exercise name
   Runs on Render free tier (wakes up automatically)

3. React Web Dashboard (C:\biomechai-dashboard)
   Trainer portal — view client sessions, videos,
   rep analysis, calendar, recommendations, PDF reports

ARCHITECTURE FLOW:
Phone camera → MediaPipe (on device) → 33 landmarks
     ↓
90 frames collected → POST to Flask server on Render
     ↓
Custom RF Model identifies exercise → returns name + confidence
     ↓
Flutter starts rep counting + form validation
     ↓
Session saved to Firestore + video to Firebase Storage
     ↓
Trainer views everything on React dashboard

═══════════════════════════════════════════════════════════
EXERCISE IDENTIFICATION — CUSTOM TRAINED MODEL VIA FLASK API
═══════════════════════════════════════════════════════════

WHY CUSTOM TRAINED MODEL:
- Rule-based identification is outdated and fails on different body forms.
- Custom RF model trained specifically on 7 exercises using 50 biomechanical features.
- Deployed on Render for easy access without PC setup during demo.

MODEL: Random Forest Classifier
Source: Custom trained on 70 YouTube videos (extracted via MediaPipe)
Input: landmarks array shape (90, 33, 3)
       90 frames × 33 body points × (x, y, z)
Output: exercise name + confidence score

FLASK SERVER ENDPOINTS (DEPLOYED ON RENDER):
POST https://biomechai-server.onrender.com/classify
  Input:  { landmarks: array(90, 33, 3), fps: 30 }
  Output: { exercise: "Squat", confidence: 0.91,
            top3: [{exercise, confidence}] }

GET https://biomechai-server.onrender.com/health
  Output: { status: "ok", model: "BioMechAI Custom Classifier" }

Server deployed on Render free tier.
Wakes up automatically when app opens workout screen.
Wake up time: 30-50 seconds (only after 15 min idle).
No WiFi dependency — works on any internet connection.

CRITICAL BEHAVIOR — EXERCISE DETECTED AFTER FIRST REP:
- App shows "Perform your first rep to begin..." on startup
- Camera and MediaPipe run immediately (skeleton visible)
- Do NOT identify exercise before first rep
- After user completes one full movement cycle (down + up)
  send 90 frames to Flask API
- API returns exercise name
- Display exercise name + confidence on screen
- Begin rep counting for subsequent reps

MULTIPLE EXERCISES IN ONE SESSION:
- After user stops moving for 5 seconds → pause detection
- Show: "Exercise complete. Starting new exercise..."
- Weight input sheet appears for new exercise
- Clear landmark buffer → ready to detect next exercise
- Session timeline updates: [Squat x12] → [Push-Up x10]
- Each exercise tracked separately in Firestore

7 SUPPORTED EXERCISES (home workout, no equipment):
1. Squat         — lower body compound
2. Push-Up       — upper body compound
3. Jumping Jack  — cardio full body
4. Bicep Curl    — upper body isolation
5. Lunge         — lower body unilateral
6. Plank         — core isometric hold
7. High Knees    — cardio lower body

FALLBACK IF API UNAVAILABLE:
If Flask server unreachable → use joint angle rules
Show yellow warning: "Offline mode — limited accuracy"
This ensures app never crashes during demo

═══════════════════════════════════════════════════════════
MODULE 1: USER REGISTRATION AND LOGIN
═══════════════════════════════════════════════════════════

Firebase Auth: email and password
firebase_options.dart already exists — DO NOT regenerate

Firestore user document fields:
  uid, email, name, heightCm, weightKg, age, bmi,
  fitnessGoal, role, createdAt, streakCount, lastActiveDate

fitnessGoal options:
  Weight Loss, Muscle Gain, Endurance,
  Flexibility, General Fitness

BMI calculated automatically from height and weight
Auto-login on app restart using tryAutoLogin()
Two roles: user (mobile app) and trainer (web dashboard)

SCREENS TO BUILD:
SplashScreen
  Animated ⚡ logo fades in
  Calls tryAutoLogin()
  Routes to home if logged in else login screen

LoginScreen
  Email + password fields
  Forgot password link/button
  Error message box below fields
  Register link at bottom

RegisterScreen
  Toggle at top: User | Trainer
  User fields: name, email, password, confirm password, height, weight, age, goal dropdown
  Trainer fields: name, email, password, confirm password, certification
  Password text fields must have "view password" toggle options
  BMI auto-calculated and shown after height/weight entered

HomeScreen
  AppBar: "Hello [name] 👋" + profile icon
  Streak card: "🔥 [X] day streak"
  Today summary card: sessions done today + avg score
  Mini calendar widget: current week, green dots on active days
  Start Workout CTA: large gradient blue button
  Recommendations section: 3 exercises based on fitnessGoal
  Recent sessions list: last 5 sessions using SessionCard

ProfileScreen
  Circle avatar with first letter of name
  Info grid: height, weight, age, BMI, goal, role
  Sign out button (red)

HistoryScreen
  All sessions in ListView sorted by date newest first
  Each session shows: date, exercises, total reps, avg score

═══════════════════════════════════════════════════════════
MODULE 2: REAL-TIME 3D POSE DETECTION
═══════════════════════════════════════════════════════════

PRE-TRAINED MODEL: google_mlkit_pose_detection
This IS MediaPipe Pose Lite bundled in ML Kit SDK
No model file download needed
Works completely offline on device

SRS REQUIREMENTS:
- 30 FPS minimum
- 33 landmarks with X Y Z coordinates
- Skeleton overlay on live feed
- Total delay below 100ms
- 90-frame ring buffer

PoseDetectionService:
  PoseDetector with PoseDetectionModel.base (Pose Lite)
  PoseDetectionMode.stream for live video
  processFrame(CameraImage, CameraDescription) → List<Pose>
  jointAngle(lm, a, b, c) → double? degrees
  landmarkBuffer: Queue with maxSize 90
  fps getter returning current processing speed
  dispose() closes detector

kSkeletonPairs: List of 16 bone pairs
  leftShoulder-rightShoulder
  leftShoulder-leftElbow
  leftElbow-leftWrist
  rightShoulder-rightElbow
  rightElbow-rightWrist
  leftShoulder-leftHip
  rightShoulder-rightHip
  leftHip-rightHip
  leftHip-leftKnee
  leftKnee-leftAnkle
  rightHip-rightKnee
  rightKnee-rightAnkle
  leftAnkle-leftHeel
  rightAnkle-rightHeel
  leftHeel-leftFootIndex
  rightHeel-rightFootIndex

SkeletonPainter extends CustomPainter:
  Constructor: poses, imageSize, isFront, mode
  SkeletonMode enum: detecting, valid, invalid
  detecting = blue bones
  valid = green bones (#3FB950)
  invalid = red bones (#F85149)
  Mirror x-axis when isFront is true
  Bone strokeWidth: 2.8
  Joint dots: white filled circles radius 4.5
  Only draw landmarks with likelihood > 0.38
  shouldRepaint: true when poses or mode changes

═══════════════════════════════════════════════════════════
MODULE 3: EXERCISE RECOGNITION VIA CUSTOM MODEL API
═══════════════════════════════════════════════════════════

ExerciseRecognitionService:
  Constructor takes PoseDetectionService
  Uses Render endpoint: https://biomechai-server.onrender.com

  KEY METHODS:

  collectLandmarks():
    Read current landmarkBuffer (90 frames)
    Convert to List<List<List<double>>> shape (90, 33, 3)
    Each landmark: [x, y, z] normalized 0.0-1.0

  detectFirstRep(lm):
    Monitor primary joint angle for any large movement
    If angle changes more than 60 degrees → first rep detected
    Call sendToAPI() after first rep

  sendToAPI(landmarks):
    POST https://biomechai-server.onrender.com/classify
    Body: { landmarks: landmarks, fps: 30 }
    Timeout: 10 seconds (due to potential Render delay)
    Parse response → confirmedExercise + confidence
    If confidence >= 0.85 → confirm exercise
    If API fails → use fallback rule-based detection

  detectExerciseChange():
    Monitor if user stops moving for 5 seconds
    If stopped → set exerciseChangeDetected = true
    Clear landmark buffer
    Ready for next exercise detection

  exerciseTimeline: List<ExerciseBlock>
    Each block: exerciseName, startTime, endTime,
    totalReps, validReps, avgFormScore, weightUsed

  reset(): Clear everything for new session

FLUTTER HTTP CALL EXAMPLE:
  final response = await http.post(
    Uri.parse('https://biomechai-server.onrender.com/classify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'landmarks': landmarks, 'fps': 30}),
  ).timeout(Duration(seconds: 10));

═══════════════════════════════════════════════════════════
MODULE 4: REP COUNTING AND FORM VALIDATION
═══════════════════════════════════════════════════════════

RepCounterService:
  State machine: _state = 'up' or 'down'
  update(angle, isValid, score) → bool (true = rep done)
  When angle < 112 → switch to down
  When angle > 148 → switch to up = one rep completed
  Smooth using average of last 5 angles
  totalReps: int
  validReps: int
  avgScore: double
  repHistory: List<RepRecord>
    RepRecord: repNumber, formScore, isValid,
    errorsDetected, primaryAngle, timestamp
  reset() for new exercise

FormValidationService:
  Constructor: PoseDetectionService, heightCm
  heightAdj = (heightCm - 175) / 175 * 10 degrees

  validate(lm, exercise) → FormResult

  Pattern 1 — Sports science limits:
    kSafetyLimits map for all 7 exercises
    Each has: joint triplet, bMin, bMax, tMin, tMax
    Squat:        knee (LHip,LKnee,LAnkle) bottom 58-102 top 158-180
    Push-Up:      elbow (LShoulder,LElbow,LWrist) bottom 62-100 top 152-180
    Jumping Jack: shoulder (LShoulder,LHip,LKnee) bottom 28-92 top 153-180
    Bicep Curl:   elbow (RShoulder,RElbow,RWrist) bottom 148-180 top 22-72
    Lunge:        knee (RHip,RKnee,RAnkle) bottom 75-102 top 158-180
    Plank:        hip (LShoulder,LHip,LAnkle) holds at 153-180 always
    High Knees:   knee (LHip,LKnee,LAnkle) bottom 42-102 top 153-180
    If outside range: errors add HIGH severity, score -36

  Pattern 2 — AQMN smoothness:
    8-frame angle window standard deviation
    score = min(score, max(0, 100 - std * 3.2))

  Pattern 3 — Jerk RMS:
    15-frame acceleration calculation
    If RMS > 19: add MEDIUM error, score -14

  Pattern 4 — Symmetry:
    Compare Y coords: leftShoulder vs rightShoulder
    Compare Y coords: leftHip vs rightHip
    Compare Y coords: leftKnee vs rightKnee
    If asymmetry > 0.20: add LOW error, score -8

  Final score clamped 0-100
  valid = score >= 60 AND no HIGH severity errors

  feedback string:
    score >= 86: "Great [exercise] form! 💪"
    score >= 72: show first error message
    score < 72: "Fix: [first error message]"

WEIGHT INPUT FEATURE:
  WeightInputSheet bottom sheet widget
  Shows before each exercise starts
  Options: Bodyweight button OR number input in kg
  Stores weightUsed in ExerciseBlock and RepRecord

═══════════════════════════════════════════════════════════
MODULE 5: TRAINER DASHBOARD (React Web App)
═══════════════════════════════════════════════════════════

LOCATION: C:\biomechai-dashboard
TECH STACK: React 18, Firebase, Recharts, react-calendar, jsPDF

CREATE REACT APP:
  npx create-react-app biomechai-dashboard
  cd biomechai-dashboard
  npm install firebase recharts react-calendar jspdf

PAGES:

LoginPage (/login):
  Logo on top left corner
  Firebase Auth for trainer accounts
  Email + password
  Forgot password functionality
  Error handling

DashboardHome (/dashboard):
  Overview cards: total clients, active today,
  avg form score this week
  Today scheduled sessions
  Quick access to recent activity

ClientListPage (/clients):
  Table of all linked clients
  Columns: name, last active, sessions this week,
  avg form score, fitness goal, status
  Click row → go to ClientDetailPage

ClientDetailPage (/client/:uid):

  a) CALENDAR VIEW (supervisor requirement)
     react-calendar showing full month
     Green dot: completed workout day
     Orange dot: scheduled workout day
     Click any date → show sessions for that day
     Below calendar: event list for selected date

  b) DAY-WISE CATEGORIZATION (supervisor requirement)
     Date filter dropdown or click calendar date
     Timeline for that day:
     09:00 — Squat — 12 reps — Score: 87 — 40kg
     09:08 — Push-Up — 10 reps — Score: 74 — Bodyweight
     09:15 — Plank — 45 sec hold — Score: 91

  c) MUSCLE GROUP HISTORY (supervisor requirement)
     "Kisi aik muscle ka previous session"
     Dropdown: Legs / Chest / Arms / Core / Cardio
     Shows last 5 sessions for that muscle:
     Table: date, exercise, reps, weight, score
     Recharts LineChart: form score trend for muscle

  d) REP-BY-REP ANALYSIS (supervisor requirement)
     Click any session → expand rep table
     Table columns: Rep#, Valid?, Score, Error Detected, Angle
     Rep 1: ✅ 89/100 | Rep 2: ❌ 45/100 (knee outside range)
     Recharts BarChart: rep number vs form score

  e) WEIGHT TRACKING (supervisor requirement)
     Per exercise weight progression graph
     Recharts LineChart: date vs weight used
     Text: "Last session: Squat with 40kg"

  f) SESSION VIDEO PLAYBACK (supervisor requirement)
     HTML5 video player
     Loads video from Firebase Storage URL
     Trainer adds timestamped comment:
     Input: timestamp (mm:ss) + comment text
     Comments list below video sorted by timestamp
     Stored in Firestore trainer_feedback collection
     Pop-up notification pushed to the mobile application for the user

  g) EXERCISE RECOMMENDATIONS (supervisor requirement)
     Based on user fitnessGoal:
     Weight Loss → Jumping Jack, High Knees, Burpee
     Muscle Gain → Squat, Push-Up, Bicep Curl, Lunge
     Endurance → High Knees, Jumping Jack, Plank
     Flexibility → Lunge, Plank
     General → all 7 exercises rotation
     Trainer can edit and approve recommendations
     Approved recommendations pushed to user app

  h) PDF REPORT BUTTON
     Generate monthly PDF using jsPDF
     Contents:
     - Client name and period
     - Form score trend chart image
     - Exercise breakdown table
     - Weight progression summary
     - Consistency percentage
     - Trainer comments summary
     Download as BioMechAI_[name]_[month].pdf

SessionDetailPage (/session/:sessionId):
  Full session details
  Video player
  Exercise timeline
  Rep-by-rep table
  Trainer feedback panel

═══════════════════════════════════════════════════════════
WORKOUT SCREEN — COMPLETE FLOW
═══════════════════════════════════════════════════════════

STATE VARIABLES:
  cameraController, cameraReady
  poses, skeletonMode
  sessionActive, elapsed (timer seconds)
  exercise (current detected name)
  exerciseConfirmed (bool)
  formScore, formValid, feedback
  validReps, totalReps
  exerciseTimeline (list of ExerciseBlock)
  isDetectingNewExercise (bool)
  weightUsed (double)
  isRecording (bool)

SCREEN LAYOUT (Stack):
  Layer 1: CameraPreview (full screen)
  Layer 2: CustomPaint SkeletonPainter overlay
  Layer 3: Top HUD
  Layer 4: Timer badge top right
  Layer 5: Bottom panel

TOP HUD:
  Back button (top left)
  Exercise chip: "[exercise name] (confidence%)"
    Shows "Perform first rep..." before detection
    Shows confirmed exercise after detection
  FormScoreRing top right

BOTTOM PANEL:
  Row: ValidReps | TotalReps | FormScore (StatChip widgets)
  Feedback bar: green/red with icon and text
  Start Session / End Session button

COMPLETE SESSION FLOW:

BEFORE START:
  App calls _wakeUpServer() in initState to wake up Render server
  Show "Preparing AI model..." loading indicator if needed
  Camera opens and skeleton visible immediately
  WeightInputSheet appears: "Enter weight for first exercise"
  User enters weight → session starts
  Video recording begins
  Timer starts

DETECTING FIRST EXERCISE:
  Text shows: "Perform your first rep to begin..."
  MediaPipe tracks landmarks continuously
  detectFirstRep() monitors for 60+ degree angle change
  When first rep detected → collectLandmarks() → sendToAPI()
  API returns exercise → display name on screen

ACTIVE EXERCISE:
  Rep counting starts for reps 2 onwards
  Skeleton color updates based on form
  Rep counter increments
  Each rep saved to repHistory

EXERCISE CHANGE:
  User stops for 5 seconds
  Show: "New exercise? Starting detection..."
  WeightInputSheet for new exercise weight
  Buffer clears → detect next exercise
  Timeline updates

END SESSION:
  Tap End Session
  Stop recording → upload video to Firebase Storage
  Show uploading progress indicator
  When upload done → save session to Firestore
  Show summary BottomSheet:
    All exercises in timeline
    Total duration
    Total valid reps
    Average form score
    Weights used
  Navigate back to home

═══════════════════════════════════════════════════════════
VIDEO RECORDING SERVICE
═══════════════════════════════════════════════════════════

VideoRecordingService:
  startRecording(CameraController) → void
  stopRecording() → Future<String> (returns local file path)
  uploadToFirebase(filePath, sessionId, userId) → Future<String>
    Uploads to: videos/{userId}/{sessionId}.mp4
    Returns Firebase Storage download URL
  Store URL in session Firestore document as videoUrl

═══════════════════════════════════════════════════════════
FIRESTORE DATA STRUCTURE
═══════════════════════════════════════════════════════════

users/{uid}
  uid, email, name, heightCm, weightKg, age, bmi
  fitnessGoal, role, createdAt, streakCount, lastActiveDate

users/{uid}/workout_sessions/{sessionId}
  sessionId, userId, startTime, endTime, totalDuration
  avgFormScore, totalValidReps, totalReps
  videoUrl (Firebase Storage download URL)
  sessionDate (timestamp), dayOfWeek (string)
  exerciseCount (int)

users/{uid}/workout_sessions/{sessionId}/exercises/{exerciseId}
  exerciseName, muscleGroup, category
  totalReps, validReps, avgFormScore
  weightUsed (double, 0 = bodyweight)
  startTimestamp, endTimestamp

users/{uid}/workout_sessions/{sessionId}/reps/{repId}
  repNumber, exerciseName, formScore, isValid
  errorsDetected (list of strings)
  primaryAngle, timestamp, weightUsed

users/{uid}/scheduled_workouts/{scheduleId}
  date, exercises (list), type (pre/post)
  isCompleted, notes

trainer_clients/{trainerId_clientId}
  trainerId, clientId, linkedAt

trainer_feedback/{feedbackId}
  trainerId, clientId, sessionId
  feedbackText, videoTimestamp (seconds), createdAt

recommendations/{userId}
  exercises (list), basedOn (fitnessGoal)
  generatedAt, approvedByTrainer (bool)

═══════════════════════════════════════════════════════════
FLASK SERVER — server.py (CUSTOM RANDOM FOREST)
═══════════════════════════════════════════════════════════

LOCATION: C:\biomechai_server\server.py

BUILD COMPLETE server.py WITH:

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

# extract_features() function that extracts 50 biomechanical features

EXERCISE_DISPLAY_NAMES = {
    'squat':        'Squat',
    'pushup':       'Push-Up',
    'jumping_jack': 'Jumping Jack',
    'bicep_curl':   'Bicep Curl',
    'lunge':        'Lunge',
    'plank':        'Plank',
    'high_knees':   'High Knees',
}

POST /classify:
  Get landmarks from request JSON
  Pad or trim to exactly 90 frames
  Extract 50 features and scale them
  Run Random Forest predict_proba
  Return top exercise + confidence + top3 list

GET /health:
  Return status ok + model name + loaded bool

Run on 0.0.0.0 port 5000 (Local)
Deployment: Render (gunicorn server:app)

ALSO CREATE requirements.txt:
  flask
  flask-cors
  numpy
  scikit-learn
  joblib
  gunicorn

═══════════════════════════════════════════════════════════
PUBSPEC.YAML DEPENDENCIES
═══════════════════════════════════════════════════════════

dependencies:
  flutter:
    sdk: flutter
  google_mlkit_pose_detection: ^0.12.0
  camera: ^0.11.0+2
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
  firebase_messaging: ^14.9.4
  firebase_storage: ^11.7.7
  provider: ^6.1.2
  fl_chart: ^0.68.0
  http: ^1.2.2
  uuid: ^4.4.2
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  permission_handler: ^11.3.1
  cupertino_icons: ^1.0.8
  table_calendar: ^3.1.2
  path_provider: ^2.1.4

═══════════════════════════════════════════════════════════
COLORS AND THEME
═══════════════════════════════════════════════════════════

bg:       #060D1A
card:     #0D1117
card2:    #161B22
border:   #21262D
text:     #E6EDF3
muted:    #8B949E
blue:     #58A6FF
blueDark: #1E40AF
green:    #3FB950
yellow:   #D29922
red:      #F85149
purple:   #BC8CFF
orange:   #F0883E

AppRoutes constants:
  splash, login, register, home, workout,
  history, profile, trainer, schedule

═══════════════════════════════════════════════════════════
IMPLEMENTATION ORDER FOR ANTIGRAVITY AGENT
═══════════════════════════════════════════════════════════

BUILD IN THIS EXACT ORDER:

PHASE 1 — Models and Services:
  1. All model files in lib/models/
  2. lib/utils/app_theme.dart
  3. lib/services/firebase_service.dart
  4. lib/services/pose_detection_service.dart
  5. lib/services/exercise_recognition_service.dart
  6. lib/services/form_validation_service.dart
  7. lib/services/video_recording_service.dart

PHASE 2 — Providers:
  8. lib/providers/auth_provider.dart
  9. lib/providers/workout_provider.dart

PHASE 3 — Widgets:
  10. lib/widgets/skeleton_painter.dart
  11. lib/widgets/form_score_ring.dart
  12. lib/widgets/stat_chip.dart
  13. lib/widgets/session_card.dart
  14. lib/widgets/weight_input_sheet.dart
  15. lib/widgets/exercise_timeline_card.dart
  16. lib/widgets/mini_calendar.dart
  17. lib/widgets/rep_detail_card.dart

PHASE 4 — Screens:
  18. lib/screens/splash_screen.dart
  19. lib/screens/login_screen.dart
  20. lib/screens/register_screen.dart
  21. lib/screens/home_screen.dart
  22. lib/screens/workout_screen.dart
  23. lib/screens/history_screen.dart
  24. lib/screens/profile_screen.dart
  25. lib/screens/trainer_dashboard_screen.dart

PHASE 5 — Entry point:
  26. lib/main.dart (update with all routes and providers)

PHASE 6 — After all files created:
  Run: flutter pub get
  Run: flutter analyze
  Fix ALL errors before finishing

PHASE 7 — Flask server:
  Create C:\biomechai_server\server.py
  Create C:\biomechai_server\requirements.txt

PHASE 8 — React dashboard:
  Create C:\biomechai-dashboard using create-react-app
  Build all pages listed above

═══════════════════════════════════════════════════════════
DO NOT BUILD — FYP-2 MODULES
═══════════════════════════════════════════════════════════

Module 6: Body Measurement Tracking (SMPL model)
Module 7: AI Injury Prediction (LSTM + Isolation Forest)
Module 8: AI Voice Companion (LLaVA + ElevenLabs)

═══════════════════════════════════════════════════════════
DEMO SEQUENCE FOR 15TH JUNE EVALUATION
═══════════════════════════════════════════════════════════

1. Open app → splash → auto-login
2. Show home with calendar dots and recommendations
3. Tap Start Workout → weight input appears → enter 0 (bodyweight)
4. Camera opens → skeleton overlay visible immediately
5. Do one squat → API call → "Squat (91%)" appears
6. Do 5 more squats → counter goes up → green skeleton
7. Do bad squat → skeleton turns red → warning shown
8. Stop → do jumping jacks → new exercise detected same session
9. End session → video uploads → summary shown
10. Open React dashboard on laptop
11. Show client calendar with today marked green
12. Click today → see session timeline
13. Click session → watch video with skeleton
14. Show rep-by-rep table with ✅ and ❌
15. Show muscle group history graph
16. Add timestamped trainer feedback on video
17. Generate PDF report → download