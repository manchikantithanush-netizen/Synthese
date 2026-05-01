import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';

import 'package:synthese/ui/account/accountpage.dart';
import 'package:synthese/ui/components/app_toast.dart';
import 'package:synthese/cycles/cycles.dart';
import 'package:synthese/finance/finance.dart';
import 'package:synthese/mindfulness/mindfulness_page.dart';
import 'package:synthese/mindfulness/mindfulness_onboarding.dart';
import 'package:synthese/diet/diet_page.dart';
import 'package:synthese/ui/workout.dart';
import 'package:synthese/ui/more.dart';
import 'package:synthese/ui/components/universalbottomnavbar.dart';
import 'package:synthese/services/health_connect_service.dart';
import 'package:synthese/services/first_launch_permissions_service.dart';
import 'package:synthese/services/home_widget_service.dart';
import 'package:synthese/services/data_aggregation_service.dart';
import 'package:synthese/services/notification_rules_engine.dart';
import 'package:health/health.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/services/update_reminder_service.dart';
import 'package:synthese/ui/steps_detail_page.dart';
import 'package:synthese/ui/heart_rate_detail_page.dart';
import 'package:synthese/ui/calories_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const Duration _kTabSwitchDuration = Duration(milliseconds: 320);

  late final AnimationController _workoutTabEnterController;
  late final Animation<double> _workoutTabEnterOpacity;
  late final Animation<Offset> _workoutTabEnterSlide;
  // --- STATE VARIABLES ---
  late int _score;
  int _tabIndex = 0;
  bool _isModalOpen = false;

  // Track if user is female to show the Cycles tab
  bool _isFemale = false;

  // Mindfulness onboarding completion
  bool _mindfulnessOnboardingComplete = false;

  // Track if user has uploaded at least once
  bool _hasUploadedOnce = false;
  // Cached profile photo URL for header avatar
  String? _profilePhotoUrl;

  // Current values - completely zeroed out for new logins
  int _activeCalories = 0;
  int _heartRate = 0;
  int _steps = 0;
  int _exerciseMinutes = 0;
  int _eatenCalories = 0; // from diet logs via dailyAgg — live stream
  StreamSubscription<DocumentSnapshot>? _dailyAggSub;
  List<int> _sleepData = [0, 0, 0, 0, 0, 0, 0];
  // Heart rate history for the graph — timestamped readings
  final List<({int bpm, DateTime time})> _hrHistory = [];
  // Exercise minutes per day for the last 7 days (today = last entry)
  final List<int> _exHistory = List.filled(7, 0);
  // Hourly steps for today (index = hour 0–23)
  final List<int> _hourlySteps = List.filled(24, 0);
  int _lastWorkoutCaloriesReported = 0;
  int _lastWorkoutMinutesReported = 0;
  bool _keepWorkoutAlive = false;
  late final WorkoutPage _workoutPage;
  final HealthConnectService _healthConnectService = HealthConnectService();
  final FirstLaunchPermissionsService _firstLaunchPermissionsService =
      FirstLaunchPermissionsService();
  bool _hasAttemptedHealthConnect = false;
  DateTime? _lastHealthConnectRefreshAt;
  Timer? _metricsPersistDebounce;
  Timer? _notificationRulesTimer;
  bool _isWorkoutModeOpen = false;

  // Previous values (for comparisons)
  int? _prevActiveCalories;
  int? _prevHeartRate;
  int? _prevSteps;
  int? _prevExerciseMinutes;
  List<int>? _prevSleepData;

  // Goal-reached flags — reset when app restarts, not on every metric update
  bool _stepsGoalToasted = false;
  bool _caloriesGoalToasted = false;

  @override
  void initState() {
    super.initState();
    _workoutTabEnterController = AnimationController(
      vsync: this,
      duration: _kTabSwitchDuration,
    );
    _workoutTabEnterOpacity = CurvedAnimation(
      parent: _workoutTabEnterController,
      curve: Curves.easeOutCubic,
    );
    _workoutTabEnterSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(_workoutTabEnterOpacity);
    WidgetsBinding.instance.addObserver(this);
    _workoutPage = WorkoutPage(
      onMetricsChanged: _handleWorkoutMetricsChanged,
      onTrackingBaselineCleared: _handleWorkoutTrackingBaselineCleared,
      onWorkoutModeChanged: (isOpen) {
        if (!mounted) return;
        setState(() {
          _isWorkoutModeOpen = isOpen;
        });
      },
    );
    _updateScore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showFirstLaunchHealthConnectWarningIfNeeded());
      UpdateReminderService.checkAndNotify(context);
    });
    unawaited(_bootstrapDashboardMetrics());
    _fetchUserGender();
    _fetchUserProfile();
    _fetchMindfulnessOnboarding();
    unawaited(_fetchEatenCalories());
    _listenEatenCalories();
    unawaited(_firstLaunchPermissionsService.requestAllPermissionsIfFirstLaunch());
    unawaited(NotificationRulesEngine.evaluateGlobal());
    _notificationRulesTimer = Timer.periodic(const Duration(hours: 3), (_) {
      unawaited(NotificationRulesEngine.evaluateGlobal());
    });
  }

  /// Loads saved daily totals first, then merges Health Connect so in-app
  /// workout calories are not overwritten by a racing HC refresh.
  Future<void> _bootstrapDashboardMetrics() async {
    await _loadPersistedDashboardMetrics();
    if (!mounted) return;
    await _refreshMetricsFromHealthConnect();
  }

  Future<void> _showFirstLaunchHealthConnectWarningIfNeeded() async {
    if (!Platform.isAndroid) {
      return;
    }

    final shouldShow =
        await _firstLaunchPermissionsService.shouldShowHealthConnectWarning();
    if (!shouldShow || !mounted) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          'Health Connect Required for Wearables',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'To sync metrics from devices like Samsung Band/Galaxy Watch, this app needs Google Health Connect. '
          'If Health Connect is not installed or not permitted, wearable health metrics will not sync.',
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );

    await _firstLaunchPermissionsService.markHealthConnectWarningShown();
  }

  @override
  void dispose() {
    _workoutTabEnterController.dispose();
    _metricsPersistDebounce?.cancel();
    _notificationRulesTimer?.cancel();
    _dailyAggSub?.cancel();
    unawaited(_persistDashboardMetricsNow());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshMetricsFromHealthConnect(force: true));
      unawaited(NotificationRulesEngine.evaluateGlobal());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_persistDashboardMetricsNow());
    }
  }

  DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _loadPersistedDashboardMetrics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final dayKey = _dateKey(DateTime.now());
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .get();

      final data = doc.data();
      if (data == null || !mounted) return;

      final loadedSleep = (data['sleepData'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList();

      final loadedExHistory = (data['exHistory'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList();

      final loadedHrHistory = (data['hrHistory'] as List<dynamic>?)
          ?.map((e) {
            final bpm = (e['bpm'] as num?)?.toInt() ?? 0;
            final ts = (e['time'] as Timestamp?)?.toDate() ?? DateTime.now();
            return (bpm: bpm, time: ts);
          })
          .toList();

      setState(() {
        _activeCalories = (data['activeCalories'] as num?)?.toInt() ?? _activeCalories;
        _heartRate = (data['heartRate'] as num?)?.toInt() ?? _heartRate;
        _steps = (data['steps'] as num?)?.toInt() ?? _steps;
        _exerciseMinutes =
            (data['exerciseMinutes'] as num?)?.toInt() ?? _exerciseMinutes;
        if (loadedSleep != null && loadedSleep.length == 7) {
          _sleepData = loadedSleep;
        }
        if (loadedExHistory != null && loadedExHistory.length == 7) {
          _exHistory.setAll(0, loadedExHistory);
        } else {
          // Sync today's slot if no history
          final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
          _exHistory[todayIdx] = _exerciseMinutes;
        }
        if (loadedHrHistory != null) {
          _hrHistory.clear();
          _hrHistory.addAll(loadedHrHistory);
        }
        _hasUploadedOnce = (data['hasUploadedOnce'] as bool?) ?? _hasUploadedOnce;
        _lastWorkoutCaloriesReported =
            (data['lastWorkoutCaloriesReported'] as num?)?.toInt() ??
            _lastWorkoutCaloriesReported;
        _lastWorkoutMinutesReported =
            (data['lastWorkoutMinutesReported'] as num?)?.toInt() ??
            _lastWorkoutMinutesReported;
        _updateScore();
      });
      _syncDashboardWidgets();
    } catch (e) {
      debugPrint('Error loading persisted dashboard metrics: $e');
    }
  }

  void _schedulePersistDashboardMetrics() {
    _metricsPersistDebounce?.cancel();
    _metricsPersistDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_persistDashboardMetricsNow());
    });
  }

  void _syncDashboardWidgets() {
    unawaited(
      HomeWidgetService.updateDashboardMetrics(
        steps: _steps,
        heartRate: _heartRate,
        activeCalories: _activeCalories,
        exerciseMinutes: _exerciseMinutes,
      ),
    );
  }

  Future<void> _persistDashboardMetricsNow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final dayKey = _dateKey(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .set({
            'activeCalories': _activeCalories,
            'heartRate': _heartRate,
            'steps': _steps,
            'exerciseMinutes': _exerciseMinutes,
            'sleepData': _sleepData,
            'exHistory': _exHistory,
            'hrHistory': _hrHistory.map((r) => {
              'bpm': r.bpm,
              'time': Timestamp.fromDate(r.time),
            }).toList(),
            'hasUploadedOnce': _hasUploadedOnce,
            'lastWorkoutCaloriesReported': _lastWorkoutCaloriesReported,
            'lastWorkoutMinutesReported': _lastWorkoutMinutesReported,
            'updatedAt': FieldValue.serverTimestamp(),
            'dateKey': dayKey,
          }, SetOptions(merge: true));
      await DataAggregationService.updateDashboardSnapshot(
        uid: uid,
        when: DateTime.now(),
        steps: _steps,
        activeCalories: _activeCalories,
      );
    } catch (e) {
      debugPrint('Error persisting dashboard metrics: $e');
    }
  }

  int _minutesBetween(DateTime from, DateTime to) =>
      to.difference(from).inMinutes.clamp(0, 1000000);

  int _asInt(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.round();
    }
    return 0;
  }

  Future<void> _refreshMetricsFromHealthConnect({bool force = false}) async {
    final now = DateTime.now();
    final last = _lastHealthConnectRefreshAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastHealthConnectRefreshAt = now;

    if (_hasAttemptedHealthConnect && !force) {
      return;
    }
    _hasAttemptedHealthConnect = true;

    final status =
        await _healthConnectService.initializeAndEnsureReadPermissions();
    if (status != HealthConnectStatus.ready) {
      // No UI here (by request). Just leave existing metrics as-is.
      debugPrint('Health Connect not ready: $status');
      return;
    }

    final todayStart = _midnight(now);
    final rollingSleepStart = todayStart.subtract(const Duration(days: 6));
    final fetch = await _healthConnectService.fetchPast7Days();
    if (!fetch.ok) {
      debugPrint('Health Connect fetch failed: ${fetch.status} ${fetch.error}');
      return;
    }

    final points = fetch.points;

    // Steps today (matches what users expect from Toolbox testing).
    final int stepsToday = points
        .where((p) => p.type == HealthDataType.STEPS)
        .where((p) => !p.dateTo.isBefore(todayStart) && !p.dateFrom.isAfter(now))
        .fold<int>(0, (acc, p) => acc + _asInt(p.value));

    // Hourly steps today
    final List<int> hourlySteps = List.filled(24, 0);
    for (final p in points.where((p) => p.type == HealthDataType.STEPS)) {
      if (p.dateTo.isBefore(todayStart) || p.dateFrom.isAfter(now)) continue;
      final hour = p.dateFrom.hour.clamp(0, 23);
      hourlySteps[hour] += _asInt(p.value);
    }

    // Latest heart rate sample (today).
    final hrPoints = points
        .where((p) => p.type == HealthDataType.HEART_RATE)
        .where((p) => !p.dateTo.isBefore(todayStart) && !p.dateFrom.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final int latestHr = hrPoints.isEmpty ? 0 : _asInt(hrPoints.last.value);

    // Active calories today.
    final int activeCaloriesToday = points
        .where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED)
        .where((p) => !p.dateTo.isBefore(todayStart) && !p.dateFrom.isAfter(now))
        .fold<int>(0, (acc, p) => acc + _asInt(p.value));

    // Workout minutes today.
    final int workoutMinutesToday = points
        .where((p) => p.type == HealthDataType.WORKOUT)
        .where((p) => !p.dateTo.isBefore(todayStart) && !p.dateFrom.isAfter(now))
        .fold<int>(0, (acc, p) => acc + _minutesBetween(p.dateFrom, p.dateTo));

    // Sleep minutes per day for the last 7 calendar days (Mon..Sun slots).
    final List<int> sleepByWeekday = List<int>.filled(7, 0);
    final Map<DateTime, int> sleepByDate = <DateTime, int>{};
    for (var i = 0; i < 7; i++) {
      final day = _midnight(rollingSleepStart.add(Duration(days: i)));
      sleepByDate[day] = 0;
    }

    for (final p in points.where((p) => p.type == HealthDataType.SLEEP_SESSION)) {
      var segmentStart = p.dateFrom;
      var segmentEnd = p.dateTo;
      if (segmentEnd.isBefore(rollingSleepStart) || segmentStart.isAfter(now)) {
        continue;
      }
      if (segmentStart.isBefore(rollingSleepStart)) {
        segmentStart = rollingSleepStart;
      }
      if (segmentEnd.isAfter(now)) {
        segmentEnd = now;
      }
      if (!segmentEnd.isAfter(segmentStart)) {
        continue;
      }

      var cursor = segmentStart;
      while (cursor.isBefore(segmentEnd)) {
        final dayStart = _midnight(cursor);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final chunkEnd = segmentEnd.isBefore(dayEnd) ? segmentEnd : dayEnd;
        final chunkMinutes = chunkEnd.difference(cursor).inMinutes;
        if (chunkMinutes > 0 && sleepByDate.containsKey(dayStart)) {
          sleepByDate[dayStart] = (sleepByDate[dayStart] ?? 0) + chunkMinutes;
        }
        cursor = chunkEnd;
      }
    }

    for (final entry in sleepByDate.entries) {
      final idx = (entry.key.weekday - 1).clamp(0, 6);
      sleepByWeekday[idx] = entry.value;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      // Preserve trend history if user already had data.
      if (_hasUploadedOnce) {
        _prevActiveCalories = _activeCalories;
        _prevHeartRate = _heartRate;
        _prevSteps = _steps;
        _prevExerciseMinutes = _exerciseMinutes;
        _prevSleepData = List<int>.from(_sleepData);
      } else {
        _hasUploadedOnce = true;
      }

      _steps = math.max(_steps, stepsToday);
      for (int h = 0; h < 24; h++) {
        _hourlySteps[h] = math.max(_hourlySteps[h], hourlySteps[h]);
      }
      _heartRate = latestHr;      if (latestHr > 0) {
        _hrHistory.add((bpm: latestHr, time: DateTime.now()));
      }
      _activeCalories = math.max(_activeCalories, activeCaloriesToday);
      _exerciseMinutes = math.max(_exerciseMinutes, workoutMinutesToday);
      final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
      _exHistory[todayIdx] = _exerciseMinutes;
      _sleepData = List<int>.generate(
        7,
        (i) => math.max(_sleepData[i], sleepByWeekday[i]),
      );
      _updateScore();
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  // --- FETCH USER DATA ---
  Future<void> _fetchUserGender() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['gender'] == 'Female') {
            if (mounted) {
              setState(() => _isFemale = true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // Fallback to auth profile photo if available
        final authUrl = FirebaseAuth.instance.currentUser?.photoURL;
        if (mounted) setState(() => _profilePhotoUrl = authUrl);
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        final photo = data?['photoURL'] as String?;
        final authUrl = FirebaseAuth.instance.currentUser?.photoURL;
        if (mounted) setState(() => _profilePhotoUrl = photo ?? authUrl);
      } else if (mounted) {
        final authUrl = FirebaseAuth.instance.currentUser?.photoURL;
        setState(() => _profilePhotoUrl = authUrl);
      }
    } catch (e) {
      debugPrint('Error fetching profile photo: $e');
    }
  }

  Future<void> _fetchMindfulnessOnboarding() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final completed =
              data?['mindfulnessOnboardingCompleted'] as bool? ?? false;
          if (mounted && completed) {
            setState(() => _mindfulnessOnboardingComplete = true);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching mindfulness onboarding status: $e");
    }
  }

  Future<void> _fetchEatenCalories() async {
    // Initial fast load before stream fires
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final dayKey = _dateKey(DateTime.now());
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dailyAgg')
          .doc(dayKey)
          .get();
      final cal = (doc.data()?['caloriesLogged'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _eatenCalories = cal);
    } catch (_) {}
  }

  void _listenEatenCalories() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final dayKey = _dateKey(DateTime.now());
    _dailyAggSub?.cancel();
    _dailyAggSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyAgg')
        .doc(dayKey)
        .snapshots()
        .listen((snap) {
      final cal = (snap.data()?['caloriesLogged'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _eatenCalories = cal);
    });
  }

  // --- HEALTH SCORE CALCULATOR ---

  void _updateScore() {
    double avgSleepMinutes = _sleepData.reduce((a, b) => a + b) / 7.0;

    double stepsScore = math.min(_steps / 10000.0, 1.0) * 100.0;
    double calScore = math.min(_activeCalories / 500.0, 1.0) * 100.0;
    double exerciseScore = math.min(_exerciseMinutes / 60.0, 1.0) * 100.0;
    double sleepScore = math.min(avgSleepMinutes / 480.0, 1.0) * 100.0;

    double healthScore =
        (stepsScore * 0.25) +
        (calScore * 0.25) +
        (exerciseScore * 0.25) +
        (sleepScore * 0.25);

    _score = healthScore.round();

    // Goal-reached toasts — fire only once per session per goal
    if (mounted && context.mounted) {
      if (!_stepsGoalToasted && _steps >= 10000) {
        _stepsGoalToasted = true;
        AppToast.success(context, 'Steps goal reached! 10,000 steps 🎉', icon: Icons.directions_walk_rounded);
      }
      if (!_caloriesGoalToasted && _activeCalories >= 500) {
        _caloriesGoalToasted = true;
        AppToast.success(context, 'Calories burned goal reached! 500 kcal 🔥', icon: Icons.local_fire_department_rounded);
      }
    }
  }

  // --- SCORE HELPERS ---
  String _getScoreMessage(int score) {
    if (!_hasUploadedOnce && score == 0)
      return "Upload your data to get started!";

    if (score >= 90) return "Top 5% of adults globally";
    if (score >= 75) return "Healthier than ~80% of adults";
    if (score >= 50) return "Around average for most adults";
    if (score >= 25) return "Below average — most adults score higher";
    return "In the bottom 15% — you've got room to grow";
  }

  Color _getScoreColor(int score) {
    if (!_hasUploadedOnce && score == 0) return Colors.grey;

    if (score >= 75) return const Color(0xFF4CAF50); // Green
    if (score >= 50) return const Color(0xFFFBC02D); // Yellow
    return const Color(0xFFFF4B4B); // Red
  }

  // --- NEW TREND LOGIC (REFERENCE MAX) ---
  ({String text, Color color}) _getTrend(
    int current,
    int? previous,
    double realisticMax, {
    bool isHeartRate = false,
  }) {
    if (previous == null) {
      return (text: "Not enough data yet", color: Colors.grey.withOpacity(0.5));
    }
    if (current == previous) {
      return (text: "No change", color: Colors.grey.withOpacity(0.5));
    }

    double change = isHeartRate
        ? (previous - current).toDouble()
        : (current - previous).toDouble();
    double percentage = (change / realisticMax) * 100.0;
    percentage = percentage.clamp(-100.0, 100.0);

    Color c = percentage > 0 ? const Color(0xFF4CAF50) : Colors.redAccent;
    String sign = percentage > 0 ? "+" : "";

    return (text: "$sign${percentage.toStringAsFixed(1)}%", color: c);
  }

  ({String text, Color color}) _getSleepTrend(
    List<int> currentData,
    List<int>? previousData,
  ) {
    if (previousData == null) {
      return (text: "Not enough data yet", color: Colors.grey.withOpacity(0.5));
    }

    double currentAvg = currentData.reduce((a, b) => a + b) / 7.0;
    double prevAvg = previousData.reduce((a, b) => a + b) / 7.0;

    if (currentAvg.round() == prevAvg.round()) {
      return (text: "No change", color: Colors.grey.withOpacity(0.5));
    }

    double change = currentAvg - prevAvg;
    double percentage = (change / 540.0) * 100.0;

    percentage = percentage.clamp(-100.0, 100.0);

    Color c = percentage > 0 ? const Color(0xFF4CAF50) : Colors.redAccent;
    String sign = percentage > 0 ? "+" : "";

    return (text: "$sign${percentage.toStringAsFixed(1)}%", color: c);
  }

  // --- FORMATTING HELPERS ---
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}";
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${mins}m";
    return "${mins}m";
  }


  // --- FILE PARSER ---
  Future<void> _pickTextFile() async {
    HapticFeedback.lightImpact();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        String contents = "";

        if (result.files.single.bytes != null) {
          contents = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          contents = await File(result.files.single.path!).readAsString();
        }

        if (contents.isNotEmpty) {
          _parseData(contents);
        }
      }
    } catch (e) {
      debugPrint("Error picking/reading file: $e");
    }
  }

  void _parseData(String data) {
    final lines = data.split('\n');

    int tempActive = _activeCalories;
    int tempHR = _heartRate;
    int tempSteps = _steps;
    int tempExTime = _exerciseMinutes;
    int mon = _sleepData[0], tue = _sleepData[1], wed = _sleepData[2];
    int thu = _sleepData[3],
        fri = _sleepData[4],
        sat = _sleepData[5],
        sun = _sleepData[6];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('=');

      if (parts.length >= 2) {
        final key = parts[0].trim().toLowerCase();
        final valStr = parts[1].trim();
        final val = int.tryParse(valStr) ?? 0;

        switch (key) {
          case 'activecal':
            tempActive = val;
            break;
          case 'heartrate':
            tempHR = val;
            break;
          case 'steps':
            tempSteps = val;
            break;
          case 'excersizetime':
            tempExTime = val;
            break;
          case 'sleepmon':
            mon = val;
            break;
          case 'sleeptue':
            tue = val;
            break;
          case 'sleepwed':
            wed = val;
            break;
          case 'sleepthur':
            thu = val;
            break;
          case 'sleepfri':
            fri = val;
            break;
          case 'sleepsat':
            sat = val;
            break;
          case 'sleepsun':
            sun = val;
            break;
        }
      }
    }

    setState(() {
      if (_hasUploadedOnce) {
        _prevActiveCalories = _activeCalories;
        _prevHeartRate = _heartRate;
        _prevSteps = _steps;
        _prevExerciseMinutes = _exerciseMinutes;
        _prevSleepData = List.from(_sleepData);
      } else {
        _hasUploadedOnce = true;
      }

      _activeCalories = tempActive;
      _heartRate = tempHR;
      if (tempHR > 0) {
        _hrHistory.add((bpm: tempHR, time: DateTime.now()));
      }
      _steps = tempSteps;
      _exerciseMinutes = tempExTime;
      _sleepData = [mon, tue, wed, thu, fri, sat, sun];

      _updateScore();
    });
    unawaited(
      HomeWidgetService.updateDashboardMetrics(
        steps: _steps,
        heartRate: _heartRate,
        activeCalories: _activeCalories,
        exerciseMinutes: _exerciseMinutes,
      ),
    );
    _schedulePersistDashboardMetrics();
  }

  void _showAccountBottomSheet() async {
    HapticFeedback.lightImpact();
    setState(() => _isModalOpen = true);
    await Future.delayed(const Duration(milliseconds: 150));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountPageModal(),
    );

    // Refresh header avatar after the account modal may have updated the photo.
    await _fetchUserProfile();

    if (mounted) setState(() => _isModalOpen = false);
  }

  int _getBottomNavIndex() {
    if (_tabIndex >= 4) return 3;
    return _tabIndex;
  }

  void _setBottomTab(int index) {
    final wasWorkout = _tabIndex == 2;
    final isWorkout = index == 2;
    setState(() {
      _tabIndex = index;
      if (index == 2) {
        _keepWorkoutAlive = true;
      }
    });
    if (isWorkout && !wasWorkout) {
      _workoutTabEnterController.stop();
      _workoutTabEnterController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabIndex == 2) {
          _workoutTabEnterController.forward();
        }
      });
    } else if (!isWorkout && wasWorkout) {
      _workoutTabEnterController.stop();
      _workoutTabEnterController.reset();
      _isWorkoutModeOpen = false;
    }
  }

  Widget _buildNonWorkoutTabSwitcher(Widget currentScreen) {
    return AnimatedSwitcher(
      duration: _kTabSwitchDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: currentScreen,
    );
  }

  void _adjustActiveCalories(int delta) {
    setState(() {
      _activeCalories = (_activeCalories + delta).clamp(0, 1000000).toInt();
      _hasUploadedOnce = true;
      _updateScore();
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  void _adjustHeartRate(int delta) {
    setState(() {
      _heartRate = (_heartRate + delta).clamp(0, 250).toInt();
      _hasUploadedOnce = true;
      if (_heartRate > 0) {
        _hrHistory.add((bpm: _heartRate, time: DateTime.now()));
      }
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  void _adjustSteps(int delta) {
    setState(() {
      _steps = (_steps + delta).clamp(0, 1000000).toInt();
      _hasUploadedOnce = true;
      _updateScore();
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  void _adjustSleep(int deltaMinutes) {
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    setState(() {
      _sleepData[todayIdx] =
          (_sleepData[todayIdx] + deltaMinutes).clamp(0, 1440);
      _hasUploadedOnce = true;
      _updateScore();
    });
    _schedulePersistDashboardMetrics();
  }

  void _adjustExerciseMinutes(int delta) {
    setState(() {
      _exerciseMinutes = (_exerciseMinutes + delta).clamp(0, 1000000).toInt();
      _hasUploadedOnce = true;
      _updateScore();
      // Keep today's slot (index = weekday-1) in sync
      final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
      _exHistory[todayIdx] = _exerciseMinutes;
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  void _handleWorkoutMetricsChanged(int calories, int activeMinutes) {
    final calorieDelta = math.max(0, calories - _lastWorkoutCaloriesReported);
    final minuteDelta = math.max(
      0,
      activeMinutes - _lastWorkoutMinutesReported,
    );
    if (calorieDelta == 0 && minuteDelta == 0) {
      // Do not regress the dashboard baseline when the workout tile reports
      // stable zeros (e.g. after hot restart / widget rebuild). Route reset
      // uses [onTrackingBaselineCleared] instead.
      return;
    }

    setState(() {
      _activeCalories = (_activeCalories + calorieDelta)
          .clamp(0, 1000000)
          .toInt();
      _exerciseMinutes = (_exerciseMinutes + minuteDelta)
          .clamp(0, 1000000)
          .toInt();
      _lastWorkoutCaloriesReported = calories;
      _lastWorkoutMinutesReported = activeMinutes;
      _updateScore();
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  void _handleWorkoutTrackingBaselineCleared() {
    setState(() {
      _lastWorkoutCaloriesReported = 0;
      _lastWorkoutMinutesReported = 0;
    });
    _syncDashboardWidgets();
    _schedulePersistDashboardMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    final safePadding = mediaQuery.padding;
    final isNarrowLayout = mediaQuery.size.width < 390;

    final avgSleepMinutes = _sleepData.reduce((a, b) => a + b) ~/ 7;
    final maxSleep = math.max(_sleepData.reduce(math.max), 1).toDouble();

    final calTrend = _getTrend(_activeCalories, _prevActiveCalories, 800);
    final hrTrend = _getTrend(
      _heartRate,
      _prevHeartRate,
      40,
      isHeartRate: true,
    );
    final stepTrend = _getTrend(_steps, _prevSteps, 15000);
    final exTrend = _getTrend(_exerciseMinutes, _prevExerciseMinutes, 120);
    final sleepTrend = _getSleepTrend(_sleepData, _prevSleepData);

    // --- DETERMINE WHICH PAGE TO SHOW BASED ON TAB INDEX ---
    Widget currentScreen;
    if (_tabIndex == 0) {
      // Home Tab
      currentScreen = SingleChildScrollView(
        key: const ValueKey(
          'home_tab',
        ), // The key ensures AnimatedSwitcher knows when to animate
        padding: EdgeInsets.only(
          top: safePadding.top + 24.0,
          bottom: safePadding.bottom + 120.0,
          left: 24.0,
          right: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        isDark
                            ? 'assets/logotextdarkside.png'
                            : 'assets/logotextlightside.png',
                        height: isNarrowLayout ? 36 : 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedDate(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: isNarrowLayout ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  opacity: _isModalOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: _isModalOpen,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickTextFile,
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 20,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showAccountBottomSheet,
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: (_profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL) != null
                                      ? NetworkImage((_profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL)!) as ImageProvider
                                      : null,
                                  child: (_profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL) == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 20,
                                          color: isDark ? Colors.white : Colors.black,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- ANIMATED PROGRESS RING ---
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: _score / 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return CustomPaint(
                    painter: RingPainter(
                      progress: animatedValue,
                      isDark: isDark,
                    ),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _score.toString(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 72,
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                                letterSpacing: -2,
                              ),
                            ),
                            Text(
                              "SCORE",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28.0,
                              ),
                              child: Text(
                                _getScoreMessage(_score),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _getScoreColor(_score),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // --- STEPS ---
            SizedBox(
              height: 230,
              child: MetricCard(
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                icon: Icons.directions_walk_rounded,
                iconColor: const Color(0xFF6C63FF),
                trendText: stepTrend.text,
                trendColor: stepTrend.color,
                title: "Steps",
                value: _formatNumber(_steps),
                unit: "steps",
                valueInlineUnit: true,
                compact: false,
                stepsProgress: _steps / 10000.0,
                onIncrement: () => _adjustSteps(100),
                onDecrement: () => _adjustSteps(-100),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StepsDetailPage(
                          todaySteps: _steps,
                        ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // --- HEART RATE ---
            SizedBox(
              height: 210,
              child: HeartRateCard(
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                heartRate: _heartRate,
                hrHistory: _hrHistory,
                trendText: hrTrend.text,
                trendColor: hrTrend.color,
                onIncrement: () => _adjustHeartRate(1),
                onDecrement: () => _adjustHeartRate(-1),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HeartRateDetailPage(
                      currentBpm: _heartRate,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- CALORIES ---
            SizedBox(
              height: 260,
              child: CaloriesCard(
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                activeCalories: _activeCalories,
                eatenCalories: _eatenCalories,
                trendText: calTrend.text,
                trendColor: calTrend.color,
                onIncrement: () => _adjustActiveCalories(10),
                onDecrement: () => _adjustActiveCalories(-10),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaloriesDetailPage(
                      activeCalories: _activeCalories,
                      eatenCalories: _eatenCalories,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- EXERCISE TIME ---
            SizedBox(
              height: 210,
              child: ExerciseTimeCard(
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor,
                exerciseMinutes: _exerciseMinutes,
                exHistory: _exHistory,
                trendText: exTrend.text,
                trendColor: exTrend.color,
                onIncrement: () => _adjustExerciseMinutes(1),
                onDecrement: () => _adjustExerciseMinutes(-1),
              ),
            ),

            const SizedBox(height: 16),

            // --- SLEEP ANALYSIS CARD ---
            SleepCard(
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
              sleepData: _sleepData,
              avgSleepMinutes: avgSleepMinutes,
              trendText: sleepTrend.text,
              trendColor: sleepTrend.color,
              isDark: isDark,
              onIncrement: () => _adjustSleep(30),
              onDecrement: () => _adjustSleep(-30),
            ),
          ],
        ),
      );
    } else if (_tabIndex == 3) {
      // More Tab - Show More options
      currentScreen = MorePage(
        key: const ValueKey('more_tab'),
        isFemale: _isFemale,
        onSelectTab: _setBottomTab,
      );
    } else if (_tabIndex == 2) {
      // Workout tab is rendered in an offstage stack to keep tracking alive.
      currentScreen = const SizedBox.shrink();
    } else if (_tabIndex == 1) {
      // Diet Tab - Food Tracker with AI
      currentScreen = DietPage(
        key: const ValueKey('diet_tab'),
        onModalStateChanged: (isOpen) {
          setState(() {
            _isModalOpen = isOpen;
          });
        },
      );
    } else if (_tabIndex == 4) {
      // Mindfulness Tab
      if (_mindfulnessOnboardingComplete) {
        currentScreen = MindfulnessPage(
          key: const ValueKey('mindfulness_tab'),
          onModalStateChanged: (isOpen) {
            setState(() {
              _isModalOpen = isOpen;
            });
          },
        );
      } else {
        currentScreen = MindfulnessOnboarding(
          key: const ValueKey('mindfulness_tab'),
          onContinue: () async {
            setState(() => _mindfulnessOnboardingComplete = true);
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'mindfulnessOnboardingCompleted': true});
              } catch (e) {
                debugPrint("Error saving mindfulness onboarding status: $e");
              }
            }
          },
        );
      }
    } else if (_tabIndex == 5) {
      // Finance Tab
      currentScreen = FinancePage(
        key: const ValueKey('finance_tab'),
        onModalStateChanged: (isOpen) {
          setState(() {
            _isModalOpen = isOpen;
          });
        },
      );
    } else if (_isFemale && _tabIndex == 6) {
      // Cycles Tab
      currentScreen = CyclesPage(
        key: const ValueKey('cycles_tab'),
        onModalStateChanged: (isOpen) {
          setState(() {
            _isModalOpen = isOpen;
          });
        },
      );
    } else {
      currentScreen = Container(key: ValueKey('empty_tab_$_tabIndex'));
    }

    final jakartaTheme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        Theme.of(context).textTheme,
      ),
    );

    return ValueListenableBuilder<Color>(
      valueListenable: AccentColor.notifier,
      builder: (context, accentColor, _) {
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(clampedTextScale.toDouble()),
      ),
      child: Theme(
        data: jakartaTheme,
        child: DefaultTextStyle(
          style: GoogleFonts.plusJakartaSans(),
          child: Scaffold(
            backgroundColor: bgColor,
            extendBody: true,
            bottomNavigationBar: UniversalBottomNavBar(
              hidden: _isModalOpen || (_tabIndex == 2 && _isWorkoutModeOpen),
              currentIndex: _getBottomNavIndex(),
              onTap: (index) {
                HapticFeedback.selectionClick();
                _setBottomTab(index);
              },
              items: [
                const NavItem(label: 'Home', icon: Icons.home_rounded),
                const NavItem(label: 'Diet', icon: Icons.restaurant_rounded),
                const NavItem(label: 'Workout', icon: Icons.fitness_center_rounded),
                const NavItem(label: 'More', icon: Icons.more_horiz_rounded),
              ],
            ),
            body: Stack(
              children: [
                // Accent color wash — bottommost layer, behind all content
                if (_tabIndex == 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 260,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withOpacity(isDark ? 0.60 : 0.45),
                              accentColor.withOpacity(isDark ? 0.32 : 0.22),
                              accentColor.withOpacity(isDark ? 0.10 : 0.06),
                              accentColor.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.40, 0.72, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Main content
                _keepWorkoutAlive
                    ? Stack(
                        children: [
                          Offstage(
                            offstage: _tabIndex != 2,
                            child: FadeTransition(
                              opacity: _workoutTabEnterOpacity,
                              child: SlideTransition(
                                position: _workoutTabEnterSlide,
                                child: _workoutPage,
                              ),
                            ),
                          ),
                          if (_tabIndex != 2)
                            _buildNonWorkoutTabSwitcher(currentScreen),
                        ],
                      )
                    : _buildNonWorkoutTabSwitcher(currentScreen),
              ],
            ),
          ),
        ),
      ),
    );
    }); // ValueListenableBuilder
  }
}

// ============================================================================
// EXTRACTED WIDGETS & PAINTERS
// ============================================================================

class MetricCard extends StatelessWidget {
  final Color cardColor, textColor, subTextColor, iconColor, trendColor;
  final IconData icon;
  final String trendText, title, value, unit;
  final bool valueInlineUnit;
  final bool compact;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  // Optional pill progress bar (0.0 – 1.0)
  final double? stepsProgress;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.icon,
    required this.iconColor,
    required this.trendText,
    required this.trendColor,
    required this.title,
    required this.value,
    required this.unit,
    this.valueInlineUnit = false,
    this.compact = false,
    this.onIncrement,
    this.onDecrement,
    this.stepsProgress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = compact ? 16.0 : 20.0;
    final iconSize = compact ? 20.0 : 24.0;
    final iconPad = compact ? 6.0 : 8.0;
    final topGap = compact ? 16.0 : 24.0;
    final titleSize = compact ? 13.0 : 14.0;
    final valueSize = compact ? 24.0 : 28.0;
    final unitSize = compact ? 11.0 : 12.0;
    final trendSize = compact ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: trendSize,
                  ),
                ),
              ),
              // Steps card: buttons in header
              if (stepsProgress != null && onIncrement != null && onDecrement != null) ...[
                const SizedBox(width: 8),
                _RepeatActionIconButton(
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement!,
                ),
                const SizedBox(width: 6),
                _RepeatActionIconButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement!,
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: subTextColor,
                ),
              ],
            ],
          ),
          SizedBox(height: topGap),
          Text(
            title,
            style: TextStyle(
              color: subTextColor,
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          if (valueInlineUnit)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: unitSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: TextStyle(color: subTextColor, fontSize: unitSize),
                ),
              ],
            ),
          const Spacer(),
          if (stepsProgress != null) ...[
            const SizedBox(height: 8),
            _StepsPillBar(progress: stepsProgress!.clamp(0.0, 1.0)),
            const SizedBox(height: 2),
          ],
          if (stepsProgress == null && onIncrement != null && onDecrement != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RepeatActionIconButton(
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement!,
                ),
                const SizedBox(width: 8),
                _RepeatActionIconButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement!,
                ),
              ],
            ),
        ],
      ),
    ),
    );
  }
}

class _StepsPillBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0

  const _StepsPillBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pillColor = AccentColor.notifier.value;
    const totalPills = 20;    final filledCount = (progress * totalPills).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Goal 10,000',
            style: TextStyle(
              color: pillColor.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 3.0;
            final pillWidth =
                (constraints.maxWidth - gap * (totalPills - 1)) / totalPills;
            return Row(
              children: List.generate(totalPills, (i) {
                final filled = i < filledCount;
                return Padding(
                  padding: EdgeInsets.only(right: i < totalPills - 1 ? gap : 0),
                  child: Container(
                    width: pillWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      color: filled
                          ? pillColor
                          : pillColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _RepeatActionIconButton extends StatefulWidget {
  const _RepeatActionIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_RepeatActionIconButton> createState() => _RepeatActionIconButtonState();
}

class _RepeatActionIconButtonState extends State<_RepeatActionIconButton> {
  Timer? _timer;
  int _repeatTicks = 0;

  void _runAction() {
    final multiplier = _repeatTicks >= 16
        ? 4
        : _repeatTicks >= 8
        ? 2
        : 1;
    for (var i = 0; i < multiplier; i++) {
      widget.onPressed();
    }
  }

  void _startRepeating() {
    _stopRepeating();
    _repeatTicks = 0;
    _runAction();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _repeatTicks += 1;
      _runAction();
    });
  }

  void _stopRepeating() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startRepeating(),
      onTapUp: (_) => _stopRepeating(),
      onTapCancel: _stopRepeating,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          widget.icon,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }
}

class BarChartColumn extends StatelessWidget {
  final String label;
  final double heightRatio;
  final bool isDark;

  const BarChartColumn({
    super.key,
    required this.label,
    required this.heightRatio,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: 80.0 * heightRatio,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black87,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  RingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = AccentColor.notifier.value
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

// ============================================================================
// HEART RATE CARD
// ============================================================================

// ============================================================================
// HEART RATE CARD
// ============================================================================

class HeartRateCard extends StatelessWidget {
  final Color cardColor, textColor, subTextColor, trendColor;
  final String trendText;
  final int heartRate;
  final List<({int bpm, DateTime time})> hrHistory;
  final bool compact;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onTap;

  const HeartRateCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.heartRate,
    required this.hrHistory,
    this.compact = false,
    this.onIncrement,
    this.onDecrement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = compact ? 16.0 : 20.0;
    final topGap = compact ? 16.0 : 24.0;
    final valueSize = compact ? 24.0 : 28.0;
    final trendSize = compact ? 10.0 : 11.0;
    final iconSize = compact ? 20.0 : 24.0;
    final iconPad = compact ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: double.infinity,
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_border,
                    color: Colors.redAccent, size: iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: trendSize,
                  ),
                ),
              ),
              if (onIncrement != null && onDecrement != null) ...[
                const SizedBox(width: 8),
                _RepeatActionIconButton(
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement!,
                ),
                const SizedBox(width: 8),
                _RepeatActionIconButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement!,
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: subTextColor,
                ),
              ],
            ],
          ),
          SizedBox(height: topGap),
          Text(
            'Heart Rate',
            style: TextStyle(
              color: subTextColor,
              fontSize: compact ? 13.0 : 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                heartRate.toString(),
                style: TextStyle(
                  color: textColor,
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'bpm',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: compact ? 11.0 : 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: CustomPaint(
              painter: _HeartWavePainter(
                color: AccentColor.notifier.value,
                hrHistory: hrHistory,
              ),
              size: const Size(double.infinity, 54),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _HeartWavePainter extends CustomPainter {
  final Color color;
  final List<({int bpm, DateTime time})> hrHistory;

  const _HeartWavePainter({required this.color, required this.hrHistory});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final midY = size.height * 0.5;

    canvas.saveLayer(rect, Paint());

    // Fade mask applied at the end — left edge fades in
    void applyFade() {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.transparent, Colors.white],
            stops: const [0.0, 0.18],
          ).createShader(rect)
          ..blendMode = BlendMode.dstIn,
      );
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // No data or single zero reading → flat line
    final validHistory = hrHistory.where((r) => r.bpm > 0).toList();
    if (validHistory.length < 2) {
      final y = validHistory.isEmpty
          ? midY
          : _bpmToY(validHistory.first.bpm, size.height, validHistory);
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          linePaint..color = color.withOpacity(0.45));
      applyFade();
      canvas.restore();
      return;
    }

    // Map time range to X axis
    final tStart = validHistory.first.time.millisecondsSinceEpoch.toDouble();
    final tEnd = validHistory.last.time.millisecondsSinceEpoch.toDouble();
    final tRange = (tEnd - tStart).clamp(1.0, double.infinity);

    double xOf(DateTime t) =>
        (t.millisecondsSinceEpoch - tStart) / tRange * size.width;

    double yOf(int bpm) => _bpmToY(bpm, size.height, validHistory);

    final pts = validHistory
        .map((r) => Offset(xOf(r.time), yOf(r.bpm)))
        .toList();

    // Build smooth path
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    // Fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
        ).createShader(rect)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(path, linePaint);
    applyFade();
    canvas.restore();
  }

  // Map BPM to Y: scale within the range of recorded values with padding
  double _bpmToY(
    int bpm,
    double height,
    List<({int bpm, DateTime time})> history,
  ) {
    final minBpm = history.map((r) => r.bpm).reduce(math.min).toDouble();
    final maxBpm = history.map((r) => r.bpm).reduce(math.max).toDouble();
    final range = (maxBpm - minBpm).clamp(10.0, double.infinity);
    final padding = height * 0.15;
    // Higher BPM = lower Y (top of canvas)
    return height -
        padding -
        ((bpm - minBpm) / range) * (height - padding * 2);
  }

  @override
  bool shouldRepaint(covariant _HeartWavePainter old) =>
      old.hrHistory.length != hrHistory.length ||
      (hrHistory.isNotEmpty &&
          old.hrHistory.isNotEmpty &&
          old.hrHistory.last.bpm != hrHistory.last.bpm);
}

// ============================================================================
// EXERCISE TIME CARD
// ============================================================================

class ExerciseTimeCard extends StatelessWidget {
  final Color cardColor, textColor, subTextColor, trendColor;
  final String trendText;
  final int exerciseMinutes;
  final List<int> exHistory; // 7 values, Mon–Sun, minutes
  final bool compact;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ExerciseTimeCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.exerciseMinutes,
    required this.exHistory,
    this.compact = false,
    this.onIncrement,
    this.onDecrement,
  });

  String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final p = compact ? 16.0 : 20.0;
    final topGap = compact ? 8.0 : 12.0;
    final valueSize = compact ? 22.0 : 26.0;
    final trendSize = compact ? 10.0 : 11.0;
    final iconSize = compact ? 20.0 : 24.0;
    final iconPad = compact ? 6.0 : 8.0;

    final pillColor = AccentColor.notifier.value;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);

    return Container(
      height: double.infinity,
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B4B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timer,
                    color: const Color(0xFFFF4B4B), size: iconSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: trendSize,
                  ),
                ),
              ),
              if (onIncrement != null && onDecrement != null) ...[
                const SizedBox(width: 8),
                _RepeatActionIconButton(
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement!,
                ),
                const SizedBox(width: 6),
                _RepeatActionIconButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement!,
                ),
              ],
            ],
          ),
          SizedBox(height: topGap),
          Text(
            'Exercise Time',
            style: TextStyle(
              color: subTextColor,
              fontSize: compact ? 13.0 : 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(exerciseMinutes),
            style: TextStyle(
              color: textColor,
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Vertical pill bar chart — 7 days
          SizedBox(
            height: 54,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = exHistory[i];
                // Scale: max of actual data or 60 min so 1 min doesn't fill the bar
                final maxVal = math.max(exHistory.reduce(math.max), 60);
                final frac = val / maxVal;
                final isToday = i == todayIdx;
                final hasVal = val > 0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 2.5 : 3.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: LayoutBuilder(
                            builder: (ctx, bc) {
                              const maxH = 46.0;
                              const minH = 8.0;
                              final barH = hasVal
                                  ? (minH + frac * (maxH - minH))
                                  : minH;
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? pillColor
                                        : hasVal
                                            ? pillColor.withOpacity(0.35)
                                            : pillColor.withOpacity(0.12),
                                    // Large radius = fully rounded pill caps
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[i],
                          style: TextStyle(
                            color: isToday ? pillColor : subTextColor,
                            fontSize: 9,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CALORIES CARD — fuel gauge bar
// ============================================================================

class CaloriesCard extends StatelessWidget {
  final Color cardColor, textColor, subTextColor, trendColor;
  final String trendText;
  final int activeCalories;
  final int eatenCalories;
  final bool compact;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onTap;

  static const int _burnGoal = 500;

  const CaloriesCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.activeCalories,
    this.eatenCalories = 0,
    this.compact = false,
    this.onIncrement,
    this.onDecrement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = compact ? 16.0 : 20.0;
    final trendSize = compact ? 10.0 : 11.0;
    final iconSize = compact ? 20.0 : 24.0;
    final iconPad = compact ? 6.0 : 8.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int net = eatenCalories - activeCalories;
    final Color netColor;
    if (net < -1000 || net > 200) {
      netColor = const Color(0xFFFF453A);
    } else if (net >= -200 && net <= 200) {
      netColor = const Color(0xFFFFD60A);
    } else {
      netColor = const Color(0xFF30D158);
    }
    final String netStr = net >= 0 ? '+$net' : '$net';
    final double burnProgress = (activeCalories / _burnGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: EdgeInsets.all(p),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_fire_department,
                      color: Colors.orange, size: iconSize),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trendText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                      fontSize: trendSize,
                    ),
                  ),
                ),
                if (onIncrement != null && onDecrement != null) ...[
                  const SizedBox(width: 8),
                  _RepeatActionIconButton(
                      icon: Icons.remove_rounded, onPressed: onDecrement!),
                  const SizedBox(width: 6),
                  _RepeatActionIconButton(
                      icon: Icons.add_rounded, onPressed: onIncrement!),
                ],
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: subTextColor),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Burned label + value
            Text(
              'Calories Burned',
              style: TextStyle(
                color: subTextColor,
                fontSize: compact ? 12.0 : 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  activeCalories >= 1000
                      ? '${(activeCalories / 1000).toStringAsFixed(1)}k'
                      : activeCalories.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 22.0 : 26.0,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 4),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: compact ? 11.0 : 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Fuel bar
            _CalFuelBar(progress: burnProgress, compact: compact),

            const Spacer(),

            // Three metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CalMetric(
                  label: 'Burned',
                  value: activeCalories,
                  color: Colors.orange,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  compact: compact,
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: subTextColor.withValues(alpha: 0.15)),
                _CalMetric(
                  label: 'Eaten',
                  value: eatenCalories,
                  color: const Color(0xFF30A2FF),
                  textColor: textColor,
                  subTextColor: subTextColor,
                  compact: compact,
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: subTextColor.withValues(alpha: 0.15)),
                _CalMetric(
                  label: 'Net',
                  valueStr: netStr,
                  color: netColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  compact: compact,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Net bar
            _NetEnergyBar(net: net, isDark: isDark),

            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _CalFuelBar extends StatelessWidget {
  final double progress;
  final bool compact;

  const _CalFuelBar({required this.progress, required this.compact});

  @override
  Widget build(BuildContext context) {
    final color = Colors.orange;
    const total = 12;
    final filled = (progress * total).round().clamp(0, total);
    const heightPattern = [
      0.45, 0.55, 0.50, 0.65, 0.55, 0.70,
      0.60, 0.75, 0.65, 0.80, 0.70, 0.90
    ];
    final maxH = compact ? 28.0 : 34.0;

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 4.0;
      final segW = (constraints.maxWidth - gap * (total - 1)) / total;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(total, (i) {
          final active = i < filled;
          final h = maxH * heightPattern[i];
          return Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? gap : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: segW,
              height: h,
              decoration: BoxDecoration(
                color: active
                    ? color
                    : color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(segW / 2),
              ),
            ),
          );
        }),
      );
    });
  }
}

class _CalMetric extends StatelessWidget {
  final String label;
  final int? value;
  final String? valueStr;
  final Color color;
  final Color textColor;
  final Color subTextColor;
  final bool compact;

  const _CalMetric({
    required this.label,
    this.value,
    this.valueStr,
    required this.color,
    required this.textColor,
    required this.subTextColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final display = valueStr ?? (value != null
        ? (value! >= 1000
            ? '${(value! / 1000).toStringAsFixed(1)}k'
            : value.toString())
        : '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          display,
          style: TextStyle(
            color: color,
            fontSize: compact ? 16.0 : 18.0,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: compact ? 10.0 : 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NetEnergyBar extends StatelessWidget {
  final int net;
  final bool isDark;

  const _NetEnergyBar({required this.net, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Bar spans -2000 to +2000, center = 0
    const int range = 2000;
    final double ratio = (net / range).clamp(-1.0, 1.0);
    final bool isPositive = net >= 0;

    final Color barColor;
    if (net < -1000 || net > 200) {
      barColor = const Color(0xFFFF453A);
    } else if (net >= -200 && net <= 200) {
      barColor = const Color(0xFFFFD60A);
    } else {
      barColor = const Color(0xFF30D158);
    }

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return LayoutBuilder(builder: (context, constraints) {
      final double totalW = constraints.maxWidth;
      final double centerX = totalW / 2;
      final double barW = (ratio.abs() * centerX).clamp(2.0, centerX);

      return SizedBox(
        height: 6,
        child: Stack(
          children: [
            // Track
            Container(
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Center tick
            Positioned(
              left: centerX - 0.5,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
              ),
            ),
            // Filled bar from center
            Positioned(
              left: isPositive ? centerX : centerX - barW,
              top: 1,
              bottom: 1,
              width: barW,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ============================================================================
// SLEEP CARD
// ============================================================================

class SleepCard extends StatelessWidget {
  final Color cardColor, textColor, subTextColor, trendColor;
  final String trendText;
  final List<int> sleepData;
  final int avgSleepMinutes;
  final bool isDark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const SleepCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.sleepData,
    required this.avgSleepMinutes,
    required this.isDark,
    required this.onIncrement,
    required this.onDecrement,
  });

  String _fmt(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final color = AccentColor.notifier.value;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    // Max hours to show on the bar = 10h
    const maxMins = 600.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — two rows so title never squishes
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bedtime_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sleep Analysis',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _RepeatActionIconButton(
                  icon: Icons.remove_rounded, onPressed: onDecrement),
              const SizedBox(width: 6),
              _RepeatActionIconButton(
                  icon: Icons.add_rounded, onPressed: onIncrement),
            ],
          ),

          const SizedBox(height: 6),
          // Avg line
          Row(
            children: [
              const SizedBox(width: 40),
              Text('avg  ',
                  style: TextStyle(color: subTextColor, fontSize: 11)),
              Text(_fmt(avgSleepMinutes),
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text('  / night',
                  style: TextStyle(color: subTextColor, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 14),

          // One row per day: label | filled bar
          ...List.generate(7, (i) {
            final mins = sleepData[i];
            final frac = (mins / maxMins).clamp(0.0, 1.0);
            final isToday = i == todayIdx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      days[i],
                      style: TextStyle(
                        color: isToday ? color : subTextColor,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: LayoutBuilder(builder: (ctx, bc) {
                      return Stack(
                        children: [
                          // Track
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Fill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            height: 10,
                            width: bc.maxWidth * frac,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? color
                                  : color.withOpacity(mins > 0 ? 0.45 : 0.0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      _fmt(mins),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isToday ? color : subTextColor,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
