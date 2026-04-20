import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:intl/intl.dart';
import 'package:synthese/ui/components/mood_tracker_modal.dart';
import 'package:synthese/ui/components/breathing_exercise_modal.dart';
import 'package:synthese/ui/components/questionnaire_disclaimer_modal.dart';
import '../ui/components/morning_readiness_modal.dart';
import 'package:synthese/mindfulness/questionnaire_screen.dart';
import 'package:synthese/mindfulness/questionnaire_results_screen.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalsegmentedcontrol.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/services/notification_rules_engine.dart';

class MindfulnessPage extends StatefulWidget {
  final Function(bool)? onModalStateChanged;
  const MindfulnessPage({super.key, this.onModalStateChanged});

  @override
  State<MindfulnessPage> createState() => _MindfulnessPageState();
}

class _MindfulnessPageState extends State<MindfulnessPage> {
  double? _moodValue;
  String? _moodLabel;
  Color? _cachedMoodColor;
  bool _isModalOpen = false;
  bool _hasReadinessLogged = false;
  int? _cachedSleepQuality;
  int? _cachedEnergyLevel;
  int? _cachedAcademicStress;

  String get _todayDateKey {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  Color _getMoodColor(double moodValue) {
    // Match the 7 mood colors from the modal
    if (moodValue <= 1 / 7)
      return const Color.fromRGBO(
        211,
        80,
        42,
        1,
      ); // Very Unpleasant - Burnt Orange
    if (moodValue <= 2 / 7)
      return const Color.fromRGBO(177, 106, 23, 1); // Unpleasant - Ochre
    if (moodValue <= 3 / 7)
      return const Color.fromRGBO(
        194,
        150,
        40,
        1,
      ); // Slightly Unpleasant - Golden Yellow
    if (moodValue <= 4 / 7)
      return const Color.fromRGBO(48, 127, 216, 1); // Neutral - Sky Blue
    if (moodValue <= 5 / 7)
      return const Color.fromRGBO(
        82,
        145,
        50,
        1,
      ); // Slightly Pleasant - Leaf Green
    if (moodValue <= 6 / 7)
      return const Color.fromRGBO(52, 98, 18, 1); // Pleasant - Forest Green
    return const Color.fromRGBO(17, 99, 76, 1); // Very Pleasant - Deep Teal
  }

  @override
  void initState() {
    super.initState();
    _checkTodaysReadiness();
    unawaited(NotificationRulesEngine.evaluateGlobal());
  }

  Future<void> _checkTodaysReadiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('morning_readiness')
        .doc(dateKey)
        .get();

    if (mounted && doc.exists) {
      setState(() {
        _hasReadinessLogged = true;
        _cachedSleepQuality = doc.data()?['sleepQuality'];
        _cachedEnergyLevel = doc.data()?['energyLevel'];
        _cachedAcademicStress = doc.data()?['academicStress'];
      });
    }
  }

  void _showReadinessModal(BuildContext context) async {
    HapticFeedback.lightImpact();
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    final result = await showMorningReadinessModal(context);

    if (result == true) {
      _checkTodaysReadiness();
      unawaited(NotificationRulesEngine.evaluateGlobal());
    }

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
    unawaited(NotificationRulesEngine.evaluateGlobal());
  }

  void _showMoodModal(BuildContext context) async {
    HapticFeedback.lightImpact();
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MoodTrackerModal(),
    );

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  void _showBreathingModal(BuildContext context) async {
    HapticFeedback.lightImpact();
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BreathingExerciseModal(),
    );

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  void _showDisclaimerModal(BuildContext context) async {
    HapticFeedback.lightImpact();
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuestionnaireDisclaimerModal(),
    );

    if (result == true && context.mounted) {
      // Show questionnaire and get answers
      final answers = await QuestionnaireScreen.show(context);

      // If completed (not cancelled), show results
      if (answers != null && context.mounted) {
        await QuestionnaireResultsScreen.show(context, answers);
      }
    }

    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false);
    }
  }

  Future<void> _handleResetMentalHealthData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final dialogBg = isLightMode ? Colors.white : const Color(0xFF252528);
    final textColor = isLightMode ? Colors.black : Colors.white;
    final mutedText = isLightMode ? Colors.black54 : Colors.white70;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          "Reset Mental Health Data?",
          style: TextStyle(color: textColor),
        ),
        content: Text(
          "This will delete all your mood check-ins and mental health history. This cannot be undone.",
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete All",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: BouncingDotsLoader(color: Color(0xFF33BEBE)),
        ),
      );

      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final logsSnap = await userRef.collection('mood_logs').get();

        // Delete in batches of 400
        const int chunkSize = 400;
        for (int i = 0; i < logsSnap.docs.length; i += chunkSize) {
          final batch = FirebaseFirestore.instance.batch();
          final chunk = logsSnap.docs.sublist(
            i,
            (i + chunkSize < logsSnap.docs.length)
                ? i + chunkSize
                : logsSnap.docs.length,
          );
          for (var doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Error deleting mental health data: $e');
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All mental health data has been deleted'),
            duration: Duration(seconds: 2),
          ),
        );

        setState(() {
          _moodValue = null;
          _moodLabel = null;
          _cachedMoodColor = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final safePadding = MediaQuery.of(context).padding;
    final isNarrow = MediaQuery.of(context).size.width < 380;

    return Container(
      color: bgColor,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(clampedTextScale.toDouble()),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: safePadding.top + 24.0,
            bottom: safePadding.bottom + 120,
            left: 28.0,
            right: 28.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and reset button
              Builder(
                builder: (context) {
                  final isLightMode =
                      Theme.of(context).brightness == Brightness.light;
                  final textColor = isLightMode ? Colors.black : Colors.white;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Mental Health',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: isNarrow ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CNButton.icon(
                        icon: const CNSymbol('arrow.clockwise', size: 22),
                        style: CNButtonStyle.glass,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _handleResetMentalHealthData();
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Mood Calendar (shows logged days)
              _buildMoodCalendar(context, uid),

              const SizedBox(height: 20),

              // Daily Check-In Card (simple tap to log)
              StreamBuilder<DocumentSnapshot>(
                stream: uid != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('mood_logs')
                          .doc(_todayDateKey)
                          .snapshots()
                    : null,
                builder: (context, snapshot) {
                  final hasMoodLogged =
                      snapshot.hasData && snapshot.data!.exists;
                  if (hasMoodLogged) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    _moodValue = (data?['mood_value'] as num?)?.toDouble();
                    _moodLabel = data?['mood_label'];
                  } else {
                    _moodValue = null;
                    _moodLabel = null;
                  }
                  return _buildMoodCard(context, hasMoodLogged);
                },
              ),

              const SizedBox(height: 16),

              // Morning Readiness Pill
              _buildReadinessCard(context),

              const SizedBox(height: 16),

              // Breathing exercises card
              _buildBreathingCard(context),

              const SizedBox(height: 16),

              // Mental Health Assessment card
              _buildAssessmentCard(context),

              const SizedBox(height: 24),

              // Mood Insights Graph
              _buildMoodInsightsGraph(context, uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCalendar(BuildContext context, String? uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final textColor = isDark ? Colors.white : Colors.black;
    final now = DateTime.now();
    final isNarrow = MediaQuery.of(context).size.width < 380;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isNarrow ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mood History',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Last 14 days - oldest on left, today on right
          SizedBox(
            height: isNarrow ? 56 : 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate scroll offset to show today (rightmost)
                const itemWidth = 48.0; // 40 width + 8 margin
                final totalWidth = 14 * itemWidth;
                final scrollOffset = (totalWidth - constraints.maxWidth).clamp(
                  0.0,
                  double.infinity,
                );

                final controller = ScrollController(
                  initialScrollOffset: scrollOffset,
                );

                return ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  itemBuilder: (context, index) {
                    // index 0 = 13 days ago (oldest, leftmost)
                    // index 13 = today (newest, rightmost)
                    final daysAgo = 13 - index;
                    final date = now.subtract(Duration(days: daysAgo));
                    final dateKey =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final isToday = daysAgo == 0;

                    if (uid == null) {
                      return _buildCalendarDay(
                        context,
                        date,
                        isToday,
                        false,
                        null,
                      );
                    }

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('mood_logs')
                          .doc(dateKey)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final hasLogged =
                            snapshot.hasData && snapshot.data!.exists;
                        Color? moodColor;
                        if (hasLogged) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final moodValue = (data?['mood_value'] as num?)
                              ?.toDouble();
                          if (moodValue != null) {
                            moodColor = _getMoodColor(moodValue);
                          }
                        }
                        return _buildCalendarDay(
                          context,
                          date,
                          isToday,
                          hasLogged,
                          moodColor,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    BuildContext context,
    DateTime date,
    bool isToday,
    bool hasLogged,
    Color? moodColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    const tealColor = Color(0xFF33BEBE);

    return Container(
      width: 40,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('E').format(date).substring(0, 1),
            style: TextStyle(
              color: textColor.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hasLogged && moodColor != null
                  ? moodColor.withOpacity(0.2)
                  : (isToday ? tealColor.withOpacity(0.1) : Colors.transparent),
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: tealColor, width: 2) : null,
            ),
            child: Center(
              child: hasLogged
                  ? Icon(
                      CupertinoIcons.checkmark,
                      color: moodColor ?? tealColor,
                      size: 16,
                    )
                  : Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isToday ? tealColor : textColor.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);

    return GestureDetector(
      onTap: () => _showReadinessModal(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Morning Readiness',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _hasReadinessLogged
                          ? 'Sleep ${_cachedSleepQuality ?? "-"} · Energy ${_cachedEnergyLevel ?? "-"} · Stress ${_cachedAcademicStress ?? "-"}'
                          : 'How ready are you today?',
                      key: ValueKey(_hasReadinessLogged ? 'logged' : 'prompt'),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: _hasReadinessLogged ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _hasReadinessLogged
                  ? Container(
                      key: const ValueKey('edit'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.8)
                              : Colors.black.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('button'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF33BEBE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.sun_max_fill,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, bool hasMoodLogged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCardBg = isDark
        ? const Color(0xFF252528)
        : const Color(0xFFE5E5E7);

    Color cardBg = baseCardBg;
    if (hasMoodLogged && _moodValue != null) {
      _cachedMoodColor = _getMoodColor(_moodValue!);
      cardBg = Color.lerp(baseCardBg, _cachedMoodColor!, 0.12)!;
    } else {
      _cachedMoodColor = null;
    }

    return GestureDetector(
      onTap: () => _showMoodModal(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: hasMoodLogged && _cachedMoodColor != null
                  ? _cachedMoodColor!.withOpacity(isDark ? 0.25 : 0.15)
                  : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      hasMoodLogged ? "Today's Check-in" : 'Daily Check-in',
                      key: ValueKey(hasMoodLogged ? 'logged' : 'not-logged'),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      hasMoodLogged
                          ? 'Feeling $_moodLabel'
                          : 'How are you feeling?',
                      key: ValueKey(hasMoodLogged ? _moodLabel : 'prompt'),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: hasMoodLogged
                  ? Container(
                      key: const ValueKey('edit'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.8)
                              : Colors.black.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _showMoodModal(context),
                      child: Container(
                        key: const ValueKey('button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF33BEBE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);

    return GestureDetector(
      onTap: () => _showBreathingModal(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Breathing',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take a moment to breathe',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF33BEBE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.wind,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mental Health Assessment',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '15 questions inspired by PHQ-9, GAD-7, and Maslach Burnout Inventory',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isModalOpen) ...[
            UniversalButton(
              text: 'Start Assessment',
              onPressed: () => _showDisclaimerModal(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodInsightsGraph(BuildContext context, String? uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
    final textColor = isDark ? Colors.white : Colors.black;
    final now = DateTime.now();
    const tealColor = Color(0xFF33BEBE);

    if (uid == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Insights',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Last 30 days',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Graph
          SizedBox(
            height: 150,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('mood_logs')
                  .orderBy('date', descending: false)
                  .limitToLast(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar,
                          color: textColor.withOpacity(0.2),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Log your mood to see insights',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final moodData = <DateTime, double>{};

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateStr = data['date'] as String?;
                  final moodValue = (data['mood_value'] as num?)?.toDouble();

                  if (dateStr != null && moodValue != null) {
                    final parts = dateStr.split('-');
                    if (parts.length == 3) {
                      final date = DateTime(
                        int.parse(parts[0]),
                        int.parse(parts[1]),
                        int.parse(parts[2]),
                      );
                      moodData[date] = moodValue;
                    }
                  }
                }

                if (moodData.isEmpty) {
                  return Center(
                    child: Text(
                      'No mood data yet',
                      style: TextStyle(color: textColor.withOpacity(0.5)),
                    ),
                  );
                }

                return CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _MoodGraphPainter(
                    moodData: moodData,
                    lineColor: tealColor,
                    gridColor: textColor.withOpacity(0.1),
                    textColor: textColor.withOpacity(0.5),
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Very Happy', const Color(0xFF30D158)),
              _buildLegendItem('Neutral', const Color(0xFF60A5FA)),
              _buildLegendItem('Unpleasant', const Color(0xFFFF3B30)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MoodGraphPainter extends CustomPainter {
  final Map<DateTime, double> moodData;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final bool isDark;

  _MoodGraphPainter({
    required this.moodData,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moodData.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Sort dates
    final sortedDates = moodData.keys.toList()..sort();
    if (sortedDates.isEmpty) return;

    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;
    final dateRange = lastDate.difference(firstDate).inDays;

    if (dateRange == 0 && sortedDates.length == 1) {
      // Single point - draw a dot
      final x = size.width / 2;
      final y = size.height * (1 - moodData[sortedDates.first]!);

      final dotPaint = Paint()
        ..color = _getMoodColor(moodData[sortedDates.first]!)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 6, dotPaint);
      return;
    }

    final path = Path();
    final fillPath = Path();
    bool isFirst = true;

    for (final date in sortedDates) {
      final daysFromStart = date.difference(firstDate).inDays;
      final x = dateRange > 0
          ? (daysFromStart / dateRange) * size.width
          : size.width / 2;
      final y = size.height * (1 - moodData[date]!);

      if (isFirst) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    final lastX = dateRange > 0 ? size.width : size.width / 2;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots at data points with mood colors
    for (final date in sortedDates) {
      final daysFromStart = date.difference(firstDate).inDays;
      final x = dateRange > 0
          ? (daysFromStart / dateRange) * size.width
          : size.width / 2;
      final y = size.height * (1 - moodData[date]!);

      final dotPaint = Paint()
        ..color = _getMoodColor(moodData[date]!)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      // White/dark border
      final borderPaint = Paint()
        ..color = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 5, borderPaint);
    }
  }

  Color _getMoodColor(double moodValue) {
    if (moodValue <= 0.2) return const Color(0xFFFF3B30);
    if (moodValue <= 0.4) return const Color(0xFF1E3A8A);
    if (moodValue <= 0.6) return const Color(0xFF60A5FA);
    if (moodValue <= 0.8) return const Color(0xFF34C759);
    return const Color(0xFF30D158);
  }

  @override
  bool shouldRepaint(covariant _MoodGraphPainter oldDelegate) {
    return moodData != oldDelegate.moodData;
  }
}
