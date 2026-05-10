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
  static const String currentVersion = '1.9.0+13';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.9.0+13 brings a completely redesigned onboarding experience, a new Athlete Details section, and a fresh notification design.

Getting started is now faster and simpler than ever. The onboarding flow has been fully reworked — the first stage has been updated, and the original first three slides of the second stage have been merged into a single screen, cutting out unnecessary steps so you can get into the app quicker.

Only the essentials are asked upfront. Extra details that aren't immediately needed have been removed from onboarding entirely. Things like health details and athlete-specific information can now be filled in at any time from the Account Details section, at your own pace.

Speaking of which, a new Athlete Details section has been added under Account Details, giving athletes a dedicated place to log and manage their specific information whenever it suits them.

The dashboard has also received bug fixes and stability improvements for a smoother experience.

Finally, notifications have a brand new design that's cleaner and more polished.

This update is all about getting out of your way — less friction, more focus on what matters.""";
}
