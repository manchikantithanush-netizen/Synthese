import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationsService {
  AppNotificationsService._();

  static final AppNotificationsService instance = AppNotificationsService._();
  static const String _defaultChannelId = 'synthese_general_notifications';
  static const String _defaultChannelName = 'Synthese updates';
  static const String _defaultChannelDescription =
      'Health, wellness and finance reminders.';
  static const String _metaPrefix = 'notif_meta_';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        description: _defaultChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    _initialized = true;
  }

  Future<void> show({
    required String uniqueKey,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      _idFromKey(uniqueKey),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showOncePerDay({
    required String uniqueKey,
    required String title,
    required String body,
    DateTime? now,
  }) async {
    final marker = _dateMarker(now ?? DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final metaKey = '$_metaPrefix$uniqueKey';
    final last = prefs.getString(metaKey);
    if (last == marker) return;
    await show(uniqueKey: uniqueKey, title: title, body: body);
    await prefs.setString(metaKey, marker);
  }

  Future<void> showWithCooldown({
    required String uniqueKey,
    required String title,
    required String body,
    required Duration cooldown,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final metaKey = '$_metaPrefix$uniqueKey';
    final lastRaw = prefs.getString(metaKey);
    if (lastRaw != null) {
      final last = DateTime.tryParse(lastRaw);
      if (last != null && current.difference(last) < cooldown) return;
    }
    await show(uniqueKey: uniqueKey, title: title, body: body);
    await prefs.setString(metaKey, current.toIso8601String());
  }

  Future<void> markOnce({
    required String uniqueKey,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_metaPrefix$uniqueKey',
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<bool> hasMarked(String uniqueKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_metaPrefix$uniqueKey');
  }

  int _idFromKey(String key) {
    final raw = key.hashCode;
    if (raw == 0) return 1;
    return raw.isNegative ? -raw : raw;
  }

  String _dateMarker(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

void debugNotification(String message) {
  debugPrint('[AppNotifications] $message');
}
