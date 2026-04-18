# Synthese

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.11.0+-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)
![Android](https://img.shields.io/badge/Platform-Android%20Only%20(for%20now)-3DDC84?logo=android)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**An all-in-one wellness and performance tracking application designed for young athletes**

**🚀 Android-focused. Desktop/web code exists but is not actively maintained or tested.**

[Features](#-features) • [Installation](#-installation) • [Setup](#-configuration) • [Running](#-running-the-app) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Running the App](#-running-the-app)
- [Project Structure](#-project-structure)
- [Firebase Setup](#-firebase-setup)
- [Android Permissions](#-android-permissions)
- [Troubleshooting](#-troubleshooting)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)
- [Acknowledgments](#-acknowledgments)
- [Project Status & Roadmap](#-project-status--roadmap)
- [Screenshots](#-screenshots)

---

## 🎯 Overview

**Synthese** is a comprehensive wellness and performance management platform tailored for young athletes. The app provides tools to track and improve various aspects of athletic life, from financial management to menstrual cycle tracking, mindfulness exercises, dietary analysis, and live workout tracking. Built with Flutter and powered by Firebase, Synthese offers a seamless Android experience with real-time data synchronization.

### Key Highlights

- 🏃 **Athlete-Focused**: Designed specifically for young athletes' unique needs
- 📊 **Comprehensive Tracking**: Multiple specialized modules for holistic wellness
- 🔐 **Secure Authentication**: Firebase Auth with Google Sign-In support
- ☁️ **Cloud-Powered**: Real-time data sync via Cloud Firestore
- 🎨 **Beautiful UI**: Adaptive Material Design with dark/light theme support
- 🤖 **AI Integration**: Smart food analysis via GitHub Models API
- 📍 **Live Workouts**: GPS-powered route tracking with real-time metrics
- ⌚ **Wearable Sync**: Health Connect integration for smartwatch data

---

## ✨ Features

### 🔐 Authentication & Onboarding
- Email/password authentication with verification flow
- Google Sign-In integration
- Comprehensive multi-step onboarding flow
- Personalized athlete profiles with gender, sport, and lifestyle preferences

### 💪 Performance Dashboard
- Composite health score (0-100)
- Real-time metrics: steps, heart rate, active calories, exercise time
- 7-day sleep analysis chart
- Trend tracking with percentage deltas
- Health Connect integration (steps, heart rate, sleep, workouts)
- Manual `.txt` file import for offline data entry

### 🏃 Workout Tracking
- **Live GPS tracking** with interactive map and polyline route visualization
- **7 workout modes**: Running, Trail Run, Outdoor Walking, Cycling, Mountain Bike, E-Bike, Swimming
- Pause/resume/reset flow with countdown start
- Real-time metrics: distance, pace/speed, calories, active time
- Background foreground notification with live stats
- Workout history with saved routes, playback capability
- Persistent session storage with route points

### 🥗 Diet & Nutrition
- **AI image analysis**: Snap photos of meals for instant AI-powered calorie & macro estimates
- **AI text analysis**: Describe meals verbally for nutritional breakdown
- Meal logging with macro tracking (protein, carbs, fats)
- Daily calorie goal tracking and progress
- **Water intake tracker** with daily goal settings and 7-day trend visualization
- Diet onboarding flow with baseline water intake setup

### 🧘 Mindfulness & Mental Wellness
- Daily mood tracking with 7-tier color-coded scale
- Morning readiness check-in assessments
- Guided breathing exercise modals
- Mental health questionnaire (15 questions) with results
- Stress and recovery monitoring
- Personalized insights and mood trends visualization
- Mood history chart

### 🌸 Cycle Tracking (Female Users)
- Menstrual cycle calendar with phase predictions
- Symptom logging (cramps, bloating, fatigue, etc.)
- Flow tracking and mood correlations
- Cycle history and analytics
- Educational articles about reproductive health
- Deviation detection and early period/late period flows
- Daily cycle logging interface

### 💰 Finance Tracker
- Account management (checking, savings, credit card)
- Income and expense transaction tracking
- Debt management system (owe vs. owed-to-me)
- Debt payment history and paydown tracking
- Transfers between accounts
- Category-based spending analysis
- Budget visualization with charts
- Financial insights and contextual recommendations
- Multi-currency support based on user country

### 📱 Account & Data Management
- Account settings modal with profile viewing
- Email/password management
- Sign-out functionality
- Complete account deletion with cascading data cleanup
- Privacy-respecting data export (Firestore-based)

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev) (3.11.0+)
- **Language**: Dart
- **UI Components**: 
  - Material Design
  - Cupertino (iOS-style) widgets
  - Adaptive Platform UI

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **AI Analysis**: GitHub Models API (Llama 4 Scout 17B)
- **Maps & Location**: Flutter Map + Geolocator
- **Wearable Integration**: Health Connect (Android 12+)

### Key Dependencies
```yaml
firebase_core: ^4.5.0
firebase_auth: ^6.2.0
cloud_firestore: ^6.1.3
google_sign_in: ^5.4.2
http: ^1.1.0
image_picker: ^1.0.4
file_picker: ^8.0.0
flutter_dotenv: ^6.0.0
intl: ^0.20.2
modal_bottom_sheet: ^3.0.0
adaptive_platform_ui: ^0.1.103
geolocator: ^13.0.4
flutter_map: ^7.0.2
latlong2: ^0.9.1
flutter_local_notifications: ^19.4.2
health: ^13.3.1
permission_handler: ^11.4.0
shared_preferences: ^2.3.2
```

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.11.0 or higher)
  - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Git** for version control
- **Code Editor** (VS Code or Android Studio recommended)
- **Android Studio** (with Android SDK, API 26+)
- **Firebase Account** (free tier is sufficient)
- **GitHub Account** (for GitHub Models API token)

### Verify Installation

```bash
flutter doctor
```

Ensure all checks pass, especially Android toolchain and IDE.

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/manchikantithanush-netizen/Synthese.git
cd Synthese
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will download all required packages specified in `pubspec.yaml`.

### 3. Install Platform-Specific Dependencies

#### For Android:
No additional setup required beyond Android Studio. Gradle will handle dependencies automatically.

---

## ⚙️ Configuration

### 1. Firebase Configuration

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use: `synthese-c2958`
3. Enable the following services:
   - **Authentication** (Email/Password + Google Sign-In)
   - **Cloud Firestore** (Database)
   - **Firebase Storage** (file uploads)

#### Step 2: Download Android Configuration

1. In Firebase Console, add an Android app
2. Package name: `com.example.synthese`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### Step 3: Firebase Options Configuration

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase:
   ```bash
   flutterfire configure --project=synthese-c2958
   ```
   This generates `lib/config/firebase_options.dart`

### 2. Environment Variables Setup

#### Step 1: Create `.env` File

```bash
cp .env.example .env
```

#### Step 2: Add Your API Keys

Open `.env` and add:

```env
# Firebase API Keys
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
GOOGLE_WEB_CLIENT_ID=your_web_oauth_client_id_here

# GitHub Models API (for AI food analysis)
GITHUB_TOKEN=your_github_models_token_here
```

**Where to find keys:**
- Firebase Android API Key: From `google-services.json` → `client[0].api_key[0].current_key`
- Google Web Client ID: Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration
- GitHub Token: [GitHub Settings → Developer Settings → Personal Access Tokens](https://github.com/settings/tokens)

#### Step 3: Ensure `.env` is Loaded

Verify `lib/config/firebase_options.dart` reads from environment variables and that `pubspec.yaml` includes `.env` in assets:

```yaml
flutter:
  assets:
    - .env
```

**⚠️ SECURITY NOTE**: 
- **NEVER** commit `.env` to Git
- `.env` is already in `.gitignore`
- Only commit `.env.example` as a template

### 3. Google Sign-In Configuration

#### For Android:
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Google" provider
3. Get SHA-1 and SHA-256 fingerprints:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Copy debug/release SHA values into Firebase project settings
5. Re-download `google-services.json` and replace `android/app/google-services.json`

---

## ▶️ Running the App

### Development Mode

#### Run on connected device/emulator:
```bash
flutter run -d android
```

#### Run with debug output:
```bash
flutter run -d android -v
```

#### Run with specific build flavor:
```bash
flutter run --debug
flutter run --profile
flutter run --release
```

### Build for Production

#### Android APK:
```bash
flutter build apk --release
```

#### Android App Bundle (for Play Store):
```bash
flutter build appbundle --release
```

---

## 📁 Project Structure

```
synthese/
├── android/                     # Android native code & configuration
│   └── app/src/main/
│       ├── AndroidManifest.xml  # Permissions & Health Connect config
│       └── google-services.json # Firebase config (not in repo)
├── lib/                         # Main Flutter application code
│   ├── main.dart               # App entry point
│   ├── config/
│   │   └── firebase_options.dart # Firebase initialization
│   ├── theme/
│   │   └── app_theme.dart      # Light/dark theme definitions
│   ├── ui/                     # Core UI screens
│   │   ├── auth/               # Authentication (login, signup, verification)
│   │   ├── account/            # Account settings & profile
│   │   ├── components/         # Reusable UI components
│   │   ├── dashboard.dart      # Home screen with metrics
│   │   ├── workout.dart        # GPS workout tracking
│   │   ├── daily_logging_screen.dart  # Daily log entry
│   │   ├── more.dart          # More menu/navigation
│   │   └── start_page.dart    # App entry UI
│   ├── onboarding/            # Multi-step onboarding flows
│   │   ├── onboarding_intro.dart
│   │   ├── onboarding_personal.dart
│   │   ├── onboarding_athlete.dart
│   │   ├── onboarding_sports.dart
│   │   ├── onboarding_training.dart
│   │   ├── onboarding_lifestyle.dart
│   │   ├── onboarding_physical.dart
│   │   ├── onboarding_cycles.dart
│   │   ├── onboarding_finance.dart
│   │   ├── onboarding_diet.dart
│   │   └── onboarding_steps.dart
│   ├── diet/                  # Diet & nutrition module
│   │   ├── diet_page.dart
│   │   ├── diet_onboarding.dart
│   │   ├── food_analysis_service.dart  # AI food analysis
│   │   └── water_tracker_widget.dart
│   ├── mindfulness/           # Mental wellness module
│   │   ├── mindfulness_page.dart
│   │   ├── mindfulness_onboarding.dart
│   │   ├── questionnaire_screen.dart
│   │   ├── questionnaire_results_screen.dart
│   │   └── questionnaire_data.dart
│   ├── finance/               # Financial tracking module
│   │   ├── finance.dart      # Main finance page
│   │   ├── finance_add_transaction.dart
│   │   ├── finance_transfer.dart
│   │   ├── finance_debts.dart
│   │   ├── finance_debt_detail.dart
│   │   ├── finance_add_debt.dart
│   │   ├── finance_charts.dart
│   │   ├── finance_insights.dart
│   │   ├── finance_contextual_insights.dart
│   │   ├── models/
│   │   │   └── finance_models.dart
│   │   └── services/
│   │       └── finance_service.dart
│   ├── cycles/               # Menstrual cycle tracking module
│   │   ├── cycles.dart       # Main cycles page
│   │   ├── cyclecalendar.dart
│   │   ├── history_cycles.dart
│   │   ├── cycle_energy.dart
│   │   ├── cycledeviationmodal.dart
│   │   ├── past_cycle_summary.dart
│   │   ├── cycles_mechanism.dart
│   │   ├── help_cycles.dart
│   │   └── articles/        # Educational content
│   │       ├── cycle_article1.dart
│   │       ├── cycle_article2.dart
│   │       └── ... (6 total)
│   └── services/            # Core services
│       ├── health_connect_service.dart  # Wearable sync
│       └── first_launch_permissions_service.dart
├── assets/                  # Static assets (images)
│   └── image[1-6].jpg
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Flutter dependencies
├── pubspec.lock             # Locked dependency versions
├── analysis_options.yaml    # Linter rules
├── .env                     # Environment variables (DO NOT COMMIT)
├── .env.example             # Environment template (safe to commit)
├── .gitignore              # Git ignore rules
├── firebase.json           # Firebase configuration
└── README.md               # This file
```

---

## 🔥 Firebase Setup

### Firestore Database Structure

The app uses the following Firestore collections:

```
/users/{userId}
  - email: string
  - displayName: string
  - onboardingCompleted: boolean
  - profileData: map
  - gender: "Male" | "Female"
  - weight: number (kg)
  - country: string
  - mindfulnessOnboardingCompleted: boolean
  - dietSetupCompleted: boolean
  - financeSetupCompleted: boolean
  - dailyCalorieGoal: number
  - dailyWaterGoalGlasses: number
  - waterIntake: number (baseline litres)
  - cycleLength: number (days, default 28)
  - periodLength: number (days, default 5)
  - lastPeriodStart: timestamp
  
  /dashboardDaily/{dateKey}
    - activeCalories: number
    - heartRate: number
    - steps: number
    - exerciseMinutes: number
    - sleepData: [int × 7] (Mon-Sun)
    - hasUploadedOnce: boolean
    - lastWorkoutCaloriesReported: number
    - lastWorkoutMinutesReported: number
    - updatedAt: timestamp
  
  /workout_sessions/{sessionId}
    - mode: "running" | "trailRun" | "outdoorWalking" | "cycling" | "mountainBikeRide" | "eBikeRide" | "swimming"
    - startedAt: timestamp
    - endedAt: timestamp
    - distanceMeters: number
    - calories: number
    - activeMinutes: number
    - routePoints: [{lat: number, lng: number}]
  
  /foodLogs/{logId}
    - foodName: string
    - calories: number
    - protein: number (grams)
    - carbs: number (grams)
    - fats: number (grams)
    - description: string
    - timestamp: timestamp
  
  /waterDaily/{dateKey}
    - glasses: number
    - litres: number
    - dateKey: "YYYY-MM-DD"
    - updatedAt: timestamp
  
  /mood_logs/{logId}
    - mood_value: number (0.0-1.0)
    - mood_label: string
    - dateKey: "YYYY-MM-DD"
    - timestamp: timestamp
  
  /morning_readiness/{logId}
    - readiness_score: number (1-10)
    - timestamp: timestamp
  
  /cycles/{cycleId}
    - startDate: timestamp
    - endDate: timestamp
    - symptoms: string[]
    - flow: "None" | "Spotting" | "Light" | "Medium" | "Heavy" | "Very Heavy"
    - energy: number (1-10)
    - mood: string
    - cervicalMucus: string
  
  /finance_accounts/{accountId}
    - id: string
    - name: string
    - balance: number
    - type: "checking" | "savings" | "creditCard"
    - createdAt: timestamp
  
  /finance_categories/{categoryId}
    - id: string
    - name: string
    - type: "income" | "expense"
    - color: hex color
  
  /finance_transactions/{transactionId}
    - id: string
    - type: "income" | "expense" | "transfer"
    - amount: number
    - category: string
    - accountId: string
    - description: string
    - date: timestamp
    - createdAt: timestamp
  
  /finance_debts/{debtId}
    - id: string
    - type: "owe" | "owedToMe"
    - totalAmount: number
    - remainingAmount: number
    - isPaid: boolean
    - creditorName: string
    - description: string
    - createdAt: timestamp
    - dueDate: timestamp
    
    /payments/{paymentId}
      - amount: number
      - accountId: string
      - date: timestamp
      - createdAt: timestamp
```

### Firestore Security Rules

Add these rules in Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### Authentication Setup

1. Enable Email/Password:
   - Firebase Console → Authentication → Sign-in method → Email/Password
2. Enable Google Sign-In:
   - Enable "Google" provider
   - Configure support email

---

## 📱 Android Permissions

All permissions are declared in `android/app/src/main/AndroidManifest.xml`. Here's what each permission is used for:

| Permission | Purpose | Module |
|---|---|---|
| `INTERNET` | Firebase + API network requests | Core |
| `CAMERA` | Food photo capture for AI analysis | Diet |
| `READ_MEDIA_IMAGES` | Access gallery for meal images | Diet |
| `READ_EXTERNAL_STORAGE` | Fallback image access (Android <13) | Diet |
| `ACTIVITY_RECOGNITION` | Workout/activity detection | Dashboard/Workout |
| `ACCESS_COARSE_LOCATION` | Approximate location for workouts | Workout |
| `ACCESS_FINE_LOCATION` | Precise GPS for route tracking | Workout |
| `ACCESS_BACKGROUND_LOCATION` | Background GPS during active workouts | Workout |
| `FOREGROUND_SERVICE` | Long-running workout tracking service | Workout |
| `FOREGROUND_SERVICE_LOCATION` | Foreground location service behavior | Workout |
| `POST_NOTIFICATIONS` | Workout tracking live notification | Workout |
| `health.READ_STEPS` | Health Connect: steps sync | Dashboard (Health Connect) |
| `health.READ_HEART_RATE` | Health Connect: heart rate sync | Dashboard (Health Connect) |
| `health.READ_SLEEP` | Health Connect: sleep data sync | Dashboard (Health Connect) |
| `health.READ_ACTIVE_CALORIES_BURNED` | Health Connect: calorie sync | Dashboard (Health Connect) |
| `health.READ_EXERCISE` | Health Connect: workout data sync | Dashboard (Health Connect) |

**Runtime Permissions**: Handled via `permission_handler`, geolocator flows, and Health Connect authorization dialogs.

---

## 🐛 Troubleshooting

### Common Issues

#### 1. `MissingPluginException` on Firebase

**Solution**: Clean and reinstall
```bash
flutter clean
flutter pub get
```

#### 2. `.env` file not found

**Solution**: Create the file
```bash
cp .env.example .env
# Then add your API keys
```

#### 3. Firebase configuration errors

**Solution**: Reconfigure Firebase
```bash
flutterfire configure --project=synthese-c2958
```

#### 4. Google Sign-In fails with `ApiException: 10`

**Solution**: Add SHA fingerprints to Firebase
```bash
cd android
./gradlew signingReport
# Copy SHA-1 to Firebase Console → Project Settings → Add Fingerprint
```

#### 5. No wearable health data syncing

**Solution**: 
- Install Google Health Connect app on device
- Grant permission to Synthese in Health Connect settings
- Ensure target device is Android 12+

#### 6. Diet AI analysis fails

**Solution**: 
- Verify `GITHUB_TOKEN` in `.env` is valid
- Check internet connectivity
- Ensure image is valid (not corrupted or too small)

#### 7. GPS/location not working in workouts

**Solution**:
- Enable location services on device
- Grant Location permission to app
- Use emulator with GPS simulation if on desktop testing

---

## 🧪 Testing

### Run all tests:
```bash
flutter test
```

### Run specific test file:
```bash
flutter test test/widget_test.dart
```

### Run with coverage:
```bash
flutter test --coverage
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'feat(scope): add amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Code Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features
- Ensure code passes `flutter analyze`

### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example**:
```
feat(workout): add route playback on history

- Add polyline animation on previous route view
- Implement speed replay controls
- Add distance/time markers

Closes #45
```

---

## 📄 License

This project is licensed under the **MIT License** - see details below.

```
MIT License

Copyright (c) 2024 Thanush Manchikanti

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 👤 Contact

**Thanush Manchikanti**

- GitHub: [@manchikantithanush-netizen](https://github.com/manchikantithanush-netizen)
- Repository: [Synthese](https://github.com/manchikantithanush-netizen/Synthese)

---

## 🙏 Acknowledgments

- Flutter team for the amazing cross-platform framework
- Firebase for reliable backend infrastructure
- GitHub Models for AI-powered food analysis capabilities
- All open-source contributors whose packages made this possible
- Google Health Connect for wearable integration
- The athletics community for continuous feedback and inspiration

---

## 📊 Project Status & Roadmap

🚧 **Status**: Active Development (Android-first)

This project is actively being developed. Features are being added regularly, and contributions are welcome!

### Current Release
- ✅ Core authentication and onboarding
- ✅ Dashboard with Health Connect sync
- ✅ GPS workout tracking
- ✅ AI-powered diet tracking
- ✅ Mindfulness & mood logging
- ✅ Finance management
- ✅ Menstrual cycle tracking
- ✅ Account & data management

### Roadmap (Future Releases)

- [ ] Performance analytics dashboard (advanced metrics)
- [ ] Social features (connect with other athletes)
- [ ] Workout-form AI coaching via camera
- [ ] Premium tier features (advanced insights, priority support)
- [ ] iOS support (after Android stabilization)
- [ ] Web version (dashboard & data export)
- [ ] Apple HealthKit integration (iOS)
- [ ] Wearable direct app support (Wear OS)
- [ ] Push notifications for goals/reminders
- [ ] Data export (CSV, PDF reports)
- [ ] Offline mode with sync
- [ ] Voice logging for workouts/meals

---

## 📸 Screenshots

<img width="497" height="1005" alt="Dashboard Overview" src="https://github.com/user-attachments/assets/3c17f8bb-ed94-4ed7-8b24-db6fe876b0ec" />
<img width="535" height="1012" alt="Workout Tracking" src="https://github.com/user-attachments/assets/54c45d98-4a0b-4d4f-9ab3-37b9ae1f03ca" />
<img width="536" height="1014" alt="Diet & Nutrition" src="https://github.com/user-attachments/assets/7a30c3e7-67ae-4a51-8b44-0e6381917217" />
<img width="518" height="999" alt="Mindfulness" src="https://github.com/user-attachments/assets/6fc696aa-4096-49fc-949c-b09f2971e422" />
<img width="518" height="1008" alt="Finance Tracking" src="https://github.com/user-attachments/assets/15d3ad06-fc8d-41e0-9646-e69093932ca8" />

---

<div align="center">

**Made with ❤️ for athletes everywhere**

[Report Bug](https://github.com/manchikantithanush-netizen/Synthese/issues) • [Request Feature](https://github.com/manchikantithanush-netizen/Synthese/issues) • [View Progress](https://github.com/manchikantithanush-netizen/Synthese/projects)

</div>
