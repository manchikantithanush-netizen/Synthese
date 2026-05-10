import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class SleepDetailPage extends StatefulWidget {
  final int todaySleepMinutes;
  final int goalMinutes;
  final ValueChanged<int>? onTodaySleepMinutesAdded;

  const SleepDetailPage({
    super.key,
    this.todaySleepMinutes = 0,
    this.goalMinutes = 480,
    this.onTodaySleepMinutesAdded,
  });

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

// Sleep stage breakdown
class _SleepData {
  final int totalMinutes;
  final int remMinutes;
  final int coreMinutes;
  final int deepMinutes;
  final int awakeMinutes;
  final int asleepMinutes;
  final int inBedMinutes;

  const _SleepData({
    this.totalMinutes = 0,
    this.remMinutes = 0,
    this.coreMinutes = 0,
    this.deepMinutes = 0,
    this.awakeMinutes = 0,
    this.asleepMinutes = 0,
    this.inBedMinutes = 0,
  });

  bool get hasData => totalMinutes > 0;
}

// A single timed sleep segment
class _SleepSegment {
  final DateTime from;
  final DateTime to;
  final String stage; // 'rem','light','deep','awake','sleeping'

  const _SleepSegment({
    required this.from,
    required this.to,
    required this.stage,
  });

  int get minutes => to.difference(from).inMinutes;
}

enum _SleepPhase { inBed, asleep, awake, light, deep, rem }

extension _SleepPhaseX on _SleepPhase {
  String get label {
    switch (this) {
      case _SleepPhase.inBed:
        return 'In Bed';
      case _SleepPhase.asleep:
        return 'Asleep';
      case _SleepPhase.awake:
        return 'Awake';
      case _SleepPhase.light:
        return 'Core';
      case _SleepPhase.deep:
        return 'Deep';
      case _SleepPhase.rem:
        return 'REM';
    }
  }
}

class _SleepDetailPageState extends State<SleepDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  _SleepData _data = const _SleepData();
  bool _loading = true;
  List<_SleepSegment> _segments = [];

  // Sleep goal in minutes (sourced from onboarding stage 2; default 480 = 8h)
  int get _goalMinutes => widget.goalMinutes;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fetchSleepData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSleepData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final key = _dateKey(DateTime.now());
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(key)
          .get();
      final data = doc.data();

      // Load phase totals
      final phases = data?['manualSleepPhases'] as Map<String, dynamic>?;
      final rem = (phases?['rem'] as num?)?.toInt() ?? 0;
      final light = (phases?['light'] as num?)?.toInt() ?? 0;
      final deep = (phases?['deep'] as num?)?.toInt() ?? 0;
      final awake = (phases?['awake'] as num?)?.toInt() ?? 0;
      final asleep = (phases?['asleep'] as num?)?.toInt() ?? 0;
      final inBed = (phases?['inBed'] as num?)?.toInt() ?? 0;
      final total = rem + light + deep + awake + asleep + inBed;

      // Load segments for the chart
      final rawSegs = data?['manualSleepSegments'] as List<dynamic>?;
      final loadedSegments =
          rawSegs == null
                ? <_SleepSegment>[]
                : rawSegs
                      .map(
                        (e) => _SleepSegment(
                          from: (e['from'] as Timestamp).toDate(),
                          to: (e['to'] as Timestamp).toDate(),
                          stage: e['stage'] as String? ?? 'asleep',
                        ),
                      )
                      .toList()
            ..sort((a, b) => a.from.compareTo(b.from));

      if (mounted) {
        setState(() {
          _data = _SleepData(
            totalMinutes: total,
            remMinutes: rem,
            coreMinutes: light,
            deepMinutes: deep,
            awakeMinutes: awake,
            asleepMinutes: asleep,
            inBedMinutes: inBed,
          );
          _segments = loadedSegments;
        });
        _ctrl.forward(from: 0);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtHours(int mins) {
    if (mins == 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<Map<String, int>> _loadManualSleepPhases(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return <String, int>{};
    final key = _dateKey(day);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(key)
        .get();
    final phases = doc.data()?['manualSleepPhases'] as Map<String, dynamic>?;
    if (phases == null) return <String, int>{};
    return <String, int>{
      'rem': (phases['rem'] as num?)?.toInt() ?? 0,
      'light': (phases['light'] as num?)?.toInt() ?? 0,
      'deep': (phases['deep'] as num?)?.toInt() ?? 0,
      'awake': (phases['awake'] as num?)?.toInt() ?? 0,
      'asleep': (phases['asleep'] as num?)?.toInt() ?? 0,
      'inBed': (phases['inBed'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> _addManualSleepPhaseMinutes({
    required DateTime start,
    required DateTime end,
    required _SleepPhase phase,
  }) async {
    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final key = _dateKey(end);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dashboardDaily')
        .doc(key);
    final snapshot = await docRef.get();
    final current =
        (snapshot.data()?['manualSleepPhases'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    int rem = (current['rem'] as num?)?.toInt() ?? 0;
    int light = (current['light'] as num?)?.toInt() ?? 0;
    int deep = (current['deep'] as num?)?.toInt() ?? 0;
    int awake = (current['awake'] as num?)?.toInt() ?? 0;
    int asleep = (current['asleep'] as num?)?.toInt() ?? 0;
    int inBed = (current['inBed'] as num?)?.toInt() ?? 0;
    switch (phase) {
      case _SleepPhase.rem:
        rem = (rem + minutes).clamp(0, 1440).toInt();
        break;
      case _SleepPhase.light:
        light = (light + minutes).clamp(0, 1440).toInt();
        break;
      case _SleepPhase.deep:
        deep = (deep + minutes).clamp(0, 1440).toInt();
        break;
      case _SleepPhase.awake:
        awake = (awake + minutes).clamp(0, 1440).toInt();
        break;
      case _SleepPhase.asleep:
        asleep = (asleep + minutes).clamp(0, 1440).toInt();
        break;
      case _SleepPhase.inBed:
        inBed = (inBed + minutes).clamp(0, 1440).toInt();
        break;
    }

    await docRef.set({
      'manualSleepPhases': <String, int>{
        'rem': rem,
        'light': light,
        'deep': deep,
        'awake': awake,
        'asleep': asleep,
        'inBed': inBed,
      },
      'manualSleepTotal': rem + light + deep + awake + asleep + inBed,
      // Append this segment to the chart list
      'manualSleepSegments': FieldValue.arrayUnion([
        {
          'from': Timestamp.fromDate(start),
          'to': Timestamp.fromDate(end),
          'stage': phase.name,
        },
      ]),
      'dateKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    final newSegment = _SleepSegment(from: start, to: end, stage: phase.name);
    setState(() {
      _data = _SleepData(
        totalMinutes: _data.totalMinutes + minutes,
        remMinutes: phase == _SleepPhase.rem
            ? _data.remMinutes + minutes
            : _data.remMinutes,
        coreMinutes: phase == _SleepPhase.light
            ? _data.coreMinutes + minutes
            : _data.coreMinutes,
        deepMinutes: phase == _SleepPhase.deep
            ? _data.deepMinutes + minutes
            : _data.deepMinutes,
        awakeMinutes: phase == _SleepPhase.awake
            ? _data.awakeMinutes + minutes
            : _data.awakeMinutes,
        asleepMinutes: phase == _SleepPhase.asleep
            ? _data.asleepMinutes + minutes
            : _data.asleepMinutes,
        inBedMinutes: phase == _SleepPhase.inBed
            ? _data.inBedMinutes + minutes
            : _data.inBedMinutes,
      );
      _segments = [..._segments, newSegment]
        ..sort((a, b) => a.from.compareTo(b.from));
    });

    if (_isSameDay(end, DateTime.now())) {
      widget.onTodaySleepMinutesAdded?.call(minutes);
    }
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
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
      builder: (_) => _SleepPhaseAddSheet(
        accentColor: accentColor,
        isDark: isDark,
        textColor: textColor,
        cardColor: cardColor,
        onSave: ({required start, required end, required phase}) =>
            _addManualSleepPhaseMinutes(start: start, end: end, phase: phase),
      ),
    );
  }

  ({String prefix, String keyword, String suffix}) _buildInsight() {
    final int mins = _data.totalMinutes;
    if (mins == 0) {
      return (prefix: 'No sleep data ', keyword: 'recorded', suffix: ' yet.');
    }
    final double hrs = mins / 60;
    if (hrs >= 8) {
      return (
        prefix: 'You got a ',
        keyword: 'great night\'s sleep',
        suffix: '.',
      );
    }
    if (hrs >= 7) {
      return (prefix: 'You slept ', keyword: 'well', suffix: ' last night.');
    }
    if (hrs >= 6) {
      return (
        prefix: 'You got ',
        keyword: 'decent sleep',
        suffix: ' last night.',
      );
    }
    if (hrs >= 4) {
      return (
        prefix: 'You had a ',
        keyword: 'short night',
        suffix: ' — try to rest more.',
      );
    }
    return (prefix: 'You need ', keyword: 'more sleep', suffix: ' tonight.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final font = GoogleFonts.plusJakartaSans;
    final insight = _buildInsight();

    // Ring colors — matching the reference image style
    const Color remColor = Color(0xFF5B8A5F); // green
    const Color coreColor = Color(0xFFE07B39); // orange
    const Color deepColor = Color(0xFF6B6B6B); // grey
    const Color awakeColor = Color(0xFFB0A090); // light tan

    final int total = _data.totalMinutes;
    final double remRatio = total > 0 ? _data.remMinutes / total : 0;
    final double coreRatio = total > 0 ? _data.coreMinutes / total : 0;
    final double deepRatio = total > 0 ? _data.deepMinutes / total : 0;
    final double totalProgress = (total / _goalMinutes).clamp(0.0, 1.0);

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
              fit: StackFit.expand,
              children: [
                // Accent glow
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 260,
                  child: IgnorePointer(
                    child: Container(
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
                        // Back button
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
                                icon: Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: textColor,
                                ),
                                label: Text(
                                  'Add data',
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
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Insight text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: RichText(
                            text: TextSpan(
                              style: font(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(text: insight.prefix),
                                TextSpan(
                                  text: insight.keyword,
                                  style: TextStyle(color: accentColor),
                                ),
                                TextSpan(text: insight.suffix),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: _loading
                                ? const SizedBox(
                                    height: 200,
                                    child: Center(child: BouncingDotsLoader()),
                                  )
                                : Column(
                                    children: [
                                      // "You slept for X.XXh" header
                                      Column(
                                        children: [
                                          Text(
                                            'You slept for',
                                            style: font(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: total > 0
                                                      ? _fmtHours(total)
                                                      : '--',
                                                  style: font(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.w800,
                                                    color: textColor,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Goal ${_fmtHours(_goalMinutes)}',
                                            style: font(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textColor.withValues(
                                                alpha: 0.45,
                                              ),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 28),

                                      // Concentric rings
                                      AnimatedBuilder(
                                        animation: _anim,
                                        builder: (_, __) => SizedBox(
                                          width: 220,
                                          height: 220,
                                          child: CustomPaint(
                                            painter: _SleepRingsPainter(
                                              progress: _anim.value,
                                              totalProgress: totalProgress,
                                              remRatio: remRatio,
                                              coreRatio: coreRatio,
                                              deepRatio: deepRatio,
                                              remColor: remColor,
                                              coreColor: coreColor,
                                              deepColor: deepColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      // Stage breakdown — wraps to multiple
                                      // rows so 6 stages with minute-precision
                                      // values stay readable.
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 4,
                                        runSpacing: 18,
                                        children: [
                                          if (_data.remMinutes > 0)
                                            _StageChip(
                                              label: 'REM',
                                              value: _fmtHours(
                                                _data.remMinutes,
                                              ),
                                              color: remColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.coreMinutes > 0)
                                            _StageChip(
                                              label: 'Core',
                                              value: _fmtHours(
                                                _data.coreMinutes,
                                              ),
                                              color: coreColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.deepMinutes > 0)
                                            _StageChip(
                                              label: 'Deep',
                                              value: _fmtHours(
                                                _data.deepMinutes,
                                              ),
                                              color: deepColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.awakeMinutes > 0)
                                            _StageChip(
                                              label: 'Awake',
                                              value: _fmtHours(
                                                _data.awakeMinutes,
                                              ),
                                              color: awakeColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.asleepMinutes > 0)
                                            _StageChip(
                                              label: 'Asleep',
                                              value: _fmtHours(
                                                _data.asleepMinutes,
                                              ),
                                              color: const Color(0xFF5E5CE6),
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          if (_data.inBedMinutes > 0)
                                            _StageChip(
                                              label: 'In Bed',
                                              value: _fmtHours(
                                                _data.inBedMinutes,
                                              ),
                                              color: const Color(0xFF636366),
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                          // If no stage data, show total only
                                          if (_data.remMinutes == 0 &&
                                              _data.coreMinutes == 0 &&
                                              _data.deepMinutes == 0 &&
                                              _data.asleepMinutes == 0 &&
                                              _data.inBedMinutes == 0 &&
                                              total > 0)
                                            _StageChip(
                                              label: 'Total',
                                              value: _fmtHours(total),
                                              color: accentColor,
                                              isDark: isDark,
                                              textColor: textColor,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sleep stage timeline chart — always shown
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: _SleepTimeline(
                              segments: _segments,
                              isDark: isDark,
                              textColor: textColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sleep heatmap
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SleepHeatmap(
                            cardColor: cardColor,
                            textColor: textColor,
                            accentColor: accentColor,
                            isDark: isDark,
                            todaySleepMinutes: _data.totalMinutes,
                            goalMinutes: _goalMinutes,
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

class _SleepPhaseAddSheet extends StatefulWidget {
  const _SleepPhaseAddSheet({
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
  final Future<void> Function({
    required DateTime start,
    required DateTime end,
    required _SleepPhase phase,
  })
  onSave;

  @override
  State<_SleepPhaseAddSheet> createState() => _SleepPhaseAddSheetState();
}

class _SleepPhaseAddSheetState extends State<_SleepPhaseAddSheet> {
  late DateTime _start;
  late DateTime _end;
  _SleepPhase _selectedPhase = _SleepPhase.asleep;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: end = now, start = 8h ago (typical sleep)
    _end = now;
    _start = now.subtract(const Duration(hours: 8));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) =>
          Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || date == null) return;
    setState(() {
      final updated = DateTime(
        date.year,
        date.month,
        date.day,
        initial.hour,
        initial.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
      _error = null;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) =>
          Theme(data: _pickerTheme(context), child: child!),
    );
    if (!mounted || time == null) return;
    setState(() {
      final updated = DateTime(
        initial.year,
        initial.month,
        initial.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSave(start: _start, end: _end, phase: _selectedPhase);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save. Please try again.';
        _saving = false;
      });
    }
  }

  String _fmt(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour == 0
        ? 12
        : dt.hour > 12
        ? dt.hour - 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _duration() {
    final mins = _end.difference(_start).inMinutes;
    if (mins <= 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = widget.textColor;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final pillBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final divColor = isDark
        ? Colors.white12
        : Colors.black.withValues(alpha: 0.07);
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
                // ── top bar (fixed) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SleepSheetTopButton(
                        isDark: isDark,
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textColor,
                        ),
                      ),
                      _SleepSheetTopButton(
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
                            : Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: textColor,
                              ),
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
                  child: Icon(
                    Icons.bedtime_rounded,
                    size: 34,
                    color: widget.accentColor,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── title + duration ──
              Center(
                child: Text(
                  'Sleep',
                  style: font(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _duration(),
                  style: font(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: widget.accentColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── phase card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _SleepPhase.values.map((p) {
                      final isLast = p == _SleepPhase.values.last;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _selectedPhase = p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    p.label,
                                    style: font(fontSize: 16, color: textColor),
                                  ),
                                  const Spacer(),
                                  if (_selectedPhase == p)
                                    Icon(
                                      Icons.check_rounded,
                                      color: widget.accentColor,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 20,
                              color: divColor,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── starts / ends card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _SleepSheetRow(
                        label: 'Starts',
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _pickDate(isStart: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _fmt(_start),
                                  style: font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _pickTime(isStart: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _fmtTime(_start),
                                  style: font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 16,
                        color: divColor,
                      ),
                      _SleepSheetRow(
                        label: 'Ends',
                        subColor: subColor,
                        textColor: textColor,
                        font: font,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _pickDate(isStart: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _fmt(_end),
                                  style: font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _pickTime(isStart: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _fmtTime(_end),
                                  style: font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
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

// ─────────────────────────────────────────────
// Stage chip
// ─────────────────────────────────────────────

class _StageChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final Color textColor;

  const _StageChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: font(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: font(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Concentric sleep rings painter
// ─────────────────────────────────────────────

class _SleepRingsPainter extends CustomPainter {
  final double progress; // animation 0→1
  final double totalProgress; // total sleep / goal
  final double remRatio;
  final double coreRatio;
  final double deepRatio;
  final Color remColor;
  final Color coreColor;
  final Color deepColor;
  final bool isDark;

  const _SleepRingsPainter({
    required this.progress,
    required this.totalProgress,
    required this.remRatio,
    required this.coreRatio,
    required this.deepRatio,
    required this.remColor,
    required this.coreColor,
    required this.deepColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double strokeW = 18.0;
    const double gap = 10.0;

    // 3 rings: outer=total, middle=REM, inner=core
    final double r1 = size.width / 2 - strokeW / 2;
    final double r2 = r1 - strokeW - gap;
    final double r3 = r2 - strokeW - gap;

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    void drawRing(double radius, double ratio, Color color) {
      // Track
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      // Arc
      if (ratio > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * ratio * progress,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Outer ring: total sleep progress
    drawRing(r1, totalProgress, deepColor);
    // Middle ring: REM
    drawRing(r2, remRatio, remColor);
    // Inner ring: core/light
    drawRing(r3, coreRatio, coreColor);
  }

  @override
  bool shouldRepaint(_SleepRingsPainter old) =>
      old.progress != progress ||
      old.totalProgress != totalProgress ||
      old.remRatio != remRatio ||
      old.coreRatio != coreRatio;
}

// ─────────────────────────────────────────────
// Sleep Timeline — horizontal Gantt-style
// ─────────────────────────────────────────────

class _SleepTimeline extends StatelessWidget {
  final List<_SleepSegment> segments;
  final bool isDark;
  final Color textColor;

  const _SleepTimeline({
    required this.segments,
    required this.isDark,
    required this.textColor,
  });

  // Stage depth level: higher = deeper sleep (drawn lower on chart)
  static int _stageLevel(String stage) {
    switch (stage) {
      case 'inBed':
        return 0;
      case 'awake':
        return 1;
      case 'asleep':
        return 2;
      case 'light':
        return 3;
      case 'rem':
        return 4;
      case 'deep':
        return 5;
      default:
        return 2;
    }
  }

  static Color _stageColor(String stage) {
    switch (stage) {
      case 'inBed':
        return const Color(0xFF636366); // grey
      case 'awake':
        return const Color(0xFF5B8DEF); // blue
      case 'asleep':
        return const Color(0xFF5E5CE6); // indigo
      case 'light':
        return const Color(0xFF9B59B6); // purple
      case 'rem':
        return const Color(0xFFE74C8B); // pink
      case 'deep':
        return const Color(0xFF2ECC71); // green
      default:
        return const Color(0xFF5E5CE6);
    }
  }

  static String _stageLabel(String stage) {
    switch (stage) {
      case 'awake':
        return 'Awake';
      case 'light':
        return 'Core';
      case 'rem':
        return 'REM';
      case 'deep':
        return 'Deep';
      case 'asleep':
        return 'Asleep';
      case 'inBed':
        return 'In Bed';
      default:
        return stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final labelColor = textColor.withValues(alpha: 0.4);

    // Filter to today's segments only
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd   = todayStart.add(const Duration(days: 1));
    final todaySegs  = segments.where((s) =>
        s.to.isAfter(todayStart) && s.from.isBefore(todayEnd)).toList()
      ..sort((a, b) => a.from.compareTo(b.from));

    // Empty state
    if (todaySegs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep Stages',
              style: font(fontSize: 15, fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 40),
          Center(child: Text('Add a sleep entry to see your chart',
              style: font(fontSize: 13, color: labelColor))),
          const SizedBox(height: 40),
        ],
      );
    }

    final DateTime chartStart = todaySegs.first.from;
    final DateTime chartEnd   = todaySegs.last.to;
    final int totalMins = math.max(chartEnd.difference(chartStart).inMinutes, 1);

    // Build exactly 4 evenly-spaced X-axis labels across the range
    String _hourLabel(DateTime dt) {
      final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$h $period';
    }

    final List<String> xLabels = [];
    final List<double> xPositions = [];
    for (int i = 0; i < 4; i++) {
      final frac = i / 3.0;
      final dt = chartStart.add(Duration(
          minutes: (totalMins * frac).round()));
      xLabels.add(_hourLabel(dt));
      xPositions.add(frac);
    }

    // Unique stages for legend
    final usedStages = todaySegs.map((s) => s.stage).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep Stages',
            style: font(fontSize: 15, fontWeight: FontWeight.w700,
                color: textColor)),

        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            return Column(
              children: [
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    size: Size(w, 160),
                    painter: _SleepGanttPainter(
                      segments: todaySegs,
                      totalMins: totalMins,
                      start: chartStart,
                      isDark: isDark,
                    ),
                  ),
                ),
                Container(height: 1,
                    color: textColor.withValues(alpha: 0.08)),
                const SizedBox(height: 6),
                // X-axis: 4 labels
                SizedBox(
                  height: 18,
                  child: LayoutBuilder(
                    builder: (ctx, bc) {
                      const double leftMargin = 52.0;
                      const double rightPad = 8.0;
                      final double chartW = bc.maxWidth - leftMargin - rightPad;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(4, (i) {
                          final double x = leftMargin + xPositions[i] * chartW;
                          const double labelW = 48.0;
                          return Positioned(
                            left: (x - labelW / 2).clamp(0.0,
                                bc.maxWidth - labelW),
                            top: 0,
                            child: SizedBox(
                              width: labelW,
                              child: Text(
                                xLabels[i],
                                textAlign: TextAlign.center,
                                style: font(
                                  fontSize: 10,
                                  color: labelColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: usedStages.map((stage) {
            final mins = todaySegs
                .where((s) => s.stage == stage)
                .fold(0, (a, s) => a + s.minutes);
            final h = mins ~/ 60;
            final m = mins % 60;
            final timeStr = h > 0
                ? '${h}h${m > 0 ? ' ${m}m' : ''}'
                : '${m}m';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _stageColor(stage),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$timeStr  ${_stageLabel(stage)}',
                  style: font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SleepGanttPainter extends CustomPainter {
  final List<_SleepSegment> segments;
  final int totalMins;
  final DateTime start;
  final bool isDark;

  const _SleepGanttPainter({
    required this.segments,
    required this.totalMins,
    required this.start,
    required this.isDark,
  });

  static const int _levels =
      6; // inBed=0, awake=1, asleep=2, light=3, rem=4, deep=5
  static const double _barH = 14.0;
  static const double _barR = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalMins <= 0) return;

    // Reserve left margin for Y labels, right padding
    const double leftMargin = 52.0;
    const double rightPad = 8.0;
    final double chartW = size.width - leftMargin - rightPad;

    final double levelH = size.height / _levels;

    // Draw faint horizontal lane lines
    final lanePaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    for (int i = 0; i < _levels; i++) {
      final y = levelH * i + levelH / 2;
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + chartW, y),
        lanePaint,
      );
    }

    // Y-axis stage labels on the LEFT, vertically centered in each lane
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 9,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
      fontWeight: FontWeight.w600,
    );
    // Top→bottom: Deep(0), REM(1), Light(2), Asleep(3), Awake(4), In Bed(5)
    const stageNames = ['Deep', 'REM', 'Core', 'Asleep', 'Awake', 'In Bed'];
    for (int i = 0; i < _levels; i++) {
      final double cy = levelH * i + levelH / 2;
      final tp = TextPainter(
        text: TextSpan(text: stageNames[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftMargin - 6);
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, cy - tp.height / 2));
    }

    // Draw each segment as a rounded rect
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i];
      final double xStart =
          leftMargin + s.from.difference(start).inMinutes / totalMins * chartW;
      final double xEnd =
          leftMargin + s.to.difference(start).inMinutes / totalMins * chartW;
      final double segW = (xEnd - xStart).clamp(2.0, chartW);

      final int level = _SleepTimeline._stageLevel(s.stage);
      // level 5=deep → row 0 (top), level 0=inBed → row 5 (bottom)
      final double cy = levelH * ((_levels - 1) - level) + levelH / 2;

      final rrect = RRect.fromLTRBR(
        xStart,
        cy - _barH / 2,
        xStart + segW,
        cy + _barH / 2,
        const Radius.circular(_barR),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = _SleepTimeline._stageColor(s.stage),
      );

      // Connecting line to next segment
      if (i < segments.length - 1) {
        final next = segments[i + 1];
        final int nextLevel = _SleepTimeline._stageLevel(next.stage);
        final double nextCy = levelH * (3 - nextLevel) + levelH / 2;
        final double gapX = xStart + segW;
        final double nextX =
            leftMargin +
            next.from.difference(start).inMinutes / totalMins * chartW;

        if (nextX > gapX + 1) {
          canvas.drawLine(
            Offset(gapX, cy),
            Offset(nextX, nextCy),
            Paint()
              ..color = _SleepTimeline._stageColor(
                next.stage,
              ).withValues(alpha: 0.35)
              ..strokeWidth = 1.2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SleepGanttPainter old) =>
      old.segments.length != segments.length;
}

// ─────────────────────────────────────────────
// Sleep Heatmap — monthly, goal = 8h (480 min)
// ─────────────────────────────────────────────

class _SleepHeatmap extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final bool isDark;
  final int todaySleepMinutes;
  final int goalMinutes;

  const _SleepHeatmap({
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.todaySleepMinutes,
    required this.goalMinutes,
  });

  @override
  State<_SleepHeatmap> createState() => _SleepHeatmapState();
}

class _SleepHeatmapState extends State<_SleepHeatmap> {
  Map<int, int> _monthlyMinutes = {};
  bool _loading = true;

  int get _goalMinutes => widget.goalMinutes;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _fetchData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final Map<int, int> result = {};

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
                final data = doc.data();
                // Primary: explicit manualSleepTotal
                final explicit = (data?['manualSleepTotal'] as num?)?.toInt();
                if (explicit != null && explicit > 0) {
                  result[day] = explicit.clamp(0, 1440).toInt();
                  return;
                }
                // Fallback: sum manualSleepPhases
                final phases =
                    data?['manualSleepPhases'] as Map<String, dynamic>?;
                if (phases != null) {
                  final total =
                      ((phases['rem'] as num?)?.toInt() ?? 0) +
                      ((phases['light'] as num?)?.toInt() ?? 0) +
                      ((phases['deep'] as num?)?.toInt() ?? 0) +
                      ((phases['awake'] as num?)?.toInt() ?? 0) +
                      ((phases['asleep'] as num?)?.toInt() ?? 0);
                  if (total > 0) result[day] = total.clamp(0, 1440).toInt();
                }
              }),
        );
      }
      await Future.wait(futures);
      if (mounted) setState(() => _monthlyMinutes = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _cellOpacity(int? mins) {
    if (mins == null || mins <= 0) return 0.08;
    final ratio = (mins / _goalMinutes).clamp(0.0, 1.0);
    return 0.12 + ratio * 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.plusJakartaSans;
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = '${monthNames[month]} $year';
    final int firstWeekday = (DateTime(year, month, 1).weekday - 1).clamp(0, 6);
    final int rows = ((firstWeekday + daysInMonth) / 7).ceil();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final labelColor = widget.textColor.withValues(alpha: 0.4);
    final emptyColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
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
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    '8h',
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

          LayoutBuilder(
            builder: (context, constraints) {
              const int cols = 7;
              const double gap = 4.0;
              final double cellSize =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _loading
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

                                  final mins = day == now.day
                                      ? math.max(
                                          _monthlyMinutes[day] ?? 0,
                                          widget.todaySleepMinutes,
                                        )
                                      : _monthlyMinutes[day];
                                  final Color cellColor = isFuture
                                      ? emptyColor
                                      : widget.accentColor.withValues(
                                          alpha: _cellOpacity(mins),
                                        );
                                  final bool isToday = day == now.day;

                                  return Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: cellColor,
                                      borderRadius: BorderRadius.circular(5),
                                      border: isToday
                                          ? Border.all(
                                              color: widget.accentColor,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
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

// ── Picker theme helper ───────────────────────────────────────────────────────
// Wraps date/time pickers with the correct dark-mode dialog background.
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

// ── Sleep sheet helpers ───────────────────────────────────────────────────────

class _SleepSheetTopButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _SleepSheetTopButton({
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SleepSheetRow extends StatelessWidget {
  final String label;
  final Color subColor;
  final Color textColor;
  final TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  })
  font;
  final Widget trailing;

  const _SleepSheetRow({
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
          Text(label, style: font(fontSize: 16, color: subColor)),
          trailing,
        ],
      ),
    );
  }
}
