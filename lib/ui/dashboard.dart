import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:synthese/l10n/generated/app_localizations.dart';

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
import 'package:synthese/services/first_launch_permissions_service.dart';
import 'package:synthese/services/home_widget_service.dart';
import 'package:synthese/services/data_aggregation_service.dart';
import 'package:synthese/services/notification_rules_engine.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/services/update_reminder_service.dart';
import 'package:synthese/services/review_service.dart';
import 'package:synthese/ui/steps_detail_page.dart';
import 'package:synthese/ui/heart_rate_detail_page.dart';
import 'package:synthese/ui/calories_detail_page.dart';
import 'package:synthese/ui/exercise_detail_page.dart';
import 'package:synthese/ui/sleep_detail_page.dart';

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

  late final AnimationController _tabEnterController;
  late final Animation<double> _tabEnterOpacity;
  late final Animation<Offset> _tabEnterSlide;
  // --- STATE VARIABLES ---
  late int _score;
  int _tabIndex = 0;
  bool _isModalOpen = false;

  // Track if user is female to show the Cycles tab
  bool _isFemale = false;

  // Mindfulness onboarding completion
  bool _mindfulnessOnboardingComplete = false;

  // Cached profile photo URL for header avatar
  String? _profilePhotoUrl;

  // Current values - completely zeroed out for new logins
  int _activeCalories = 0;
  int _heartRate = 0;
  int _steps = 0;
  int _manualStepAdjustments = 0;
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
  final FirstLaunchPermissionsService _firstLaunchPermissionsService =
      FirstLaunchPermissionsService();
  Timer? _metricsPersistDebounce;
  Timer? _notificationRulesTimer;
  bool _isWorkoutModeOpen = false;

  // Goal-reached flags — reset when app restarts, not on every metric update
  bool _stepsGoalToasted = false;
  bool _caloriesGoalToasted = false;

  // User-configured daily goals (set during onboarding stage 2; fall back
  // to the previous hardcoded defaults if Firestore has no value yet).
  int _goalSteps = 10000;
  int _goalCaloriesBurnt = 500;
  int _goalCaloriesEaten = 2000;
  int _goalExerciseMinutes = 60;
  double _goalSleepHours = 8.0;

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

    _tabEnterController = AnimationController(
      vsync: this,
      duration: _kTabSwitchDuration,
      value: 1.0, // start complete so initial home tab has no animation
    );
    final _tabEnterCurved = CurvedAnimation(
      parent: _tabEnterController,
      curve: Curves.easeOutCubic,
    );
    _tabEnterOpacity = _tabEnterCurved;
    _tabEnterSlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(_tabEnterCurved);
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
      UpdateReminderService.checkAndNotify(context);
    });
    unawaited(_loadPersistedDashboardMetrics());
    _fetchUserGender();
    _fetchUserProfile();
    _fetchUserGoals();
    _fetchMindfulnessOnboarding();
    unawaited(_fetchEatenCalories());
    _listenEatenCalories();
    unawaited(
      _firstLaunchPermissionsService.requestAllPermissionsIfFirstLaunch(),
    );
    unawaited(NotificationRulesEngine.evaluateGlobal());
    _notificationRulesTimer = Timer.periodic(const Duration(hours: 3), (_) {
      unawaited(NotificationRulesEngine.evaluateGlobal());
    });
  }

  @override
  void dispose() {
    _workoutTabEnterController.dispose();
    _tabEnterController.dispose();
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

  int _manualSleepTotalFromData(Map<String, dynamic>? data) {
    final explicit = (data?['manualSleepTotal'] as num?)?.toInt();
    if (explicit != null) return explicit;
    final phases = data?['manualSleepPhases'] as Map<String, dynamic>?;
    if (phases == null) return 0;
    final rem    = (phases['rem']    as num?)?.toInt() ?? 0;
    final light  = (phases['light']  as num?)?.toInt() ?? 0;
    final deep   = (phases['deep']   as num?)?.toInt() ?? 0;
    final awake  = (phases['awake']  as num?)?.toInt() ?? 0;
    final asleep = (phases['asleep'] as num?)?.toInt() ?? 0;
    return rem + light + deep + awake + asleep;
  }

  Future<int> _fetchManualSleepTotalForDay(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final key = _dateKey(day);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(key)
        .get();
    return _manualSleepTotalFromData(doc.data());
  }

  Future<void> _incrementManualSleepPhaseForToday({
    required String phase,
    required int deltaMinutes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final key = _dateKey(now);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(key);
    final snapshot = await docRef.get();
    final current =
        (snapshot.data()?['manualSleepPhases'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final rem    = (current['rem']    as num?)?.toInt() ?? 0;
    final light  = (current['light']  as num?)?.toInt() ?? 0;
    final deep   = (current['deep']   as num?)?.toInt() ?? 0;
    final awake  = (current['awake']  as num?)?.toInt() ?? 0;
    final asleep = (current['asleep'] as num?)?.toInt() ?? 0;

    int nextRem    = rem;
    int nextLight  = light;
    int nextDeep   = deep;
    int nextAwake  = awake;
    int nextAsleep = asleep;
    switch (phase) {
      case 'rem':
        nextRem = (rem + deltaMinutes).clamp(0, 1440).toInt();
        break;
      case 'deep':
        nextDeep = (deep + deltaMinutes).clamp(0, 1440).toInt();
        break;
      case 'awake':
        nextAwake = (awake + deltaMinutes).clamp(0, 1440).toInt();
        break;
      case 'asleep':
        nextAsleep = (asleep + deltaMinutes).clamp(0, 1440).toInt();
        break;
      default:
        nextLight = (light + deltaMinutes).clamp(0, 1440).toInt();
        break;
    }

    await docRef.set({
      'manualSleepPhases': <String, int>{
        'rem':    nextRem,
        'light':  nextLight,
        'deep':   nextDeep,
        'awake':  nextAwake,
        'asleep': nextAsleep,
      },
      'manualSleepTotal': nextRem + nextLight + nextDeep + nextAwake + nextAsleep,
      'dateKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

      final loadedExHistory = (data['exHistory'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList();

      final loadedHrHistory = (data['hrHistory'] as List<dynamic>?)?.map((e) {
        final bpm = (e['bpm'] as num?)?.toInt() ?? 0;
        final ts = (e['time'] as Timestamp?)?.toDate() ?? DateTime.now();
        return (bpm: bpm, time: ts);
      }).toList();

      // Load sleep for the full week from manualSleepTotal per day
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final List<int> weeklySleep = List.filled(7, 0);
      final sleepFutures = <Future<void>>[];
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final idx = i; // Mon=0 … Sun=6
        sleepFutures.add(
          _fetchManualSleepTotalForDay(day).then((mins) {
            weeklySleep[idx] = mins;
          }),
        );
      }
      await Future.wait(sleepFutures);
      final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);

      setState(() {
        _activeCalories =
            (data['activeCalories'] as num?)?.toInt() ?? _activeCalories;
        _heartRate = (data['heartRate'] as num?)?.toInt() ?? _heartRate;
        _steps = (data['steps'] as num?)?.toInt() ?? _steps;
        _manualStepAdjustments =
            (data['manualStepAdjustments'] as num?)?.toInt() ??
            _manualStepAdjustments;
        _exerciseMinutes =
            (data['exerciseMinutes'] as num?)?.toInt() ?? _exerciseMinutes;
        // Load sleep: full week from manualSleepTotal per day
        _sleepData = weeklySleep;
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
            'manualStepAdjustments': _manualStepAdjustments,
            'exerciseMinutes': _exerciseMinutes,
            'exHistory': _exHistory,
            'hrHistory': _hrHistory
                .map((r) => {'bpm': r.bpm, 'time': Timestamp.fromDate(r.time)})
                .toList(),
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
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

  Future<void> _fetchUserGoals() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists || !mounted) return;
      final data = doc.data();
      if (data == null) return;
      setState(() {
        _goalSteps = (data['goalSteps'] as num?)?.toInt() ?? _goalSteps;
        _goalCaloriesBurnt =
            (data['goalCaloriesBurnt'] as num?)?.toInt() ?? _goalCaloriesBurnt;
        _goalCaloriesEaten =
            (data['dailyCalorieGoal'] as num?)?.toInt() ?? _goalCaloriesEaten;
        _goalExerciseMinutes =
            (data['goalExerciseMinutes'] as num?)?.toInt() ?? _goalExerciseMinutes;
        _goalSleepHours =
            (data['goalSleepHours'] as num?)?.toDouble() ?? _goalSleepHours;
      });
      _updateScore();
    } catch (e) {
      debugPrint('Error fetching user goals: $e');
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
    final double sleepGoalMinutes = _goalSleepHours * 60.0;

    double stepsScore = math.min(_steps / _goalSteps.toDouble(), 1.0) * 100.0;
    double calScore =
        math.min(_activeCalories / _goalCaloriesBurnt.toDouble(), 1.0) * 100.0;
    double exerciseScore =
        math.min(_exerciseMinutes / _goalExerciseMinutes.toDouble(), 1.0) *
            100.0;
    double sleepScore =
        math.min(avgSleepMinutes / sleepGoalMinutes, 1.0) * 100.0;

    double healthScore =
        (stepsScore * 0.25) +
        (calScore * 0.25) +
        (exerciseScore * 0.25) +
        (sleepScore * 0.25);

    _score = healthScore.round();

    // Goal-reached toasts — fire only once per session per goal.
    // Look up localizations only when a toast actually fires: _updateScore()
    // runs during initState() (before the Localizations scope is available),
    // and an unconditional AppLocalizations.of(context) there would throw.
    if (mounted && context.mounted) {
      if (!_stepsGoalToasted && _steps >= _goalSteps) {
        _stepsGoalToasted = true;
        AppToast.success(
          context,
          AppLocalizations.of(context).dashStepsGoalReached(
            _formatNumber(_goalSteps),
          ),
          icon: Icons.directions_walk_rounded,
        );
        ReviewService.instance.maybeRequestAfterGoal();
      }
      if (!_caloriesGoalToasted && _activeCalories >= _goalCaloriesBurnt) {
        _caloriesGoalToasted = true;
        AppToast.success(
          context,
          AppLocalizations.of(context).dashCaloriesGoalReached(
            _goalCaloriesBurnt,
          ),
          icon: Icons.local_fire_department_rounded,
        );
        ReviewService.instance.maybeRequestAfterGoal();
      }
    }
  }

  // --- SCORE HELPERS ---
  String _getScoreMessage(AppLocalizations t, int score) {
    if (score >= 90) return t.dashScore90;
    if (score >= 75) return t.dashScore75;
    if (score >= 50) return t.dashScore50;
    if (score >= 25) return t.dashScore25;
    return t.dashScore0;
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return const Color(0xFF4CAF50); // Green
    if (score >= 50) return const Color(0xFFFBC02D); // Yellow
    return const Color(0xFFFF4B4B); // Red
  }

  // --- FORMATTING HELPERS ---
  String _getFormattedDate(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, MMM d', localeName).format(DateTime.now());
  }

  String _formatNumber(int number) {
    final localeName = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(localeName).format(number);
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${mins}m";
    return "${mins}m";
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
      _tabEnterController.forward(from: 0);
    } else if (!isWorkout) {
      _tabEnterController.forward(from: 0);
    }
  }

  Widget _buildNonWorkoutTabSwitcher(Widget currentScreen) {
    return FadeTransition(
      opacity: _tabEnterOpacity,
      child: SlideTransition(
        position: _tabEnterSlide,
        child: currentScreen,
      ),
    );
  }

  /// Called by the sleep detail page after it has already written to Firestore.
  /// Only updates the in-memory display — no second Firestore write.
  void _onSleepDetailAdded(int deltaMinutes) {
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    setState(() {
      _sleepData[todayIdx] = (_sleepData[todayIdx] + deltaMinutes).clamp(0, 1440);
      _updateScore();
    });
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
    final t = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    final safePadding = mediaQuery.padding;
    final isNarrowLayout = mediaQuery.size.width < 390;

    final loggedSleepDays = _sleepData.where((m) => m > 0).toList();
    final avgSleepMinutes = loggedSleepDays.isEmpty
        ? 0
        : loggedSleepDays.reduce((a, b) => a + b) ~/ loggedSleepDays.length;
    final todaySleepMinutes = _sleepData[(DateTime.now().weekday - 1).clamp(0, 6)];

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
                        _getFormattedDate(context),
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
                                  backgroundImage:
                                      (_profilePhotoUrl ??
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.photoURL) !=
                                          null
                                      ? NetworkImage(
                                              (_profilePhotoUrl ??
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.photoURL)!,
                                            )
                                            as ImageProvider
                                      : null,
                                  child:
                                      (_profilePhotoUrl ??
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.photoURL) ==
                                          null
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 20,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
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
                              t.dashScoreLabel,
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
                                _getScoreMessage(t, _score),
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
                trendText: t.dashTapForMore,
                trendColor: subTextColor,
                title: t.dashSteps,
                value: _formatNumber(_steps),
                unit: t.dashStepsUnit,
                valueInlineUnit: true,
                compact: false,
                stepsProgress: _steps / _goalSteps.toDouble(),
                stepsGoalLabel: t.dashGoalValue(_formatNumber(_goalSteps)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StepsDetailPage(
                        todaySteps: _steps,
                        stepGoal: _goalSteps,
                        onTodayManualStepsAdded: (addedSteps) {
                          setState(() {
                            _manualStepAdjustments =
                                (_manualStepAdjustments + addedSteps)
                                    .clamp(-1000000, 1000000)
                                    .toInt();
                            _steps = (_steps + addedSteps)
                                .clamp(0, 1000000)
                                .toInt();
                            _updateScore();
                          });
                          _syncDashboardWidgets();
                          _schedulePersistDashboardMetrics();
                        },
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
                trendText: t.dashTapForMore,
                trendColor: subTextColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HeartRateDetailPage(
                      currentBpm: _heartRate,
                      onManualHeartRateAdded: (bpm) {
                        setState(() {
                          _heartRate = bpm.clamp(0, 250).toInt();
                          _hrHistory.add((
                            bpm: _heartRate,
                            time: DateTime.now(),
                          ));
                        });
                        _syncDashboardWidgets();
                        _schedulePersistDashboardMetrics();
                      },
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
                burnGoal: _goalCaloriesBurnt,
                trendText: t.dashTapForMore,
                trendColor: subTextColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaloriesDetailPage(
                      activeCalories: _activeCalories,
                      eatenCalories: _eatenCalories,
                      burnGoal: _goalCaloriesBurnt,
                      eatGoal: _goalCaloriesEaten,
                      onManualBurnedCaloriesAdded: (delta) {
                          setState(() {
                            _activeCalories = (_activeCalories + delta).clamp(0, 1000000).toInt();
                            _updateScore();
                          });
                          _syncDashboardWidgets();
                          _schedulePersistDashboardMetrics();
                        },
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
                trendText: t.dashTapForMore,
                trendColor: subTextColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailPage(
                      exerciseMinutes: _exerciseMinutes,
                      goalMinutes: _goalExerciseMinutes,
                      onManualExerciseMinutesAdded: (delta) {
                          setState(() {
                            _exerciseMinutes = (_exerciseMinutes + delta).clamp(0, 1000000).toInt();
                            _updateScore();
                            final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
                            _exHistory[todayIdx] = _exerciseMinutes;
                          });
                          _syncDashboardWidgets();
                          _schedulePersistDashboardMetrics();
                        },
                    ),
                  ),
                ),
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
              todaySleepMinutes: todaySleepMinutes,
              goalMinutes: (_goalSleepHours * 60).round(),
              trendText: t.dashTapForMore,
              trendColor: subTextColor,
              isDark: isDark,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SleepDetailPage(
                      todaySleepMinutes:
                          _sleepData[(DateTime.now().weekday - 1).clamp(0, 6)],
                      goalMinutes: (_goalSleepHours * 60).round(),
                      onTodaySleepMinutesAdded: (delta) => _onSleepDetailAdded(delta),
                    ),
                  ),
                );
              },
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
                  hidden:
                      _isModalOpen || (_tabIndex == 2 && _isWorkoutModeOpen),
                  currentIndex: _getBottomNavIndex(),
                  onTap: (index) {
                    HapticFeedback.selectionClick();
                    _setBottomTab(index);
                  },
                  items: [
                    NavItem(label: t.navHome, icon: Icons.home_rounded),
                    NavItem(
                      label: t.navDiet,
                      icon: Icons.restaurant_rounded,
                    ),
                    NavItem(
                      label: t.navWorkout,
                      icon: Icons.fitness_center_rounded,
                    ),
                    NavItem(
                      label: t.navMore,
                      icon: Icons.more_horiz_rounded,
                    ),
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
      },
    ); // ValueListenableBuilder
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
  // Optional pill progress bar (0.0 – 1.0)
  final double? stepsProgress;
  // Optional label rendered above the steps pill bar (e.g. "Goal 10,000")
  final String? stepsGoalLabel;
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
    this.stepsProgress,
    this.stepsGoalLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
              _StepsPillBar(
                progress: stepsProgress!.clamp(0.0, 1.0),
                goalLabel: stepsGoalLabel ?? t.dashGoalShort,
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepsPillBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final String goalLabel;

  const _StepsPillBar({required this.progress, required this.goalLabel});

  @override
  Widget build(BuildContext context) {
    final pillColor = AccentColor.notifier.value;
    const totalPills = 20;
    final filledCount = (progress * totalPills).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            goalLabel,
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
                  padding: EdgeInsetsDirectional.only(end: i < totalPills - 1 ? gap : 0),
                  child: Container(
                    width: pillWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      color: filled ? pillColor : pillColor.withOpacity(0.15),
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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.redAccent,
                    size: iconSize,
                  ),
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
              t.dashHeartRate,
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
                    t.dashBpm,
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
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint..color = color.withOpacity(0.45),
      );
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
    return height - padding - ((bpm - minBpm) / range) * (height - padding * 2);
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
  final List<int> exHistory;
  final bool compact;
  final VoidCallback? onTap;

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
    this.onTap,
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

    final t = AppLocalizations.of(context);
    final pillColor = AccentColor.notifier.value;
    final localeName = Localizations.localeOf(context).toString();
    final nowDate = DateTime.now();
    final monday = nowDate.subtract(Duration(days: nowDate.weekday - 1));
    final days = List.generate(
      7,
      (i) => DateFormat('EEEEE', localeName).format(monday.add(Duration(days: i))),
    );
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);

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
                    color: const Color(0xFFFF4B4B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: const Color(0xFFFF4B4B),
                    size: iconSize,
                  ),
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
              t.dashExerciseTime,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2.5 : 3.0,
                      ),
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
  final int burnGoal;
  final bool compact;
  final VoidCallback? onTap;

  const CaloriesCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.activeCalories,
    this.eatenCalories = 0,
    this.burnGoal = 500,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
    final double burnProgress =
        (activeCalories / burnGoal.toDouble()).clamp(0.0, 1.0);

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
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: iconSize,
                  ),
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

            const SizedBox(height: 10),

            // Burned label + value
            Text(
              t.dashCaloriesBurned,
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
                  padding: const EdgeInsetsDirectional.only(bottom: 3, start: 4),
                  child: Text(
                    t.dashKcal,
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
                  label: t.dashBurned,
                  value: activeCalories,
                  color: Colors.orange,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  compact: compact,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: subTextColor.withValues(alpha: 0.15),
                ),
                _CalMetric(
                  label: t.dashEaten,
                  value: eatenCalories,
                  color: const Color(0xFF30A2FF),
                  textColor: textColor,
                  subTextColor: subTextColor,
                  compact: compact,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: subTextColor.withValues(alpha: 0.15),
                ),
                _CalMetric(
                  label: t.dashNet,
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
      0.45,
      0.55,
      0.50,
      0.65,
      0.55,
      0.70,
      0.60,
      0.75,
      0.65,
      0.80,
      0.70,
      0.90,
    ];
    final maxH = compact ? 28.0 : 34.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final segW = (constraints.maxWidth - gap * (total - 1)) / total;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(total, (i) {
            final active = i < filled;
            final h = maxH * heightPattern[i];
            return Padding(
              padding: EdgeInsetsDirectional.only(end: i < total - 1 ? gap : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: segW,
                height: h,
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(segW / 2),
                ),
              ),
            );
          }),
        );
      },
    );
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
    final display =
        valueStr ??
        (value != null
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

    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
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
  final int todaySleepMinutes;
  final int goalMinutes;
  final bool isDark;
  final VoidCallback? onTap;

  const SleepCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.trendColor,
    required this.trendText,
    required this.sleepData,
    required this.avgSleepMinutes,
    required this.todaySleepMinutes,
    required this.goalMinutes,
    required this.isDark,
    this.onTap,
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
    final t = AppLocalizations.of(context);
    final color = AccentColor.notifier.value;
    final localeName = Localizations.localeOf(context).toString();
    final nowDate = DateTime.now();
    final monday = nowDate.subtract(Duration(days: nowDate.weekday - 1));
    final days = List.generate(
      7,
      (i) => DateFormat('EEE', localeName).format(monday.add(Duration(days: i))),
    );
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    // Bar fills relative to the user's sleep goal so reaching the goal = full bar.
    final double maxMins = goalMinutes > 0 ? goalMinutes.toDouble() : 480.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    t.dashSleepAnalysis,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t.dashTapForMore,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

            const SizedBox(height: 6),
            // Avg line
            Row(
              children: [
                const SizedBox(width: 40),
                Text(
                  '${t.dashSleepToday}  ',
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
                Text(
                  _fmt(todaySleepMinutes),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '  ${t.dashSleepAvg(_fmt(avgSleepMinutes))}',
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
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
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, bc) {
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
                                      : color.withOpacity(
                                          mins > 0 ? 0.45 : 0.0,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

