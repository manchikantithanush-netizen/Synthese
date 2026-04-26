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
  static const String currentVersion = '1.4.0+8';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.4.0+8 brings a polished visual refresh and smoother first-time experience across the app. We’ve introduced a new Dark Mode switch, redesigned switches and interactive button animations, and improved colors across the start, sign in, sign up, onboarding, and picker screens for a more consistent modern look. Typography has also been updated to Plus Jakarta Sans across key pages to better match the dashboard experience.

This update also improves usability and clarity by reorganizing the start page navigation, adding direct access to the Privacy Policy, expanding the wearable compatibility list, and including guidance for installing Health Connect for syncing. We’ve refined the About App page by removing unnecessary details, updated the version display style, and improved dialogs and theme consistency throughout the app, including battery and bottom navigation bar visuals.""";
}
