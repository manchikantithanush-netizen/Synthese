import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/services/data_aggregation_service.dart';
import 'package:synthese/services/notification_rules_engine.dart';
import 'package:synthese/ui/components/app_toast.dart';
import 'package:intl/intl.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

class MoodOption {
  final double value;
  final String label;
  final Color color;
  final String description;
  final List<String> subFeelings;

  const MoodOption({
    required this.value,
    required this.label,
    required this.color,
    required this.description,
    required this.subFeelings,
  });
}

class MoodTrackerModal extends StatefulWidget {
  const MoodTrackerModal({super.key});

  @override
  State<MoodTrackerModal> createState() => _MoodTrackerModalState();
}

class _MoodTrackerModalState extends State<MoodTrackerModal>
    with SingleTickerProviderStateMixin {
  double _moodValue = 0.5;
  bool _isSaving = false;
  bool _isOnSecondPage = false;
  Set<String> _selectedSubFeelings = {};
  bool _showLoggedOverlay = false;

  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;

  static const List<MoodOption> _moodOptions = [
    MoodOption(
      value: 0.0,
      label: 'Very Unpleasant',
      color: Color.fromRGBO(211, 80, 42, 1),
      description:
          "It's rough right now. Give yourself grace — you're doing what you can.",
      subFeelings: [
        'Angry',
        'Anxious',
        'Scared',
        'Overwhelmed',
        'Ashamed',
        'Devastated',
        'Panicked',
        'Hopeless',
        'Furious',
        'Terrified',
        'Disgusted',
        'Resentful',
        'Miserable',
      ],
    ),
    MoodOption(
      value: 1 / 6,
      label: 'Unpleasant',
      color: Color.fromRGBO(177, 106, 23, 1),
      description: "Things feel heavy. Take it one step at a time.",
      subFeelings: [
        'Frustrated',
        'Worried',
        'Sad',
        'Stressed',
        'Lonely',
        'Disappointed',
        'Insecure',
        'Irritated',
        'Guilty',
        'Hurt',
        'Nervous',
        'Jealous',
        'Embarrassed',
      ],
    ),
    MoodOption(
      value: 2 / 6,
      label: 'Slightly Unpleasant',
      color: Color.fromRGBO(194, 150, 40, 1),
      description:
          "A little off-track. Not great, but you're hanging in there.",
      subFeelings: [
        'Tired',
        'Bored',
        'Uneasy',
        'Distracted',
        'Restless',
        'Apathetic',
        'Drained',
        'Impatient',
        'Disconnected',
        'Sluggish',
        'Uncertain',
        'Unfocused',
        'Melancholic',
      ],
    ),
    MoodOption(
      value: 3 / 6,
      label: 'Neutral',
      color: Color.fromRGBO(48, 127, 216, 1),
      description: "Balanced and centered. Ready for what's next.",
      subFeelings: [
        'Content',
        'Calm',
        'Peaceful',
        'Indifferent',
        'Steady',
        'Balanced',
        'Accepting',
        'Present',
        'Mellow',
        'Composed',
        'Grounded',
        'Reserved',
        'Thoughtful',
      ],
    ),
    MoodOption(
      value: 4 / 6,
      label: 'Slightly Pleasant',
      color: Color.fromRGBO(82, 145, 50, 1),
      description: "Doing alright! A steady, positive energy is building.",
      subFeelings: [
        'Hopeful',
        'Relaxed',
        'Focused',
        'Grateful',
        'Optimistic',
        'Curious',
        'Refreshed',
        'Relieved',
        'Comfortable',
        'Open',
        'Encouraged',
        'Interested',
        'Serene',
      ],
    ),
    MoodOption(
      value: 5 / 6,
      label: 'Pleasant',
      color: Color.fromRGBO(52, 98, 18, 1),
      description: "Feeling solid and on track. You've got a good flow going.",
      subFeelings: [
        'Happy',
        'Confident',
        'Energized',
        'Motivated',
        'Joyful',
        'Proud',
        'Fulfilled',
        'Cheerful',
        'Playful',
        'Empowered',
        'Creative',
        'Appreciated',
        'Loving',
      ],
    ),
    MoodOption(
      value: 1.0,
      label: 'Very Pleasant',
      color: Color.fromRGBO(17, 99, 76, 1),
      description:
          "Absolutely great! You're in peak form and feeling energized.",
      subFeelings: [
        'Amazed',
        'Excited',
        'Surprised',
        'Passionate',
        'Inspired',
        'Euphoric',
        'Thrilled',
        'Elated',
        'Ecstatic',
        'Blissful',
        'Radiant',
        'Alive',
        'Grateful',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    super.dispose();
  }

  int get _selectedIndex {
    if (_moodValue <= 1 / 7) return 0;
    if (_moodValue <= 2 / 7) return 1;
    if (_moodValue <= 3 / 7) return 2;
    if (_moodValue <= 4 / 7) return 3;
    if (_moodValue <= 5 / 7) return 4;
    if (_moodValue <= 6 / 7) return 5;
    return 6;
  }

  MoodOption get _selectedMood => _moodOptions[_selectedIndex];

  Color _getInterpolatedColor() {
    if (_moodValue <= 0.0) return _moodOptions[0].color;
    if (_moodValue >= 1.0) return _moodOptions[6].color;

    final segment = _moodValue * 6;
    final lowerIndex = segment.floor().clamp(0, 5);
    final upperIndex = (lowerIndex + 1).clamp(0, 6);
    final t = segment - lowerIndex;

    return Color.lerp(
      _moodOptions[lowerIndex].color,
      _moodOptions[upperIndex].color,
      t,
    )!;
  }

  Color _getModalBackground(bool isDark) {
    final baseColor = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFF2F2F7);
    final tint = _getInterpolatedColor();
    return Color.lerp(baseColor, tint, 0.08) ?? baseColor;
  }

  void _goToSecondPage() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOnSecondPage = true;
      _selectedSubFeelings = {};
    });
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOnSecondPage = false;
      _selectedSubFeelings = {};
    });
  }

  Future<void> _saveMood() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('mood_logs')
          .doc(dateKey)
          .set({
            'mood_value': _moodValue,
            'mood_label': _selectedMood.label,
            'sub_feelings': _selectedSubFeelings.toList(),
            'timestamp': FieldValue.serverTimestamp(),
          });
      await DataAggregationService.markMoodLogged(uid: uid, when: today);
      await NotificationRulesEngine.evaluateGlobal();

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _showLoggedOverlay = true;
          _isSaving = false;
        });
        _checkmarkController.forward();
        AppToast.success(context, AppLocalizations.of(context).moodLogged, icon: Icons.mood_rounded);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving mood: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final currentColor = _getInterpolatedColor();
    final trackColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);

    final localeName = Localizations.localeOf(context).toString();
    final timeString = DateFormat.jm(localeName).format(DateTime.now());

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: _getModalBackground(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(38),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isOnSecondPage
                  ? _buildSecondPage(
                      isDark,
                      textColor,
                      subTextColor,
                      currentColor,
                    )
                  : _buildFirstPage(
                      isDark,
                      textColor,
                      subTextColor,
                      currentColor,
                      trackColor,
                      timeString,
                    ),
            ),
          ),

          // Logged overlay with checkmark animation
          if (_showLoggedOverlay)
            Container(
              decoration: BoxDecoration(
                color: _getModalBackground(isDark),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(38),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _checkmarkAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: currentColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: currentColor,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _checkmarkAnimation,
                      child: Text(
                        AppLocalizations.of(context).moodLoggedOverlay,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFirstPage(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color currentColor,
    Color trackColor,
    String timeString,
  ) {
    final t = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('first'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 24, start: 20, end: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                t.moodHowFeeling,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: UniversalCloseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Time pill badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: currentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: currentColor.withOpacity(0.3), width: 1),
          ),
          child: Text(
            t.moodLogFor(timeString),
            style: TextStyle(
              color: currentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.moodYoureFeeling,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _moodLabel(t, _selectedMood.label),
                      key: ValueKey(_selectedIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currentColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _moodDesc(t, _selectedMood.label),
                      key: ValueKey(_selectedMood.description),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Mood indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (index) {
                      final isSelected = _selectedIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 12 : 8,
                        height: isSelected ? 12 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _moodOptions[index].color
                              : _moodOptions[index].color.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  _buildPillSlider(trackColor, currentColor),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.moodScaleUnpleasant,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                      Text(
                        t.moodScalePleasant,
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Date info
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _getFormattedDate(),
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        // Next Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: UniversalButton(text: t.moodNext, onPressed: _goToSecondPage),
        ),
      ],
    );
  }

  Widget _buildSecondPage(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color currentColor,
  ) {
    final t = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 760;
    return Column(
      key: const ValueKey('second'),
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 24, start: 20, end: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: UniversalBackButton(onPressed: _goBack),
              ),
              Text(
                t.moodDescribeFeeling,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: UniversalCloseButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isCompact ? 16 : 32),

        // Selected feeling pill at top
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: currentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: currentColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Text(
            _moodLabel(t, _selectedMood.label),
            style: TextStyle(
              color: currentColor,
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Text(
                  t.moodWhatDescribes,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: isCompact ? 15 : 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isCompact ? 18 : 32),
                Wrap(
                  spacing: isCompact ? 8 : 12,
                  runSpacing: isCompact ? 8 : 12,
                  alignment: WrapAlignment.center,
                  children: _selectedMood.subFeelings.map((feeling) {
                    final isSelected = _selectedSubFeelings.contains(feeling);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_selectedSubFeelings.contains(feeling)) {
                            _selectedSubFeelings.remove(feeling);
                          } else {
                            _selectedSubFeelings.add(feeling);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 14 : 20,
                          vertical: isCompact ? 9 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? currentColor
                              : currentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? currentColor
                                : currentColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _feelingLabel(t, feeling),
                          style: TextStyle(
                            color: isSelected ? Colors.white : currentColor,
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Finish Button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: UniversalButton(
            text: _isSaving ? t.commonSaving : t.moodFinish,
            isLoading: _isSaving,
            onPressed: _isSaving ? () {} : _saveMood,
          ),
        ),
      ],
    );
  }

  String _moodLabel(AppLocalizations t, String label) {
    switch (label) {
      case 'Very Unpleasant':
        return t.moodLblVeryUnpleasant;
      case 'Unpleasant':
        return t.moodLblUnpleasant;
      case 'Slightly Unpleasant':
        return t.moodLblSlightlyUnpleasant;
      case 'Neutral':
        return t.moodLblNeutral;
      case 'Slightly Pleasant':
        return t.moodLblSlightlyPleasant;
      case 'Pleasant':
        return t.moodLblPleasant;
      case 'Very Pleasant':
        return t.moodLblVeryPleasant;
      default:
        return label;
    }
  }

  String _moodDesc(AppLocalizations t, String label) {
    switch (label) {
      case 'Very Unpleasant':
        return t.moodDescVeryUnpleasant;
      case 'Unpleasant':
        return t.moodDescUnpleasant;
      case 'Slightly Unpleasant':
        return t.moodDescSlightlyUnpleasant;
      case 'Neutral':
        return t.moodDescNeutral;
      case 'Slightly Pleasant':
        return t.moodDescSlightlyPleasant;
      case 'Pleasant':
        return t.moodDescPleasant;
      case 'Very Pleasant':
        return t.moodDescVeryPleasant;
      default:
        return '';
    }
  }

  String _feelingLabel(AppLocalizations t, String feeling) {
    switch (feeling) {
      case 'Angry':
        return t.moodFeelAngry;
      case 'Anxious':
        return t.moodFeelAnxious;
      case 'Scared':
        return t.moodFeelScared;
      case 'Overwhelmed':
        return t.moodFeelOverwhelmed;
      case 'Ashamed':
        return t.moodFeelAshamed;
      case 'Devastated':
        return t.moodFeelDevastated;
      case 'Panicked':
        return t.moodFeelPanicked;
      case 'Hopeless':
        return t.moodFeelHopeless;
      case 'Furious':
        return t.moodFeelFurious;
      case 'Terrified':
        return t.moodFeelTerrified;
      case 'Disgusted':
        return t.moodFeelDisgusted;
      case 'Resentful':
        return t.moodFeelResentful;
      case 'Miserable':
        return t.moodFeelMiserable;
      case 'Frustrated':
        return t.moodFeelFrustrated;
      case 'Worried':
        return t.moodFeelWorried;
      case 'Sad':
        return t.moodFeelSad;
      case 'Stressed':
        return t.moodFeelStressed;
      case 'Lonely':
        return t.moodFeelLonely;
      case 'Disappointed':
        return t.moodFeelDisappointed;
      case 'Insecure':
        return t.moodFeelInsecure;
      case 'Irritated':
        return t.moodFeelIrritated;
      case 'Guilty':
        return t.moodFeelGuilty;
      case 'Hurt':
        return t.moodFeelHurt;
      case 'Nervous':
        return t.moodFeelNervous;
      case 'Jealous':
        return t.moodFeelJealous;
      case 'Embarrassed':
        return t.moodFeelEmbarrassed;
      case 'Tired':
        return t.moodFeelTired;
      case 'Bored':
        return t.moodFeelBored;
      case 'Uneasy':
        return t.moodFeelUneasy;
      case 'Distracted':
        return t.moodFeelDistracted;
      case 'Restless':
        return t.moodFeelRestless;
      case 'Apathetic':
        return t.moodFeelApathetic;
      case 'Drained':
        return t.moodFeelDrained;
      case 'Impatient':
        return t.moodFeelImpatient;
      case 'Disconnected':
        return t.moodFeelDisconnected;
      case 'Sluggish':
        return t.moodFeelSluggish;
      case 'Uncertain':
        return t.moodFeelUncertain;
      case 'Unfocused':
        return t.moodFeelUnfocused;
      case 'Melancholic':
        return t.moodFeelMelancholic;
      case 'Content':
        return t.moodFeelContent;
      case 'Calm':
        return t.moodFeelCalm;
      case 'Peaceful':
        return t.moodFeelPeaceful;
      case 'Indifferent':
        return t.moodFeelIndifferent;
      case 'Steady':
        return t.moodFeelSteady;
      case 'Balanced':
        return t.moodFeelBalanced;
      case 'Accepting':
        return t.moodFeelAccepting;
      case 'Present':
        return t.moodFeelPresent;
      case 'Mellow':
        return t.moodFeelMellow;
      case 'Composed':
        return t.moodFeelComposed;
      case 'Grounded':
        return t.moodFeelGrounded;
      case 'Reserved':
        return t.moodFeelReserved;
      case 'Thoughtful':
        return t.moodFeelThoughtful;
      case 'Hopeful':
        return t.moodFeelHopeful;
      case 'Relaxed':
        return t.moodFeelRelaxed;
      case 'Focused':
        return t.moodFeelFocused;
      case 'Grateful':
        return t.moodFeelGrateful;
      case 'Optimistic':
        return t.moodFeelOptimistic;
      case 'Curious':
        return t.moodFeelCurious;
      case 'Refreshed':
        return t.moodFeelRefreshed;
      case 'Relieved':
        return t.moodFeelRelieved;
      case 'Comfortable':
        return t.moodFeelComfortable;
      case 'Open':
        return t.moodFeelOpen;
      case 'Encouraged':
        return t.moodFeelEncouraged;
      case 'Interested':
        return t.moodFeelInterested;
      case 'Serene':
        return t.moodFeelSerene;
      case 'Happy':
        return t.moodFeelHappy;
      case 'Confident':
        return t.moodFeelConfident;
      case 'Energized':
        return t.moodFeelEnergized;
      case 'Motivated':
        return t.moodFeelMotivated;
      case 'Joyful':
        return t.moodFeelJoyful;
      case 'Proud':
        return t.moodFeelProud;
      case 'Fulfilled':
        return t.moodFeelFulfilled;
      case 'Cheerful':
        return t.moodFeelCheerful;
      case 'Playful':
        return t.moodFeelPlayful;
      case 'Empowered':
        return t.moodFeelEmpowered;
      case 'Creative':
        return t.moodFeelCreative;
      case 'Appreciated':
        return t.moodFeelAppreciated;
      case 'Loving':
        return t.moodFeelLoving;
      case 'Amazed':
        return t.moodFeelAmazed;
      case 'Excited':
        return t.moodFeelExcited;
      case 'Surprised':
        return t.moodFeelSurprised;
      case 'Passionate':
        return t.moodFeelPassionate;
      case 'Inspired':
        return t.moodFeelInspired;
      case 'Euphoric':
        return t.moodFeelEuphoric;
      case 'Thrilled':
        return t.moodFeelThrilled;
      case 'Elated':
        return t.moodFeelElated;
      case 'Ecstatic':
        return t.moodFeelEcstatic;
      case 'Blissful':
        return t.moodFeelBlissful;
      case 'Radiant':
        return t.moodFeelRadiant;
      case 'Alive':
        return t.moodFeelAlive;
      default:
        return feeling;
    }
  }

  String _getFormattedDate() {
    final localeName = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, MMMM d', localeName).format(DateTime.now());
  }

  Widget _buildPillSlider(Color trackColor, Color thumbColor) {
    const double trackHeight = 40.0;
    const double thumbSize = 32.0;
    const double padding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final usableWidth = trackWidth - thumbSize - (padding * 2);
        final thumbX = padding + (_moodValue * usableWidth);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newX = details.localPosition.dx - (thumbSize / 2);
            final newValue = ((newX - padding) / usableWidth).clamp(0.0, 1.0);
            final oldIndex = _selectedIndex;
            setState(() {
              _moodValue = newValue;
              if (_selectedIndex != oldIndex) {
                _selectedSubFeelings = {};
              }
            });
            if (_selectedIndex != oldIndex) HapticFeedback.selectionClick();
          },
          onTapDown: (details) {
            final newX = details.localPosition.dx - (thumbSize / 2);
            final newValue = ((newX - padding) / usableWidth).clamp(0.0, 1.0);
            final oldIndex = _selectedIndex;
            HapticFeedback.selectionClick();
            setState(() {
              _moodValue = newValue;
              if (_selectedIndex != oldIndex) {
                _selectedSubFeelings = {};
              }
            });
          },
          child: Container(
            height: trackHeight,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(trackHeight / 2),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: thumbX,
                  top: padding,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
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
