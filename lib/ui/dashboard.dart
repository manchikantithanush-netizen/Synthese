import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';

import 'package:synthese/ui/account/accountpage.dart';
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

  // Current values - completely zeroed out for new logins
  int _activeCalories = 0;
  int _heartRate = 0;
  int _steps = 0;
  int _exerciseMinutes = 0;
  List<int> _sleepData = [0, 0, 0, 0, 0, 0, 0];
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
    });
    unawaited(_bootstrapDashboardMetrics());
    _fetchUserGender();
    _fetchMindfulnessOnboarding();
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

      setState(() {
        _activeCalories = (data['activeCalories'] as num?)?.toInt() ?? _activeCalories;
        _heartRate = (data['heartRate'] as num?)?.toInt() ?? _heartRate;
        _steps = (data['steps'] as num?)?.toInt() ?? _steps;
        _exerciseMinutes =
            (data['exerciseMinutes'] as num?)?.toInt() ?? _exerciseMinutes;
        if (loadedSleep != null && loadedSleep.length == 7) {
          _sleepData = loadedSleep;
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
      _heartRate = latestHr;
      _activeCalories = math.max(_activeCalories, activeCaloriesToday);
      _exerciseMinutes = math.max(_exerciseMinutes, workoutMinutesToday);
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

  void _adjustExerciseMinutes(int delta) {
    setState(() {
      _exerciseMinutes = (_exerciseMinutes + delta).clamp(0, 1000000).toInt();
      _hasUploadedOnce = true;
      _updateScore();
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

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final cardColor = isDark ? const Color(0xFF151515) : Colors.grey.shade100;

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
                      Text(
                        "Synthese",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: isNarrowLayout ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
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
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: isDark ? Colors.white : Colors.black,
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

            // --- ROW 1: Calories & Heart Rate ---
            if (isNarrowLayout)
              Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: MetricCard(
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      trendText: calTrend.text,
                      trendColor: calTrend.color,
                      title: "Active",
                      value: _formatNumber(_activeCalories),
                      unit: "kcal",
                      compact: true,
                      onIncrement: () => _adjustActiveCalories(10),
                      onDecrement: () => _adjustActiveCalories(-10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    child: MetricCard(
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      icon: Icons.favorite_border,
                      iconColor: Colors.redAccent,
                      trendText: hrTrend.text,
                      trendColor: hrTrend.color,
                      title: "Heart Rate",
                      value: _heartRate.toString(),
                      unit: "AVG",
                      valueInlineUnit: true,
                      compact: true,
                      onIncrement: () => _adjustHeartRate(1),
                      onDecrement: () => _adjustHeartRate(-1),
                    ),
                  ),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        icon: Icons.local_fire_department,
                        iconColor: Colors.orange,
                        trendText: calTrend.text,
                        trendColor: calTrend.color,
                        title: "Active",
                        value: _formatNumber(_activeCalories),
                        unit: "kcal",
                        onIncrement: () => _adjustActiveCalories(10),
                        onDecrement: () => _adjustActiveCalories(-10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MetricCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        icon: Icons.favorite_border,
                        iconColor: Colors.redAccent,
                        trendText: hrTrend.text,
                        trendColor: hrTrend.color,
                        title: "Heart Rate",
                        value: _heartRate.toString(),
                        unit: "AVG",
                        valueInlineUnit: true,
                        onIncrement: () => _adjustHeartRate(1),
                        onDecrement: () => _adjustHeartRate(-1),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --- ROW 2: Steps & Exercise Time ---
            if (isNarrowLayout)
              Column(
                children: [
                  SizedBox(
                    height: 210,
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
                      compact: true,
                      onIncrement: () => _adjustSteps(100),
                      onDecrement: () => _adjustSteps(-100),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    child: MetricCard(
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      icon: Icons.timer,
                      iconColor: const Color(0xFFFF4B4B),
                      trendText: exTrend.text,
                      trendColor: exTrend.color,
                      title: "Exercise Time",
                      value: _formatMinutes(_exerciseMinutes),
                      unit: "AVG",
                      valueInlineUnit: false,
                      compact: true,
                      onIncrement: () => _adjustExerciseMinutes(1),
                      onDecrement: () => _adjustExerciseMinutes(-1),
                    ),
                  ),
                ],
              )
            else
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
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
                        onIncrement: () => _adjustSteps(100),
                        onDecrement: () => _adjustSteps(-100),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MetricCard(
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        icon: Icons.timer,
                        iconColor: const Color(0xFFFF4B4B),
                        trendText: exTrend.text,
                        trendColor: exTrend.color,
                        title: "Exercise Time",
                        value: _formatMinutes(_exerciseMinutes),
                        unit: "AVG",
                        valueInlineUnit: false,
                        onIncrement: () => _adjustExerciseMinutes(1),
                        onDecrement: () => _adjustExerciseMinutes(-1),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --- SLEEP ANALYSIS CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sleep Analysis",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Last 7 Nights",
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMinutes(avgSleepMinutes),
                            style: const TextStyle(
                              color: Color(0xFFB022FF),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "AVG DURATION",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sleepTrend.text,
                            style: TextStyle(
                              color: sleepTrend.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BarChartColumn(
                        label: "M",
                        heightRatio: _sleepData[0] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "T",
                        heightRatio: _sleepData[1] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "W",
                        heightRatio: _sleepData[2] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "T",
                        heightRatio: _sleepData[3] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "F",
                        heightRatio: _sleepData[4] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "S",
                        heightRatio: _sleepData[5] / maxSleep,
                        isDark: isDark,
                      ),
                      BarChartColumn(
                        label: "S",
                        heightRatio: _sleepData[6] / maxSleep,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
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

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(clampedTextScale.toDouble()),
      ),
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

        body: _keepWorkoutAlive
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
      ),
    );
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

    return Container(
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
          if (onIncrement != null && onDecrement != null)
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
      ..color = isDark ? Colors.white : Colors.black
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
