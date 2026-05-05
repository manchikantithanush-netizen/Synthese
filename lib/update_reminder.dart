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
  static const String currentVersion = '1.8.0+12';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.7.0+11 refines your health tracking experience with a cleaner and more intuitive interface. The dashboard has been simplified by removing manual adjustments and percentage comparisons, making it easier to focus on what matters.

A new “Tap to Explore” prompt guides you to detailed views, while “+ Add Data” allows you to manually log your metrics with ease.

Sleep tracking now includes a new “Asleep” phase for more flexible logging. Health Connect has been temporarily removed to improve data stability, with plans for a better implementation in the future.

Overall, this update focuses on simplicity, clarity, and giving you more control over your data.""";
}
