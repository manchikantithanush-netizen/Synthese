import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synthese/services/health_connect_service.dart';

/// Requests app permissions once on first app launch.
///
/// Behavior:
/// - On first run, asks for all major permissions up front.
/// - If user denies, we still mark "first-run ask completed" so we don't
///   auto-prompt again on later launches.
/// - Feature screens can still request again when user actively uses them.
class FirstLaunchPermissionsService {
  static const String _firstRunPermissionsAskedKey =
      'first_run_permissions_asked_v1';
  static const String _healthConnectWarningShownKey =
      'health_connect_warning_shown_v1';

  final HealthConnectService _healthConnectService;

  FirstLaunchPermissionsService({HealthConnectService? healthConnectService})
    : _healthConnectService = healthConnectService ?? HealthConnectService();

  Future<bool> shouldShowHealthConnectWarning() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_healthConnectWarningShownKey) ?? false);
  }

  Future<void> markHealthConnectWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_healthConnectWarningShownKey, true);
  }

  Future<void> requestAllPermissionsIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_firstRunPermissionsAskedKey) ?? false;
    if (alreadyAsked) {
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Notifications
        await Permission.notification.request();

        // Location + activity recognition
        await Permission.location.request();
        await Permission.activityRecognition.request();

        // Camera + photo/media access
        await Permission.camera.request();
        await Permission.photos.request();

        // Health Connect read permissions
        await _healthConnectService.initializeAndEnsureReadPermissions();
      } else if (Platform.isIOS) {
        // Keep iOS lightweight in this app for now.
        await Permission.notification.request();
        await Permission.camera.request();
        await Permission.photos.request();
      }
    } catch (_) {
      // Best-effort bootstrap: intentionally ignore and continue.
    } finally {
      // Mark first-run permission ask complete regardless of grant/deny.
      await prefs.setBool(_firstRunPermissionsAskedKey, true);
    }
  }
}

