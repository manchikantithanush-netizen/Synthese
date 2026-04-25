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
  static const String currentVersion = '1.3.0+7';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.3.0+7 focuses on UI stability and refined navigation. We’ve resolved theme inconsistencies and overlapping elements in the navigation bar, while ensuring the About App page and onboarding slides now scale correctly for smaller or slimmer devices. Version 1.2.0+6 focuses on UI stability and refined navigation. We’ve resolved theme inconsistencies and overlapping elements in the navigation bar, while ensuring the About App page and onboarding slides now scale correctly for smaller or slimmer devices.

This update introduces a new Notification System with in-app toasts and optimizes performance by replacing unstable elements with Android Native UI. To ensure a consistent experience, the app now exclusively supports Portrait View. Additionally, we’ve updated the date selector to enforce a minimum age requirement of 13 years or older. Also a new permission slides in the second onboarding instead of asking all permissions at once""";
}
