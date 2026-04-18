# Synthese

**Synthese is Android-only for now.**  
The codebase includes Flutter desktop/web folders, but active support and testing are currently focused on Android.

## Overview

Synthese is a wellness and performance app for athletes, combining daily health metrics, workout tracking, diet analysis, mindfulness, cycle tracking, and finance tools in one app.

## Current Features

1. **Authentication**
   - Email/password sign-up and login
   - Email verification flow
   - Google Sign-In
   - Password reset
2. **Onboarding**
   - Multi-step profile onboarding (personal, athlete, training, lifestyle, sports)
   - Specialized onboarding for Diet, Finance, Mindfulness, and Cycles
3. **Home Dashboard**
   - Composite health score
   - Steps, heart rate, active calories, exercise minutes, and 7-day sleep analysis
   - Health Connect sync (steps, heart rate, sleep, active energy, workouts)
   - Manual `.txt` data import for dashboard metrics
4. **Workout Tracking**
   - Live GPS tracking with map and route polyline
   - Modes: Running, Trail Run, Outdoor Walking, Cycling, Mountain Bike, E-Bike, Swimming
   - Pause/resume/reset flow
   - Background tracking notification
   - Workout history with saved route previews
5. **Diet & Nutrition**
   - AI image-based food analysis
   - AI text-based meal analysis
   - Macro + calorie logging
   - Daily calorie target tracking
   - Water tracking with daily goal and 7-day trend
6. **Mindfulness**
   - Mood tracking
   - Morning readiness check-ins
   - Breathing exercise modal
   - Mental health questionnaire and results view
   - Mood trends/insights visualization
7. **Finance**
   - Accounts, transactions, and category-based tracking
   - Transfers between accounts
   - Debt tracking with payment history
   - Finance insights and contextual insights
8. **Cycles (shown for female users)**
   - Cycle calendar/history
   - Symptom, flow, and mood tracking
   - Deviation flows and cycle education/help content
   - Daily cycle logging
9. **Account & Data**
   - Account modal with sign-out
   - Delete-account flow that clears user document + app subcollections

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase Auth + Cloud Firestore
- **AI API:** GitHub Models API (used for food analysis)
- **Android integrations:** Health Connect, Geolocator, Flutter Map, Local Notifications

## Android Permissions

Declared in `android/app/src/main/AndroidManifest.xml`:

| Permission | Why it is used |
|---|---|
| `INTERNET` | Firebase + API requests |
| `CAMERA` | Food image capture for diet analysis |
| `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` | Picking meal images from device gallery |
| `ACTIVITY_RECOGNITION` | Workout/activity-related metrics |
| `ACCESS_COARSE_LOCATION` / `ACCESS_FINE_LOCATION` | Live workout GPS and route tracking |
| `ACCESS_BACKGROUND_LOCATION` | Continued location updates during ongoing workout |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` | Foreground tracking service behavior for active workouts |
| `POST_NOTIFICATIONS` | Workout tracking notification while route is active |
| `health.READ_STEPS` | Health Connect steps sync |
| `health.READ_HEART_RATE` | Health Connect heart-rate sync |
| `health.READ_SLEEP` | Health Connect sleep-session sync |
| `health.READ_ACTIVE_CALORIES_BURNED` | Health Connect active calories sync |
| `health.READ_EXERCISE` | Health Connect workout/exercise sync |

Runtime requests are handled through `permission_handler`, geolocator permission flows, and Health Connect authorization.

## Prerequisites

- Flutter SDK (with Android toolchain configured)
- Android Studio / Android SDK
- Firebase project configured for Android
- GitHub token for AI food analysis

## Setup

1. **Clone and install dependencies**
   ```bash
   git clone https://github.com/manchikantithanush-netizen/Synthese.git
   cd Synthese
   flutter pub get
   ```

2. **Firebase Android config**
   - Register Android app with package name: `com.example.synthese`
   - Put `google-services.json` at:
     - `android/app/google-services.json`
   - Enable Firebase Auth and Firestore

3. **Environment file**
   Create a `.env` in project root:
   ```env
   FIREBASE_ANDROID_API_KEY=your_android_firebase_api_key
   GOOGLE_WEB_CLIENT_ID=your_google_web_client_id_for_signin
   GITHUB_TOKEN=your_github_models_token
   ```

## Run (Android)

```bash
flutter run -d android
```

## Build (Android)

```bash
flutter build apk --release
flutter build appbundle --release
```

## Project Structure (key folders)

```text
lib/
  ui/                 # Dashboard, workout, auth, account, shared UI
  onboarding/         # Onboarding flows
  diet/               # Food AI + water tracking
  mindfulness/        # Mood/readiness/questionnaire
  finance/            # Accounts, transactions, debts, insights
  cycles/             # Cycle tracking + education
  services/           # Health Connect + first-launch permissions
  config/             # Firebase options
android/              # Android-specific platform config
assets/               # Static assets
test/                 # Flutter tests
```

## Firestore Collections Used

Per-user document and major subcollections:

- `users/{uid}`
- `dashboardDaily`
- `workout_sessions`
- `foodLogs`
- `waterDaily`
- `mood_logs`
- `morning_readiness`
- `cycles`
- `finance_accounts`
- `finance_categories`
- `finance_transactions`
- `finance_debts` (+ nested `payments`)

## Troubleshooting

- **Google Sign-In fails with ApiException: 10**  
  Add SHA-1/SHA-256 fingerprints in Firebase, re-download `google-services.json`.
- **No wearable sync data**  
  Install Health Connect and grant requested health data permissions.
- **Diet AI analysis fails**  
  Verify `GITHUB_TOKEN` in `.env` and internet connectivity.

## Status

🚧 Active development, Android-first.
