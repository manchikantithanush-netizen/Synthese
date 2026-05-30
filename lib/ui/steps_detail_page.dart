import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/services/step_tracker_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class StepsDetailPage extends StatefulWidget {
  final int todaySteps;
  final int stepGoal;
  final ValueChanged<int>? onTodayManualStepsAdded;

  /// Today's automatic (pedometer) hourly distribution. Shown on top of the
  /// manually-entered hourly buckets in the daily chart; kept separate so the
  /// manual-only data persisted to Firestore is never polluted with sensor data.
  final List<int>? sensorHourlySteps;

  const StepsDetailPage({
    super.key,
    required this.todaySteps,
    this.stepGoal = 10000,
    this.onTodayManualStepsAdded,
    this.sensorHourlySteps,
  });

  @override
  State<StepsDetailPage> createState() => _StepsDetailPageState();
}

class _StepsDetailPageState extends State<StepsDetailPage> {
  String _firstName = '';
  int _selectedTab = 0; // 0 = Daily, 1 = Weekly
  late int _todaySteps;

  // Daily: 24 hourly buckets
  List<int> _hourlySteps = List.filled(24, 0);
  bool _loadingDaily = true;

  // Weekly: Mon–Sun steps (index 0 = Mon)
  List<int> _weeklySteps = List.filled(7, 0);
  bool _loadingWeekly = true;

  // Monthly heatmap: day-of-month → steps (1-indexed)
  Map<int, int> _monthlySteps = {};
  bool _loadingMonthly = true;

  @override
  void initState() {
    super.initState();
    _todaySteps = widget.todaySteps;
    _fetchUserName();
    _fetchHourlySteps();
    _fetchWeeklySteps();
    _fetchMonthlySteps();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _addManualSteps({
    required DateTime when,
    required int steps,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final day = DateTime(when.year, when.month, when.day);
    final dayKey = _dateKey(day);
    final hour = when.hour.clamp(0, 23);

    // Build updated hourly array
    final updatedHourly = List<int>.from(_hourlySteps);
    if (_isSameDay(when, DateTime.now())) {
      updatedHourly[hour] += steps;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(dayKey)
        .set({
          'steps': FieldValue.increment(steps),
          'manualStepAdjustments': FieldValue.increment(steps),
          'hourlySteps': updatedHourly,
          'dateKey': dayKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    if (!mounted) return;

    final now = DateTime.now();
    setState(() {
      if (_isSameDay(when, now)) {
        _todaySteps += steps;
        _hourlySteps[hour] += steps;
      }

      final daysSinceMonday = now.weekday - 1;
      final monday = DateTime(now.year, now.month, now.day - daysSinceMonday);
      final sunday = monday.add(const Duration(days: 6));
      if (!day.isBefore(monday) && !day.isAfter(sunday)) {
        final weekIndex = day.weekday - 1;
        _weeklySteps[weekIndex] += steps;
      }

      if (day.year == now.year && day.month == now.month) {
        final d = day.day;
        _monthlySteps[d] = (_monthlySteps[d] ?? 0) + steps;
      }
    });

    if (_isSameDay(when, now)) {
      widget.onTodayManualStepsAdded?.call(steps);
    }
  }

  Future<void> _showAddDataSheet({
    required Color accentColor,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AddStepsSheet(
        accentColor: accentColor,
        isDark: isDark,
        textColor: textColor,
        cardColor: cardColor,
        onSave: _addManualSteps,
      ),
    );
  }

  Future<void> _fetchUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final fullName = doc.data()?['fullName'] as String? ?? '';
        setState(() => _firstName = fullName.trim().split(' ').first);
      }
    } catch (_) {}
  }

  /// Fetch today's hourly steps from Firestore (manual entries only).
  Future<void> _fetchHourlySteps() async {
    setState(() => _loadingDaily = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final dayKey = _dateKey(DateTime(now.year, now.month, now.day));
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(dayKey)
          .get();
      final raw = doc.data()?['hourlySteps'] as List<dynamic>?;
      if (raw != null && raw.length == 24) {
        final hourly = raw.map((e) => (e as num).toInt()).toList();
        if (mounted) setState(() => _hourlySteps = hourly);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  Future<void> _fetchWeeklySteps() async {
    setState(() => _loadingWeekly = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      // Find this week's Monday
      final int daysSinceMonday = now.weekday - 1; // Mon=0, Sun=6
      final DateTime monday = DateTime(
        now.year,
        now.month,
        now.day - daysSinceMonday,
      );

      final List<int> steps = List.filled(7, 0);

      for (int i = 0; i <= daysSinceMonday; i++) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('dashboardDaily')
            .doc(key)
            .get();
        final daySteps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
        steps[i] = daySteps; // i=0 is Mon, i=6 is Sun
      }

      if (mounted) setState(() => _weeklySteps = steps);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  Future<void> _fetchMonthlySteps() async {
    setState(() => _loadingMonthly = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final Map<int, int> result = {};

      // Batch fetch all days of current month up to today
      final futures = <Future<void>>[];
      for (int day = 1; day <= math.min(now.day, daysInMonth); day++) {
        final date = DateTime(now.year, now.month, day);
        final key = _dateKey(date);
        futures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('dashboardDaily')
              .doc(key)
              .get()
              .then((doc) {
                final steps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
                result[day] = steps;
              }),
        );
      }
      await Future.wait(futures);

      if (mounted) setState(() => _monthlySteps = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMonthly = false);
    }
  }

  String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _formatLarge(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;

    final bool isDaily = _selectedTab == 0;
    final bool isLoading = isDaily ? _loadingDaily : _loadingWeekly;

    // Combine manual hourly buckets with today's automatic pedometer buckets
    // for display only (the persisted manual data is never modified).
    final sensorHourly = widget.sensorHourlySteps;
    final List<int> effectiveHourly = List<int>.generate(24, (i) {
      final base = i < _hourlySteps.length ? _hourlySteps[i] : 0;
      final sensor =
          (sensorHourly != null && i < sensorHourly.length) ? sensorHourly[i] : 0;
      return base + sensor;
    });

    // Daily: trim to last active hour, min 8 bars
    int lastNonZero = 7;
    for (int i = 23; i >= 0; i--) {
      if (effectiveHourly[i] > 0) {
        lastNonZero = i;
        break;
      }
    }
    final int hourCount = math.max(lastNonZero + 1, 8);
    final List<int> dailyBars = effectiveHourly.sublist(0, hourCount);

    final List<int> bars = isDaily ? dailyBars : _weeklySteps;
    final int maxVal = bars.isEmpty ? 1 : math.max(bars.reduce(math.max), 1);

    final nonZero = bars.where((v) => v > 0).toList();
    final int avg = nonZero.isEmpty
        ? 0
        : nonZero.reduce((a, b) => a + b) ~/ nonZero.length;

    final int displayNum = isDaily ? _todaySteps : avg;
    final String displayLabel =
        isDaily ? t.stepsDetTodaysSteps : t.stepsDetAvgDaily;

    final localeName = Localizations.localeOf(context).toString();
    final mondayLabel = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekLabels = List.generate(
      7,
      (i) => DateFormat('EEE', localeName).format(mondayLabel.add(Duration(days: i))),
    );

    return ValueListenableBuilder<Color>(
      valueListenable: AccentColor.notifier,
      builder: (context, accentColor, _) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // Accent glow
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
                            accentColor.withValues(alpha: isDark ? 0.60 : 0.45),
                            accentColor.withValues(alpha: isDark ? 0.32 : 0.22),
                            accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                            accentColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.40, 0.72, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                          child: Row(
                            children: [
                              UniversalBackButton(
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () => _showAddDataSheet(
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                  cardColor: cardColor,
                                ),
                                icon: Icon(Icons.add_rounded,
                                    size: 16, color: textColor),
                                label: Text(
                                  t.detailAddData,
                                  style: font(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.15),
                                  ),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Greeting
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: RichText(
                            text: TextSpan(
                              style: font(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.25,
                              ),
                              children: [
                                if (_firstName.isNotEmpty)
                                  TextSpan(text: '${t.stepsDetGreeting(_firstName)}\n'),
                                TextSpan(text: t.stepsDetWalkedPrefix),
                                TextSpan(
                                  text: _formatLarge(_todaySteps),
                                  style: font(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                TextSpan(
                                  text: t.stepsDetWalkedSuffix,
                                  style: font(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Chart card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UniversalSegmentedControl<int>(
                                  items: const [0, 1],
                                  labels: [t.detailDaily, t.detailWeekly],
                                  selectedItem: _selectedTab,
                                  onSelectionChanged: (v) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedTab = v);
                                  },
                                ),

                                const SizedBox(height: 20),

                                Text(
                                  _formatLarge(displayNum),
                                  style: font(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayLabel,
                                  style: font(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Energy bar
                                _EnergyBar(
                                  progress: (_todaySteps /
                                          widget.stepGoal.toDouble())
                                      .clamp(0.0, 1.0),
                                  accentColor: accentColor,
                                  isDark: isDark,
                                  textColor: textColor,
                                ),

                                const SizedBox(height: 16),

                                isLoading
                                    ? const SizedBox(
                                        height: 200,
                                        child: Center(
                                          child: BouncingDotsLoader(),
                                        ),
                                      )
                                    : _StepsBarChart(
                                        bars: bars,
                                        maxVal: maxVal,
                                        accentColor: accentColor,
                                        isDark: isDark,
                                        textColor: textColor,
                                        isDaily: isDaily,
                                        weekLabels: weekLabels,
                                      ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone step-tracking status card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _StepTrackingInfoCard(
                            cardColor: cardColor,
                            textColor: textColor,
                            accentColor: accentColor,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Distance card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _DistanceCard(
                            steps: _todaySteps,
                            stepGoal: widget.stepGoal,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Weekly rings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _WeeklyRings(
                            weeklySteps: _weeklySteps,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            stepGoal: widget.stepGoal,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Heatmap card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _MonthHeatmap(
                            monthlySteps: _monthlySteps,
                            isLoading: _loadingMonthly,
                            accentColor: accentColor,
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            stepGoal: widget.stepGoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddStepsSheet extends StatefulWidget {
  const _AddStepsSheet({
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.cardColor,
    required this.onSave,
  });

  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final Color cardColor;
  final Future<void> Function({required DateTime when, required int steps}) onSave;

  @override
  State<_AddStepsSheet> createState() => _AddStepsSheetState();
}

class _AddStepsSheetState extends State<_AddStepsSheet> {
  late DateTime _selectedDateTime;
  late TextEditingController _stepsController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
    _stepsController = TextEditingController();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        picked.year, picked.month, picked.day,
        _selectedDateTime.hour, _selectedDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) => Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day,
        picked.hour, picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    final value = int.tryParse(_stepsController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = AppLocalizations.of(context).stepsDetErrorCount);
      return;
    }
    setState(() { _error = null; _saving = true; });
    try {
      await widget.onSave(when: _selectedDateTime, steps: value);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).detailSaveFailed;
        _saving = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', localeName).format(dt);
  }

  String _formatTime(DateTime dt) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat.jm(localeName).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = widget.textColor;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final pillBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final divColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07);
    final font = GoogleFonts.plusJakartaSans;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.93,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── top bar: X left, ✓ right (fixed) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopBarButton(
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: textColor),
                      ),
                      _TopBarButton(
                        isDark: isDark,
                        onTap: _saving ? null : _submit,
                        child: _saving
                            ? SizedBox(
                                width: 24,
                                height: 12,
                                child: BouncingDotsLoader.compact(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              )
                            : Icon(Icons.check_rounded,
                                size: 18, color: textColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

              // ── icon ──
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    size: 34,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── title ──
              Center(
                child: Text(
                  t.dashSteps,
                  style: font(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── rows card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Date row
                      _SheetRow(
                        label: t.detailDate,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDate(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5,
                          indent: 16, color: divColor),
                      // Time row
                      _SheetRow(
                        label: t.detailTime,
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: GestureDetector(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatTime(_selectedDateTime),
                              style: font(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5,
                          indent: 16, color: divColor),
                      // Steps input row — no pill, just cursor
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              t.dashSteps,
                              style: font(
                                fontSize: 16,
                                color: subColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _stepsController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                autofocus: true,
                                textAlign: TextAlign.right,
                                onChanged: (_) {
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                onSubmitted: (_) => _submit(),
                                style: font(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '',
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // inline error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    _error!,
                    style: font(fontSize: 13, color: Colors.redAccent),
                  ),
                ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── small helpers ─────────────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _TopBarButton({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final effectiveBorder = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: effectiveBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: effectiveBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap == null ? null : () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final Color subColor;
  final Color textColor;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) font;
  final Widget trailing;

  const _SheetRow({
    required this.label,
    required this.subColor,
    required this.textColor,
    required this.font,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: font(fontSize: 16, color: subColor)),
          trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Phone step-tracking status card
// ─────────────────────────────────────────────

class _StepTrackingInfoCard extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final bool isDark;

  const _StepTrackingInfoCard({
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
  });

  void _showInfoModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _StepTrackingInfoSheet(
        isDark: isDark,
        textColor: textColor,
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    final subColor = textColor.withValues(alpha: 0.55);
    final dimColor = textColor.withValues(alpha: 0.4);

    return ValueListenableBuilder<bool>(
      valueListenable: StepTracker.instance.backgroundEnabled,
      builder: (context, enabled, _) {
        final statusColor = enabled ? const Color(0xFF22C55E) : dimColor;
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_walk_rounded,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                enabled
                                    ? t.stepsDetTrackOnTitle
                                    : t.stepsDetTrackOffTitle,
                                style: font(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enabled
                              ? t.stepsDetTrackOnSubtitle
                              : t.stepsDetTrackOffSubtitle,
                          style: font(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InfoIconButton(
                    isDark: isDark,
                    color: dimColor,
                    onTap: () => _showInfoModal(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                t.stepsDetTrackHowTitle.toUpperCase(),
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dimColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _HowToStep(number: '1', text: t.stepsDetTrackStep1, color: dimColor),
              const SizedBox(height: 5),
              _HowToStep(number: '2', text: t.stepsDetTrackStep2, color: dimColor),
              const SizedBox(height: 5),
              _HowToStep(number: '3', text: t.stepsDetTrackStep3, color: dimColor),
            ],
          ),
        );
      },
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String number;
  final String text;
  final Color color;

  const _HowToStep({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: font(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoIconButton extends StatelessWidget {
  final bool isDark;
  final Color color;
  final VoidCallback onTap;

  const _InfoIconButton({
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(Icons.info_outline_rounded, size: 18, color: color),
        ),
      ),
    );
  }
}

class _StepTrackingInfoSheet extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final Color accentColor;

  const _StepTrackingInfoSheet({
    required this.isDark,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF2F2F7);
    final subColor = textColor.withValues(alpha: 0.6);
    final handleColor = isDark ? Colors.white24 : Colors.black26;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  size: 28,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t.stepsDetTrackInfoTitle,
                style: font(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _InfoParagraph(text: t.stepsDetTrackInfoP1, color: subColor),
              const SizedBox(height: 14),
              _InfoParagraph(text: t.stepsDetTrackInfoP2, color: subColor),
              const SizedBox(height: 14),
              _InfoParagraph(text: t.stepsDetTrackInfoP3, color: subColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoParagraph extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoParagraph({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Weekly Rings
// ─────────────────────────────────────────────

class _WeeklyRings extends StatelessWidget {
  final List<int> weeklySteps; // index 0=Mon … 6=Sun
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final int stepGoal;

  const _WeeklyRings({
    required this.weeklySteps,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.stepGoal,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final font = GoogleFonts.plusJakartaSans;
    final dimColor = textColor.withValues(alpha: 0.35);
    // Today's weekday index: Mon=0 … Sun=6
    final int todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    final mondayLabel = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final labels = List.generate(
      7,
      (i) => DateFormat('EEE', localeName).format(mondayLabel.add(Duration(days: i))),
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final steps = weeklySteps.length > i ? weeklySteps[i] : 0;
          final double progress = (steps / stepGoal).clamp(0.0, 1.0);
          final bool isToday = i == todayIdx;
          // Future days (after today this week) — no data yet
          final bool isFuture = i > todayIdx;

          return Column(
            children: [
              _RingCircle(
                progress: isFuture ? 0.0 : progress,
                accentColor: accentColor,
                isDark: isDark,
                isToday: isToday,
                isFuture: isFuture,
                textColor: textColor,
              ),
              const SizedBox(height: 6),
              Text(
                isToday ? t.detailToday : labels[i],
                style: font(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? accentColor : dimColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RingCircle extends StatefulWidget {
  final double progress;
  final Color accentColor;
  final bool isDark;
  final bool isToday;
  final bool isFuture;
  final Color textColor;

  const _RingCircle({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.isToday,
    required this.isFuture,
    required this.textColor,
  });

  @override
  State<_RingCircle> createState() => _RingCircleState();
}

class _RingCircleState extends State<_RingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Stagger by index isn't available here, just forward
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(38, 38),
        painter: _RingPainter(
          progress: _anim.value * widget.progress,
          accentColor: widget.accentColor,
          isDark: widget.isDark,
          isToday: widget.isToday,
          isFuture: widget.isFuture,
          textColor: widget.textColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isDark;
  final bool isToday;
  final bool isFuture;
  final Color textColor;

  const _RingPainter({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.isToday,
    required this.isFuture,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;
    const strokeW = 3.5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: isFuture ? 0.06 : 0.10)
            : Colors.black.withValues(alpha: isFuture ? 0.06 : 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center dot — solid for today, small dim for others
    if (isToday) {
      canvas.drawCircle(center, 4, Paint()..color = accentColor);
      canvas.drawCircle(
        center,
        2,
        Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
      );
    } else if (!isFuture && progress >= 1.0) {
      // Goal met — small filled dot
      canvas.drawCircle(
        center,
        3,
        Paint()..color = accentColor.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accentColor != accentColor ||
      old.isToday != isToday;
}

// ─────────────────────────────────────────────
// Distance Card
// ─────────────────────────────────────────────

class _DistanceCard extends StatelessWidget {
  final int steps;
  final int stepGoal;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  // Average stride length ~0.762 m
  static const double _strideM = 0.762;

  const _DistanceCard({
    required this.steps,
    required this.stepGoal,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final double km = (steps * _strideM) / 1000.0;
    final double goalKm = (stepGoal * _strideM) / 1000.0;
    // Round goal km to nearest whole number for display
    final int goalKmDisplay = goalKm.round();
    final String distStr = km >= 10
        ? km.toStringAsFixed(1)
        : km.toStringAsFixed(2);

    final font = GoogleFonts.plusJakartaSans;
    final dimColor = textColor.withValues(alpha: 0.35);
    final subColor = textColor.withValues(alpha: 0.55);

    // Progress toward the dynamic goal distance
    final double routeProgress = goalKm > 0 ? (km / goalKm).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: number + label + splits ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.detailDistance,
                  style: font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dimColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distStr,
                      style: font(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 6, start: 5),
                      child: Text(
                        t.detailKm,
                        style: font(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  t.stepsDetDistanceSub((steps * _strideM).round(), steps),
                  style: font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: dimColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── Right: vertical route track ──
          SizedBox(
            width: 48,
            height: 110,
            child: CustomPaint(
              painter: _RoutePainter(
                progress: routeProgress,
                accentColor: accentColor,
                dimColor: dimColor,
                isDark: isDark,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Far right: 0 km / 5 km labels ──
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$goalKmDisplay ${t.detailKm}',
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dimColor,
                ),
              ),
              SizedBox(height: 80),
              Text(
                '0',
                style: font(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dimColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color accentColor;
  final Color dimColor;
  final bool isDark;

  const _RoutePainter({
    required this.progress,
    required this.accentColor,
    required this.dimColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cx = 24;
    const double dotR = 5.0;
    const double endDotR = 4.0;
    const double dashLen = 5.0;
    const double dashGap = 4.0;

    final trackPaint = Paint()
      ..color = dimColor.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final filledPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double topY = dotR;
    final double bottomY = size.height - dotR;
    final double progressY = bottomY - (bottomY - topY) * progress;

    // Draw dashed track — unfilled portion (above progress dot)
    double y = topY;
    while (y < progressY - dotR) {
      final end = math.min(y + dashLen, progressY - dotR);
      canvas.drawLine(Offset(cx, y), Offset(cx, end), trackPaint);
      y += dashLen + dashGap;
    }

    // Draw solid filled track — below progress dot to bottom
    canvas.drawLine(
      Offset(cx, progressY + dotR),
      Offset(cx, bottomY),
      filledPaint,
    );

    // Bottom dot (start)
    canvas.drawCircle(
      Offset(cx, bottomY),
      endDotR,
      Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.black,
    );

    // Progress dot (current position)
    canvas.drawCircle(
      Offset(cx, progressY),
      dotR,
      Paint()..color = accentColor,
    );
    // Inner white dot
    canvas.drawCircle(
      Offset(cx, progressY),
      dotR * 0.45,
      Paint()..color = isDark ? const Color(0xFF1C1C1E) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}

// ─────────────────────────────────────────────
// Energy Bar
// ─────────────────────────────────────────────

class _EnergyBar extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final Color accentColor;
  final bool isDark;
  final Color textColor;

  const _EnergyBar({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_EnergyBar> createState() => _EnergyBarState();
}

class _EnergyBarState extends State<_EnergyBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final font = GoogleFonts.plusJakartaSans;
    final pct = (widget.progress * 100).round();
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Label
          Text(
            t.detailDailyGoal,
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.textColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 12),
          // Bar track
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: _anim.value * widget.progress,
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Percentage
          Text(
            '$pct%',
            style: font(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bar Chart
// ─────────────────────────────────────────────

class _StepsBarChart extends StatefulWidget {
  final List<int> bars;
  final int maxVal;
  final Color accentColor;
  final bool isDark;
  final Color textColor;
  final bool isDaily;
  final List<String> weekLabels;

  const _StepsBarChart({
    required this.bars,
    required this.maxVal,
    required this.accentColor,
    required this.isDark,
    required this.textColor,
    required this.isDaily,
    required this.weekLabels,
  });

  @override
  State<_StepsBarChart> createState() => _StepsBarChartState();
}

class _StepsBarChartState extends State<_StepsBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_StepsBarChart old) {
    super.didUpdateWidget(old);
    if (old.bars != widget.bars || old.isDaily != widget.isDaily) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _hourLabel(int hour) {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('h a', localeName).format(DateTime(2020, 1, 1, hour));
  }

  String _fmtAxis(int n) {
    if (n >= 1000) return '${(n / 1000).round()}K';
    return n.toString();
  }

  int _roundMax(int val) {
    if (val <= 0) return 5000;
    final magnitude = math.pow(10, (math.log(val) / math.ln10).floor()).toInt();
    return ((val / magnitude).ceil()) * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final axisColor = widget.textColor.withValues(alpha: 0.15);
    final labelColor = widget.textColor.withValues(alpha: 0.45);
    final font = GoogleFonts.plusJakartaSans;
    final int barCount = widget.bars.length;
    final bool manyBars = barCount > 12;

    // No data yet — show clean empty state
    final bool hasData = widget.bars.any((v) => v > 0);
    if (!hasData && widget.isDaily) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              t.stepsDetEmpty,
              style: font(
                fontSize: 13,
                color: labelColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 40),
            child: Container(height: 1, color: axisColor),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 40),
            child: LayoutBuilder(
              builder: (ctx, bc) {
                final List<int> indices = [0, (barCount * 1 / 3).round().clamp(0, barCount - 1), (barCount * 2 / 3).round().clamp(0, barCount - 1), barCount - 1];
                return Row(
                  children: List.generate(barCount, (i) => Expanded(
                    child: indices.contains(i)
                        ? Text(_hourLabel(i), textAlign: TextAlign.center,
                            style: font(color: labelColor, fontSize: 9, fontWeight: FontWeight.w500))
                        : const SizedBox.shrink(),
                  )),
                );
              },
            ),
          ),
        ],
      );
    }

    final int roundedMax = _roundMax(widget.maxVal);
    final yLabels = [
      0,
      (roundedMax * 0.25).round(),
      (roundedMax * 0.5).round(),
      (roundedMax * 0.75).round(),
      roundedMax,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels
              SizedBox(
                width: 32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yLabels.reversed
                      .map(
                        (v) => Text(
                          _fmtAxis(v),
                          style: font(
                            color: labelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Chart area — CustomPaint draws grid + bars together
              Expanded(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    painter: _BarChartPainter(
                      bars: widget.bars,
                      roundedMax: roundedMax,
                      accentColor: widget.accentColor,
                      gridColor: axisColor,
                      progress: _anim.value,
                      gridLevels: 4,
                      barSpacing: manyBars ? 2.0 : 4.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Baseline
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 40),
          child: Container(height: 1, color: axisColor),
        ),
        const SizedBox(height: 6),

        // X-axis labels
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 40),
          child: widget.isDaily
              ? LayoutBuilder(
                  builder: (ctx, bc) {
                    // 4 evenly-spaced labels across the bar range
                    final int count = barCount;
                    if (count == 0) return const SizedBox.shrink();
                    final List<int> indices = [
                      0,
                      (count * 1 / 3).round().clamp(0, count - 1),
                      (count * 2 / 3).round().clamp(0, count - 1),
                      count - 1,
                    ];
                    return Row(
                      children: List.generate(count, (i) {
                        final show = indices.contains(i);
                        return Expanded(
                          child: show
                              ? Text(
                                  _hourLabel(i),
                                  textAlign: TextAlign.center,
                                  style: font(
                                    color: labelColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      }),
                    );
                  },
                )
              : Row(
                  children: List.generate(barCount, (i) {
                    final label = i < widget.weekLabels.length
                        ? widget.weekLabels[i]
                        : '';
                    return Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: font(
                          color: labelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainter — draws grid lines THEN solid bars on top
// ─────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<int> bars;
  final int roundedMax;
  final Color accentColor;
  final Color gridColor;
  final double progress; // 0.0 → 1.0 animation
  final int gridLevels;
  final double barSpacing;

  const _BarChartPainter({
    required this.bars,
    required this.roundedMax,
    required this.accentColor,
    required this.gridColor,
    required this.progress,
    required this.gridLevels,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    // 1. Draw grid lines first (behind bars)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 1; i <= gridLevels; i++) {
      final y = size.height * (1 - i / gridLevels);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw bars on top — solid, no transparency issues
    final int count = bars.length;
    final double slotW = size.width / count;
    const double cornerRadius = 6.0;

    for (int i = 0; i < count; i++) {
      if (bars[i] <= 0) continue;

      final double ratio = roundedMax > 0
          ? (bars[i] / roundedMax).clamp(0.0, 1.0)
          : 0.0;
      final double barH = size.height * ratio * progress;
      if (barH < 1) continue;

      final double left = slotW * i + barSpacing;
      final double right = slotW * (i + 1) - barSpacing;
      final double top = size.height - barH;
      final double bottom = size.height;

      final rect = RRect.fromLTRBR(
        left,
        top,
        right,
        bottom,
        const Radius.circular(cornerRadius),
      );

      final barPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress ||
      old.bars != bars ||
      old.accentColor != accentColor ||
      old.roundedMax != roundedMax;
}

// ─────────────────────────────────────────────
// Monthly Heatmap
// ─────────────────────────────────────────────

class _MonthHeatmap extends StatelessWidget {
  final Map<int, int> monthlySteps; // day (1-indexed) → steps
  final bool isLoading;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final int stepGoal;

  const _MonthHeatmap({
    required this.monthlySteps,
    required this.isLoading,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.stepGoal,
  });

  /// Returns opacity 0.0–1.0 based on steps vs goal.
  /// 0 steps → 0.08 (barely visible ghost)
  /// goal met → 1.0 (full accent color)
  double _cellOpacity(int? steps) {
    if (steps == null || steps <= 0) return 0.08;
    final ratio = (steps / stepGoal).clamp(0.0, 1.0);
    // Map 0→0.12, 0.25→0.35, 0.5→0.55, 0.75→0.75, 1.0→1.0
    return 0.12 + ratio * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final font = GoogleFonts.plusJakartaSans;

    // Month name
    final monthLabel = DateFormat('MMMM yyyy', localeName).format(now);

    // First weekday of month: Mon=0 … Sun=6
    final int firstWeekday = (DateTime(year, month, 1).weekday - 1).clamp(0, 6);

    // Total cells = leading empty + days
    final int totalCells = firstWeekday + daysInMonth;
    // Rows of 7
    final int rows = (totalCells / 7).ceil();

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final dayLabels = List.generate(
      7,
      (i) => DateFormat('EEEEE', localeName).format(monday.add(Duration(days: i))),
    );
    final labelColor = textColor.withValues(alpha: 0.4);
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              // Legend
              Row(
                children: [
                  Text(
                    t.detailLess,
                    style: font(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final opacity = 0.12 + (i / 4) * 0.88;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsetsDirectional.only(start: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    t.detailMore,
                    style: font(
                      fontSize: 11,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Day-of-week header + grid — fills full card width
          LayoutBuilder(
            builder: (context, constraints) {
              const int cols = 7;
              const double gap = 4.0;
              final double cellSize =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              Widget buildCell(Color color, {bool isToday = false}) {
                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday
                        ? Border.all(color: accentColor, width: 1.5)
                        : null,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      cols,
                      (i) => SizedBox(
                        width: cellSize,
                        child: Center(
                          child: Text(
                            dayLabels[i],
                            style: font(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Grid rows
                  isLoading
                      ? const SizedBox(
                          height: 80,
                          child: Center(child: BouncingDotsLoader()),
                        )
                      : Column(
                          children: List.generate(rows, (row) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: gap),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(cols, (col) {
                                  final cellIndex = row * cols + col;
                                  final day = cellIndex - firstWeekday + 1;
                                  final isValid =
                                      day >= 1 && day <= daysInMonth;
                                  final isFuture = day > now.day;

                                  if (!isValid) {
                                    return SizedBox(
                                      width: cellSize,
                                      height: cellSize,
                                    );
                                  }

                                  final steps = monthlySteps[day];
                                  final Color cellColor = isFuture
                                      ? emptyColor
                                      : accentColor.withValues(
                                          alpha: _cellOpacity(steps),
                                        );

                                  return buildCell(
                                    cellColor,
                                    isToday: day == now.day,
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

ThemeData _pickerTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) return Theme.of(context);
  const bg = Color(0xFF252528);
  return Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      surface: bg,
      surfaceContainerHigh: bg,
      surfaceContainerHighest: bg,
      surfaceContainer: bg,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: bg),
    datePickerTheme: const DatePickerThemeData(backgroundColor: bg),
    timePickerTheme: const TimePickerThemeData(backgroundColor: bg),
  );
}
