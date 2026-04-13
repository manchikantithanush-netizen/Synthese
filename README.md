# Synthese

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.11.0+-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**An all-in-one wellness and performance tracking application designed for young athletes**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Firebase Setup](#firebase-setup)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## 🎯 Overview

**Synthese** is a comprehensive wellness and performance management platform tailored for young athletes. The app provides tools to track and improve various aspects of athletic life, from financial management to menstrual cycle tracking, mindfulness exercises, and dietary analysis. Built with Flutter and powered by Firebase, Synthese offers a seamless cross-platform experience with real-time data synchronization.

### Key Highlights

- 🏃 **Athlete-Focused**: Designed specifically for young athletes' unique needs
- 📊 **Comprehensive Tracking**: Multiple specialized modules for holistic wellness
- 🔐 **Secure Authentication**: Firebase Auth with Google Sign-In support
- ☁️ **Cloud-Powered**: Real-time data sync via Cloud Firestore
- 🎨 **Adaptive UI**: Beautiful, platform-specific design (iOS/Android)
- 🤖 **AI Integration**: Smart insights powered by AI models

---

## ✨ Features

### 🔐 Authentication & Onboarding
- Email/password authentication
- Google Sign-In integration
- Comprehensive multi-step onboarding flow
- Personalized athlete profiles

### 💰 Finance Tracker
- Income and expense tracking
- Debt management system
- Financial insights and analytics
- Category-based spending analysis
- Budget visualization with charts
- Transfer tracking between accounts

### 🌸 Cycle Tracker
- Menstrual cycle tracking and prediction
- Symptom logging (energy levels, mood, flow)
- Cycle history and analytics
- Educational articles about reproductive health
- Calendar view with cycle phases
- Deviation detection and alerts

### 🧘 Mindfulness & Mental Wellness
- Daily mood tracking
- Morning readiness assessments
- Guided breathing exercises
- Mental wellness questionnaires
- Stress and recovery monitoring
- Personalized insights

### 🥗 Diet & Nutrition
- Meal logging and tracking
- AI-powered food analysis
- Image-based meal recognition
- Nutritional insights
- Diet onboarding and goal setting

### 📅 Daily Logging
- Daily performance metrics
- Custom data entry forms
- Historical data visualization
- Progress tracking over time

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev) (3.11.0+)
- **Language**: Dart
- **UI Components**: 
  - Cupertino (iOS-style widgets)
  - Material Design
  - Adaptive Platform UI

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Platform**: Firebase (synthese-c2958 project)

### AI & Analysis
- **Food Analysis**: AI-powered meal recognition
- **Insights**: Contextual recommendations based on user data

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
```

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.11.0 or higher)
  - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Git** for version control
- **Code Editor** (VS Code, Android Studio, or IntelliJ IDEA recommended)
- **Xcode** (for iOS development on macOS)
- **Android Studio** (for Android development)
- **Firebase Account** (free tier is sufficient)

### Verify Installation

```bash
flutter doctor
```

Ensure all checks pass (or at least Android/iOS toolchain and IDE).

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/manchikantithanush-netizen/synthese.git
cd synthese
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will download all required packages specified in `pubspec.yaml`.

### 3. Install Platform-Specific Dependencies

#### For iOS (macOS only):
```bash
cd ios
pod install
cd ..
```

#### For Android:
No additional steps required. Gradle will handle dependencies automatically.

---

## ⚙️ Configuration

### 1. Firebase Configuration

#### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing project: `synthese-c2958`
3. Enable the following services:
   - **Authentication** (Email/Password + Google Sign-In)
   - **Cloud Firestore** (Database)
   - **Firebase Storage** (if using file uploads)

#### Step 2: Download Configuration Files

##### For Android:
1. In Firebase Console, add an Android app
2. Package name: `com.company.synthese` (or check `android/app/build.gradle`)
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

##### For iOS:
1. In Firebase Console, add an iOS app
2. Bundle ID: `com.example.synthese` (or check `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

#### Step 3: Firebase Options Configuration
1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configure Firebase for your project:
   ```bash
   flutterfire configure --project=synthese-c2958
   ```

   This will generate `lib/config/firebase_options.dart`

### 2. Environment Variables Setup

The app uses environment variables to securely store API keys.

#### Step 1: Create `.env` File

Copy the example file:
```bash
cp .env.example .env
```

#### Step 2: Add Your Firebase API Keys

Open `.env` and add your Firebase API keys:

```env
# Firebase API Keys
FIREBASE_WEB_API_KEY=your_web_api_key_here
GOOGLE_WEB_CLIENT_ID=your_web_oauth_client_id_here
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_IOS_API_KEY=your_ios_api_key_here
```

**Where to find API keys:**
- Web API Key: Firebase Console → Project Settings → General → Web API Key
- Google Web Client ID: Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration
- Android API Key: From `google-services.json` → `client[0].api_key[0].current_key`
- iOS API Key: From `GoogleService-Info.plist` → `API_KEY`

#### Step 3: Update `firebase_options.dart`

Ensure `lib/config/firebase_options.dart` reads from environment variables:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static FirebaseOptions get web => FirebaseOptions(
  apiKey: dotenv.env['FIREBASE_WEB_API_KEY'] ?? '',
  // ... other config
);
```

**⚠️ SECURITY NOTE**: 
- **NEVER** commit `.env` file to Git
- `.env` is already in `.gitignore`
- Only commit `.env.example` as a template

### 3. Google Sign-In Configuration

#### For Android:
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Google" provider
3. Add SHA-1 and SHA-256 fingerprints:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Copy debug/release SHA-1 and SHA-256 values into Firebase project settings for your Android app
5. Re-download `google-services.json` and replace `android/app/google-services.json`

#### For iOS:
1. Open `ios/Runner/Info.plist`
2. Add URL scheme (from `GoogleService-Info.plist`):
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

---

## ▶️ Running the App

### Development Mode

#### Run on connected device/emulator:
```bash
flutter run
```

#### Run on specific platform:
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web (if supported)
flutter run -d chrome
```

#### Run with specific flavor:
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

#### iOS (requires macOS):
```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and upload.

---

## 📁 Project Structure

```
synthese/
├── android/                 # Android native code
├── ios/                     # iOS native code
├── lib/                     # Main Flutter application code
│   ├── config/             # Configuration files (Firebase options)
│   ├── cycles/             # Menstrual cycle tracking module
│   │   ├── articles/       # Educational content
│   │   ├── cycles.dart     # Main cycles page
│   │   ├── cyclecalendar.dart
│   │   ├── history_cycles.dart
│   │   └── ...
│   ├── diet/               # Diet and nutrition module
│   │   ├── diet_page.dart
│   │   ├── diet_onboarding.dart
│   │   └── food_analysis_service.dart
│   ├── finance/            # Financial tracking module
│   │   ├── models/         # Data models
│   │   ├── services/       # Business logic
│   │   ├── finance.dart    # Main finance page
│   │   ├── finance_add_transaction.dart
│   │   ├── finance_debts.dart
│   │   ├── finance_insights.dart
│   │   └── ...
│   ├── mindfulness/        # Mental wellness module
│   │   ├── mindfulness_page.dart
│   │   ├── questionnaire_screen.dart
│   │   └── questionnaire_data.dart
│   ├── onboarding/         # User onboarding flow
│   │   ├── onboarding_intro.dart
│   │   ├── onboarding_personal.dart
│   │   ├── onboarding_athlete.dart
│   │   └── ...
│   ├── ui/                 # Core UI screens
│   │   ├── auth/           # Authentication screens
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   └── verification_page.dart
│   │   ├── components/     # Reusable UI components
│   │   │   ├── mood_tracker_modal.dart
│   │   │   ├── breathing_exercise_modal.dart
│   │   │   └── ...
│   │   ├── account/        # Account settings
│   │   ├── dashboard.dart  # Main dashboard
│   │   ├── daily_logging_screen.dart
│   │   └── start_page.dart
│   ├── theme/              # App theming
│   │   └── app_theme.dart  # Light/dark theme definitions
│   └── main.dart           # App entry point
├── assets/                 # Static assets (images, etc.)
├── test/                   # Unit and widget tests
├── web/                    # Web platform files
├── .env                    # Environment variables (DO NOT COMMIT)
├── .env.example            # Environment template (safe to commit)
├── .gitignore              # Git ignore rules
├── pubspec.yaml            # Flutter dependencies
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
  
  /finances/{financeId}
    - type: "income" | "expense" | "debt" | "transfer"
    - amount: number
    - category: string
    - date: timestamp
    - description: string
  
  /cycles/{cycleId}
    - startDate: timestamp
    - endDate: timestamp
    - symptoms: array
    - flow: string
    - energy: number
    - mood: string
  
  /mindfulness/{entryId}
    - date: timestamp
    - mood: string
    - readiness: number
    - breathingExercises: number
    - journalEntry: string
  
  /diet/{mealId}
    - date: timestamp
    - mealType: "breakfast" | "lunch" | "dinner" | "snack"
    - items: array
    - imageUrl: string
    - analysis: map
  
  /dailyLogs/{logId}
    - date: timestamp
    - metrics: map
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

1. Enable Email/Password authentication:
   - Firebase Console → Authentication → Sign-in method
   - Enable "Email/Password"

2. Enable Google Sign-In:
   - Enable "Google" provider
   - Configure support email

---

## 🐛 Troubleshooting

### Common Issues

#### 1. `MissingPluginException` on Firebase

**Solution**: Run `flutter clean` then `flutter pub get`

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

#### 2. `.env` file not found

**Solution**: Make sure `.env` exists in project root

```bash
cp .env.example .env
# Then add your API keys
```

#### 3. Firebase configuration errors

**Solution**: Reconfigure Firebase

```bash
flutterfire configure --project=synthese-c2958
```

#### 4. Google Sign-In not working on Android

**Solution**: Add SHA-1 fingerprint to Firebase

```bash
cd android
./gradlew signingReport
# Copy SHA-1 to Firebase Console → Project Settings → Add Fingerprint
```

#### 5. Build fails on iOS

**Solution**: Update pods and clean

```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

#### 6. API key errors

**Cause**: Firebase API keys not properly configured

**Solution**: 
1. Check `.env` file has correct keys
2. Verify `firebase_options.dart` loads from `dotenv.env`
3. Ensure `.env` is listed in `pubspec.yaml` assets

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

### Integration tests:
```bash
flutter drive --target=test_driver/app.dart
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
   git commit -m 'Add some amazing feature'
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
feat(finance): add debt tracking feature

- Add debt creation form
- Implement debt list view
- Add debt payment tracking

Closes #123
```

---

## 📄 License

This project is licensed under the **MIT License** - see below for details.

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
- Repository: [Synthese](https://github.com/manchikantithanush-netizen/synthese)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- All open-source contributors whose packages made this possible

---

## 📊 Project Status

🚧 **Status**: Active Development

This project is actively being developed. Features are being added regularly, and contributions are welcome!

### Roadmap

- [ ] Performance analytics dashboard
- [ ] Social features (connect with other athletes)
- [ ] Workout tracking integration
- [ ] Premium tier features
- [ ] iOS TestFlight release
- [ ] Android Play Store release
- [ ] Web version
- [ ] Advanced AI insights

---

## 📸 Screenshots

<img width="497" height="1005" alt="Screenshot 2026-04-03 at 11 06 03 AM" src="https://github.com/user-attachments/assets/3c17f8bb-ed94-4ed7-8b24-db6fe876b0ec" />
<img width="535" height="1012" alt="Screenshot 2026-04-03 at 11 06 21 AM" src="https://github.com/user-attachments/assets/54c45d98-4a0b-4d4f-9ab3-37b9ae1f03ca" />
<img width="536" height="1014" alt="Screenshot 2026-04-03 at 11 06 46 AM" src="https://github.com/user-attachments/assets/7a30c3e7-67ae-4a51-8b44-0e6381917217" />
<img width="518" height="999" alt="Screenshot 2026-04-03 at 11 06 56 AM" src="https://github.com/user-attachments/assets/6fc696aa-4096-49fc-949c-b09f2971e422" />
<img width="518" height="1008" alt="Screenshot 2026-04-03 at 11 07 17 AM" src="https://github.com/user-attachments/assets/15d3ad06-fc8d-41e0-9646-e69093932ca8" />

---

<div align="center">

**Made with ❤️ for athletes everywhere**

[Report Bug](https://github.com/manchikantithanush-netizen/synthese/issues) · [Request Feature](https://github.com/manchikantithanush-netizen/synthese/issues)

</div>
