import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone pedometer / step counter with two modes:
///
///  * **Background** — counts steps all day (rest/walk/run) from the device's
///    always-on hardware step counter, reconciled whenever the app opens or
///    resumes. Controlled by the [backgroundEnabled] toggle in Settings.
///  * **Workout** — counts steps recorded during an active (foot-based) workout
///    via [startWorkout] / [stopWorkout]. These always count toward the day,
///    even when background tracking is off.
///
/// The Android `TYPE_STEP_COUNTER` sensor is cumulative-since-boot and keeps
/// counting while the app is closed, so today's step total is derived from a
/// stored baseline (the cumulative value at the start of today) rather than a
/// running tally we own. This makes the count survive app restarts and reboots.
///
/// Singleton, following the app's service convention
/// (see [AppNotificationsService] / [AccentColor]).
class StepTracker {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _kBackgroundEnabled = 'step_background_enabled';
  static const String _kBaselineDate = 'step_baseline_date';
  static const String _kBaselineCumulative = 'step_baseline_cumulative';
  static const String _kLastCumulative = 'step_last_cumulative';
  static const String _kSensorToday = 'step_sensor_today';
  static const String _kWorkoutToday = 'step_workout_today';
  static const String _kHourly = 'step_hourly_today';
  static const String _kMilestoneNotifications =
      'step_milestone_notifications_enabled';

  /// Whether passive all-day background counting is enabled. Defaults to true.
  final ValueNotifier<bool> backgroundEnabled = ValueNotifier<bool>(true);

  /// Whether step-milestone notifications (1k / 5k / goal) are enabled. Only
  /// has an effect while [backgroundEnabled] is also on. Defaults to true.
  final ValueNotifier<bool> milestoneNotificationsEnabled =
      ValueNotifier<bool>(true);

  /// Today's automatic step count (does NOT include the dashboard's manual
  /// step adjustments — those are added on top by the dashboard):
  ///  * background ON  → sensor steps since midnight.
  ///  * background OFF → steps recorded during today's workouts only.
  final ValueNotifier<int> todaySteps = ValueNotifier<int>(0);

  /// Live step count for the currently active workout (0 when none active).
  final ValueNotifier<int> currentWorkoutSteps = ValueNotifier<int>(0);

  // ── internal state ────────────────────────────────────────────────────────
  SharedPreferences? _prefs;
  StreamSubscription<StepCount>? _sub;
  bool _initialized = false;

  String _baselineDate = '';
  int _baselineCumulative = -1; // -1 = not yet established for the day
  int _sensorToday = 0;
  int _workoutToday = 0;
  final List<int> _hourly = List<int>.filled(24, 0);

  bool _workoutActive = false;
  int _workoutStartCumulative = -1;
  int _lastCumulative = -1;

  /// Today's per-hour step distribution (24 buckets). Best-effort: exact while
  /// the app is open; steps taken while it was closed land in the resume hour.
  List<int> get hourlyToday => List<int>.unmodifiable(_hourly);

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _prefs = await SharedPreferences.getInstance();

    backgroundEnabled.value = _prefs!.getBool(_kBackgroundEnabled) ?? false;
    milestoneNotificationsEnabled.value =
        _prefs!.getBool(_kMilestoneNotifications) ?? true;
    _baselineDate = _prefs!.getString(_kBaselineDate) ?? '';
    _baselineCumulative = _prefs!.getInt(_kBaselineCumulative) ?? -1;
    _lastCumulative = _prefs!.getInt(_kLastCumulative) ?? -1;
    _sensorToday = _prefs!.getInt(_kSensorToday) ?? 0;
    _workoutToday = _prefs!.getInt(_kWorkoutToday) ?? 0;
    final hourlyRaw = _prefs!.getStringList(_kHourly);
    if (hourlyRaw != null && hourlyRaw.length == 24) {
      for (var i = 0; i < 24; i++) {
        _hourly[i] = int.tryParse(hourlyRaw[i]) ?? 0;
      }
    }

    // Reset per-day accumulators if the stored day isn't today.
    _rolloverIfNeeded(persist: false);

    // If we have a last-known cumulative and a valid baseline, recompute
    // _sensorToday immediately on cold start — same logic as reconcile().
    if (_lastCumulative >= 0 && _baselineCumulative >= 0 && backgroundEnabled.value) {
      var computed = _lastCumulative - _baselineCumulative;
      if (computed < 0) computed = 0;
      if (computed > _sensorToday) {
        _sensorToday = computed;
      }
    }

    _publishToday();

    if (backgroundEnabled.value) {
      _startListening();
    }
  }

  /// Reset per-day counters when the calendar day has changed.
  void _rolloverIfNeeded({required bool persist}) {
    final today = _dateKey(DateTime.now());
    if (_baselineDate != today) {
      _baselineDate = today;
      _baselineCumulative = -1; // re-established on the next sensor event
      _sensorToday = 0;
      _workoutToday = 0;
      for (var i = 0; i < 24; i++) {
        _hourly[i] = 0;
      }
      if (persist) _persist();
    }
  }

  void _startListening() {
    if (_sub != null) return;
    _sub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object e) => debugPrint('StepTracker pedometer error: $e'),
      cancelOnError: false,
    );
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  /// Re-subscribe to the sensor — used after the activity-recognition
  /// permission is granted, since a subscription created beforehand may never
  /// receive events.
  void _restartListening() {
    _stopListening();
    _startListening();
  }

  void _onStepCount(StepCount event) {
    final cumulative = event.steps;
    _lastCumulative = cumulative;
    _rolloverIfNeeded(persist: true);

    // Establish or repair the baseline so today's count is preserved.
    if (_baselineCumulative < 0) {
      // First reading today — anchor so today starts at our restored value.
      _baselineCumulative = cumulative - _sensorToday;
    } else if (cumulative < _baselineCumulative) {
      // Device rebooted: the hardware counter reset toward zero.
      _baselineCumulative = cumulative - _sensorToday;
    }
    if (_baselineCumulative < 0) _baselineCumulative = cumulative;

    var newSensorToday = cumulative - _baselineCumulative;
    if (newSensorToday < 0) newSensorToday = 0;

    final delta = newSensorToday - _sensorToday;
    if (delta > 0) {
      final hour = DateTime.now().hour;
      _hourly[hour >= 0 && hour <= 23 ? hour : 0] += delta;
    }
    _sensorToday = newSensorToday;

    if (_workoutActive) {
      if (_workoutStartCumulative < 0) _workoutStartCumulative = cumulative;
      final ws = cumulative - _workoutStartCumulative;
      currentWorkoutSteps.value = ws < 0 ? 0 : ws;
    }

    _persist();
    _publishToday();
  }

  void _publishToday() {
    todaySteps.value = backgroundEnabled.value ? _sensorToday : _workoutToday;
  }

  void _persist() {
    final p = _prefs;
    if (p == null) return;
    p.setString(_kBaselineDate, _baselineDate);
    p.setInt(_kBaselineCumulative, _baselineCumulative);
    if (_lastCumulative >= 0) p.setInt(_kLastCumulative, _lastCumulative);
    p.setInt(_kSensorToday, _sensorToday);
    p.setInt(_kWorkoutToday, _workoutToday);
    p.setStringList(_kHourly, _hourly.map((e) => e.toString()).toList());
  }

  /// Call when the app resumes so the day's total catches up after the app was
  /// backgrounded/closed. Handles day rollover immediately; uses the last
  /// persisted cumulative sensor value to compute today's steps without
  /// waiting for the next sensor event (fixes the "shows 0 on open" bug).
  void reconcile() {
    _rolloverIfNeeded(persist: true);

    // If we have a last-known cumulative value and a valid baseline, recompute
    // _sensorToday immediately so the UI shows the correct count before the
    // next step event arrives. This is the key fix for background step tracking:
    // the hardware counter kept incrementing while the app was closed, and we
    // can derive today's count from the last persisted cumulative.
    if (_lastCumulative >= 0 && _baselineCumulative >= 0 && backgroundEnabled.value) {
      var computed = _lastCumulative - _baselineCumulative;
      if (computed < 0) computed = 0;
      if (computed > _sensorToday) {
        // Only update forward — never regress the count.
        final delta = computed - _sensorToday;
        if (delta > 0) {
          final hour = DateTime.now().hour;
          _hourly[hour >= 0 && hour <= 23 ? hour : 0] += delta;
        }
        _sensorToday = computed;
        _persist();
      }
    }

    if (backgroundEnabled.value) {
      _startListening(); // no-op if already listening
    }
    _publishToday();
  }

  Future<bool> isPermissionGranted() =>
      Permission.activityRecognition.isGranted;

  /// Request the activity-recognition permission (Android). Returns whether it
  /// is granted afterwards, and (re)starts the sensor when appropriate.
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    final granted = status.isGranted;
    if (granted) {
      // Explicitly enable background tracking now that permission is granted
      // and persist the preference so the green dot stays correct on restart.
      await setBackgroundEnabled(true);
    }
    return granted;
  }

  /// Enable/disable passive all-day background tracking (the Settings toggle).
  Future<void> setBackgroundEnabled(bool enabled) async {
    backgroundEnabled.value = enabled;
    await _prefs?.setBool(_kBackgroundEnabled, enabled);
    if (enabled) {
      _restartListening();
    } else if (!_workoutActive) {
      _stopListening();
    }
    _publishToday();
  }

  /// Enable/disable step-milestone notifications (1k / 5k / goal). Only has an
  /// effect while [backgroundEnabled] is also on; the native foreground service
  /// is started/stopped from the dashboard in response to this flag.
  Future<void> setMilestoneNotificationsEnabled(bool enabled) async {
    milestoneNotificationsEnabled.value = enabled;
    await _prefs?.setBool(_kMilestoneNotifications, enabled);
  }

  /// Begin counting steps for a workout. The caller is responsible for only
  /// calling this for foot-based modes (running / trail run / walking).
  void startWorkout() {
    _workoutActive = true;
    _workoutStartCumulative = _lastCumulative >= 0 ? _lastCumulative : -1;
    currentWorkoutSteps.value = 0;
    // Make sure the sensor is running even if background tracking is off.
    _startListening();
  }

  /// Stop the active workout and return the steps recorded during it. Those
  /// steps are added to today's workout total so they count toward the day even
  /// when background tracking is off.
  int stopWorkout() {
    final steps = currentWorkoutSteps.value;
    _workoutActive = false;
    _workoutStartCumulative = -1;
    currentWorkoutSteps.value = 0;
    if (steps > 0) {
      _rolloverIfNeeded(persist: true);
      _workoutToday += steps;
      _persist();
    }
    // Stop the sensor again if it was only running for this workout.
    if (!backgroundEnabled.value) {
      _stopListening();
    }
    _publishToday();
    return steps;
  }
}
