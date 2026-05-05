import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests app permissions once on first app launch.
class FirstLaunchPermissionsService {
  static const String _firstRunPermissionsAskedKey =
      'first_run_permissions_asked_v1';

  Future<void> requestAllPermissionsIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_firstRunPermissionsAskedKey) ?? false;
    if (alreadyAsked) return;
    try {
      if (Platform.isAndroid) {
        await Permission.notification.request();
        await Permission.location.request();
        await Permission.activityRecognition.request();
        await Permission.camera.request();
        await Permission.photos.request();
      } else if (Platform.isIOS) {
        await Permission.notification.request();
        await Permission.camera.request();
        await Permission.photos.request();
      }
    } catch (_) {
    } finally {
      await prefs.setBool(_firstRunPermissionsAskedKey, true);
    }
  }

  Future<void> requestNotification() async {
    try { await Permission.notification.request(); } catch (_) {}
  }

  Future<void> requestLocation() async {
    try { await Permission.location.request(); } catch (_) {}
  }

  Future<void> requestActivityRecognition() async {
    if (!Platform.isAndroid) return;
    try { await Permission.activityRecognition.request(); } catch (_) {}
  }

  Future<void> requestCamera() async {
    try { await Permission.camera.request(); } catch (_) {}
  }

  Future<void> requestPhotos() async {
    try { await Permission.photos.request(); } catch (_) {}
  }

  Future<void> markAllAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunPermissionsAskedKey, true);
  }
}
