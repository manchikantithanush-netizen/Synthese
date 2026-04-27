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
  static const String currentVersion = '1.5.0+9';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.5.0+9 delivers a major upgrade focused on security, visual consistency, and a richer activity tracking experience. We’ve improved onboarding by refining Dark Mode colors, refreshed section colors across the app for a cleaner and more unified appearance, and redesigned alert dialogs with a modern gray style. Switch controls have also been fixed for smoother and more reliable interaction without stopping midway.

This update introduces an expanded steps analytics experience with a new detailed steps view, interactive bar graph, activity heatmap, distance tracker, circular goal progress tracker, and energy goal tracker to help you better understand your daily movement at a glance. Behind the scenes, we’ve also completed a major security improvement by moving sensitive environment configuration to Cloudflare for safer and more scalable infrastructure.""";
}
