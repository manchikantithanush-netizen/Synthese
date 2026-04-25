import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthese/update_reminder.dart';

class UpdateReminderService {
  static const String _prefKey = 'last_seen_version';

  /// Call this once after the first frame on the dashboard.
  /// Shows a bottom sheet if the version in update_reminder.dart
  /// is newer than the last version the user saw.
  static Future<void> checkAndNotify(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_prefKey);

    if (lastSeen == UpdateReminder.currentVersion) return;

    // Mark as seen immediately so it only shows once.
    await prefs.setString(_prefKey, UpdateReminder.currentVersion);

    if (!context.mounted) return;

    _showUpdateSheet(context);
  }

  static void _showUpdateSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;

    const message = UpdateReminder.updateMessage;
    const threshold = 120;
    final isLong = message.length > threshold;
    final preview = isLong
        ? '${message.substring(0, threshold).trimRight()}…'
        : message;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          "What's New in ${UpdateReminder.currentVersion}",
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(preview, style: TextStyle(color: mutedText)),
            if (isLong) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullNotes(context);
                },
                child: Text(
                  'See more',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static void _showFullNotes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.93,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's New",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${UpdateReminder.currentVersion}',
                      style: TextStyle(color: mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      UpdateReminder.updateMessage,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
