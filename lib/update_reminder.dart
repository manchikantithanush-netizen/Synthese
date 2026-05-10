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
static const String updateMessage = """Version 1.8.0+12 brings a major refinement to your health tracking experience, focusing on simplicity, clarity, and stability.

The dashboard has been streamlined by removing manual adjustment controls and percentage comparisons, replacing them with a cleaner layout and a new “Tap to Explore” prompt that guides you into detailed metric views.

You can now log your own data easily using the new “+ Add Data” option available across all metrics, giving you full control over your tracking.

Sleep tracking has been improved with the addition of a new “Asleep” phase, along with fixes to the sleep chart, which now works smoothly even without external data sources.

To improve reliability, Health Connect has been temporarily removed and will return later with a more stable implementation. All data is currently managed manually to ensure consistency.

This update also includes multiple bug fixes and enhancements, including improved graph behavior, dynamic goal adjustments, better data syncing, and a smoother loading experience.

Overall, this version marks the completion of the dashboard with a more polished, stable, and user-friendly experience.""";
}
