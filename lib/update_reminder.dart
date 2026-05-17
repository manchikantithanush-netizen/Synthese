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
  static const String currentVersion = '1.10.0+14';

  /// What to show the user when they open the app on this version for the first time.
  static const String updateMessage = """Version 1.10.14: New features, To save the time of testers we added guest account option, which with one click the tester can go to the onboarding without needing to sign in, Also in the account page we added a button to donate to the project, which will open the browser and take you to our open collective page, where you can choose to donate any amount you want, and also see how much we have raised so far, and how much we need to reach our goal.""";
}
