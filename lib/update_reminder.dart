// =============================================================================
// UPDATE REMINDER
// =============================================================================
// HOW TO USE:
//   1. Before uploading to the Play Store, bump pubspec.yaml version.
//   2. Set [currentVersion] below to match pubspec.yaml exactly.
//   3. Replace [updateMessage] with what's new in this release.
//   4. Save the file. Done.
//
// The app will show an in-app notification the first time a user opens
// the new version, then never again for that version.
// =============================================================================

class UpdateReminder {
  /// Must match pubspec.yaml version exactly, e.g. "1.0.0+3"
  static const String currentVersion = '2.0.0+15';
  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 2.0.0 — Major Update

What's New:
- Step Tracking — New pedometer with background or workout-only tracking, calories update automatically with your steps
- 5 Languages — App now supports Spanish, Arabic, Hindi, and Mandarin alongside English
- Detailed Nutrition — Food detection now includes proteins, fats, carbs, fibers, and micronutrients
- Macros Dashboard — Full macros breakdown added to the diet section, with manual entry support
- Smart Auto-Updater — New update system that tells you how urgent each update is
- Guest Account — Try the app instantly with a 3-day guest session, no sign-in needed
- Smoother Onboarding — Step counting permission added to the onboarding flow
- UI Polish — Consistent colors throughout, redesigned buttons, and a slower intro animation for easier reading

Fixes & Improvements:
- Fixed scrolling in account details
- Fixed text overflow in heart rate and Arabic layouts
- Fixed bottom navigation bar stability
- Fixed ChatGPT responses in non-English languages
- Fixed background step tracking toggle
- Fixed screen dimming during heart rate measurement
- Updated Privacy Policy and Terms & Conditions
- Various stability and layout fixes across sections""";
}
