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
  static const String currentVersion = '1.6.0+10';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.6.0+10 introduces a powerful expansion to your health tracking experience, with a strong focus on deeper insights and clearer data visualization. This update brings a fully redesigned heart rate detailed view, now featuring a daily plot graph, weekly bar graph, heart rate zones, and clear tracking of your lowest and highest heart rate values, giving you a much better understanding of your cardiovascular activity.

We’ve also enhanced the dashboard with a new calorie overview that clearly displays burned, eaten, and net calories in one place, making it easier to track your daily balance at a glance.

The calorie detailed view has been significantly upgraded with a new ring-style burned calorie tracker, a full calorie balance breakdown with individual graphs, and a calorie heatmap to visualize your patterns over time. These additions provide a more complete and intuitive way to monitor your energy intake and expenditure.

Overall, this update focuses on turning raw data into meaningful insights, helping you stay more aware, consistent, and in control of your health.""";
}
