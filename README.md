# BioMechAI - AI-Powered Fitness Tracker

BioMechAI is an advanced fitness tracking application that utilizes a **Custom Trained Machine Learning Model** to accurately identify and track human exercises. 

## Why a Custom Trained Model?
Rule-based identification of exercises is an outdated method. Human bodies come in different forms, and gestures vary significantly between individuals. Relying on strict angle rules is often inaccurate and inflexible. BioMechAI solves this by using a custom trained Random Forest classifier based on 50 biomechanical features extracted via Google MediaPipe. This ensures high accuracy tailored specifically to our 7 core exercises.

## Core App Features (Flutter)
- **Automatic Exercise Recognition:** Whenever you open the app camera, it tracks your movements. After the first rep of any exercise, the app automatically identifies the exercise and starts recording the session.
- **Multiple Exercise Identification in a Single Session:** Users can perform multiple exercises (e.g., Squats followed by Push-ups) in the same session. The app intelligently detects the change and logs both exercises within the same session timeline.
- **Pre-Exercise Weight Logging:** Users are prompted to enter the weight information before performing any kind of exercise.
- **Target-Based Exercise Recommendations:** Provides exercise recommendations based on the user's specific fitness goals.
- **Session Recording & Sync:** All completed sessions are recorded and made immediately visible to the trainer on the web dashboard.
- **Trainer Feedback Notifications:** Receive pop-up notifications directly in the app when a trainer provides feedback on a session.
- **Enhanced Authentication:** 
  - Forgot password functionality.
  - Enter password and Confirm password fields with a "view password" toggle option.

## Web Dashboard Features (React)
The web dashboard is a dedicated portal for trainers to monitor and guide their clients effectively.
- **Trainer Authentication:** Secure trainer login page with the BioMechAI logo prominently displayed in the top-left corner. Includes forgot password functionality.
- **Day-Wise Categorization:** Easily filter and view client activities categorized by day.
- **Calendar-Wise Schedule:** Manage pre-workout and post-workout date-wise events for each client.
- **In-Depth Rep Analysis:** Check detailed information for every single rep to see if it was performed correctly or not.
- **Muscle-Specific History:** View the previous session's performance data focused on a specific muscle group ("Kisi aik muscle ka previous session ka bare ma").
- **Direct Feedback:** Provide per-session feedback that instantly triggers a notification in the client's mobile app.

## Architecture
- **Frontend:** Flutter Mobile App (User) & React Web Dashboard (Trainer)
- **Backend Model Server:** Python Flask Server running a Custom Random Forest Classifier (Deployed on Render).
- **Pose Detection:** Google MediaPipe (On-device)
- **Database & Auth:** Firebase (Firestore, Authentication, Storage)

## Setup & Deployment
The machine learning model is trained locally using `scikit-learn` and deployed to Render. The Flutter app connects directly to the Render endpoint (`https://biomechai-server.onrender.com`).
