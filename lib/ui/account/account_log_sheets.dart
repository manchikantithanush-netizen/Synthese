import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

/// Slide-up sheet for logging height, weight, average sleep duration and
/// daily water intake. These are *current values*, not goals — the goals
/// are collected during onboarding.
class HealthLogSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const HealthLogSheet({super.key, this.initial});

  @override
  State<HealthLogSheet> createState() => _HealthLogSheetState();
}

class _HealthLogSheetState extends State<HealthLogSheet> {
  late int _height;
  late int _weight;
  late double _sleepHours;
  late double _waterLitres;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _height = int.tryParse(widget.initial?['height']?.toString() ?? '') ?? 170;
    _weight = int.tryParse(widget.initial?['weight']?.toString() ?? '') ?? 70;
    final s = widget.initial?['sleepDuration'];
    _sleepHours = s is num ? s.toDouble() : 7.0;
    final w = widget.initial?['waterIntake'];
    _waterLitres = w is num ? w.toDouble() : 2.0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'height': _height.toString(),
          'weight': _weight.toString(),
          'sleepDuration': _sleepHours,
          'waterIntake': _waterLitres,
        }, SetOptions(merge: true));
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DefaultTextStyle(
          style: GoogleFonts.plusJakartaSans(),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.acctLogTitle,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    UniversalCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  t.acctLogSubtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.55),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _IntWheelCard(
                      label: t.acctLogHeight,
                      icon: Icons.straighten_rounded,
                      accent: const Color(0xFF5E5CE6),
                      min: 100,
                      max: 230,
                      step: 1,
                      unit: "cm",
                      value: _height,
                      onChanged: (v) => _height = v,
                    ),
                    const SizedBox(height: 14),
                    _IntWheelCard(
                      label: t.acctLogWeight,
                      icon: Icons.monitor_weight_rounded,
                      accent: const Color(0xFF34C759),
                      min: 30,
                      max: 200,
                      step: 1,
                      unit: "kg",
                      value: _weight,
                      onChanged: (v) => _weight = v,
                    ),
                    const SizedBox(height: 14),
                    _DoubleWheelCard(
                      label: t.acctLogSleep,
                      icon: Icons.nightlight_round,
                      accent: const Color(0xFF32ADE6),
                      min: 3.0,
                      max: 12.0,
                      step: 0.5,
                      unit: "hrs",
                      value: _sleepHours,
                      formatter: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => _sleepHours = v,
                    ),
                    const SizedBox(height: 14),
                    _DoubleWheelCard(
                      label: t.acctLogWater,
                      icon: Icons.water_drop_rounded,
                      accent: const Color(0xFF4FC3F7),
                      min: 0.5,
                      max: 6.0,
                      step: 0.25,
                      unit: "L",
                      value: _waterLitres,
                      formatter: (v) => v.toStringAsFixed(2),
                      onChanged: (v) => _waterLitres = v,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: PremiumButton(
                    text: t.commonSave,
                    isLoading: _saving,
                    onPressed: _saving ? () {} : _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide-up sheet for logging athlete profile info: type, experience and
/// sports. Mirrors the questions that used to live in the old onboarding
/// flow (now deferred until the user opts in).
class AthleteLogSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const AthleteLogSheet({super.key, this.initial});

  @override
  State<AthleteLogSheet> createState() => _AthleteLogSheetState();
}

class _AthleteLogSheetState extends State<AthleteLogSheet> {
  static const List<String> _athleteTypes = [
    'Student',
    'Club',
    'Casual',
    'Competitive',
  ];

  static const List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> _sportsCatalogue = [
    'Football',
    'Track',
    'Cricket',
    'Basketball',
    'Motor sport',
    'Golf',
    'Badminton',
    'Tennis',
    'Gymnastics',
    'Volleyball',
    'Martial arts',
    'Swimming',
    'Cycling',
    'Running',
    'Rugby',
    'Hockey',
  ];

  String? _athleteType;
  String? _experienceLevel;
  final List<String> _selectedSports = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.initial?['athleteType']?.toString();
    if (raw != null && raw.isNotEmpty) {
      // Tolerate legacy values that included "Athlete" suffix.
      final cleaned = raw.replaceAll('Athlete', '').trim();
      _athleteType = _athleteTypes.firstWhere(
        (t) => t.toLowerCase() == cleaned.toLowerCase(),
        orElse: () => '',
      );
      if (_athleteType!.isEmpty) _athleteType = null;
    }
    final exp = widget.initial?['experienceLevel']?.toString();
    if (exp != null && _experienceLevels.contains(exp)) {
      _experienceLevel = exp;
    }
    final sports = widget.initial?['selectedSports'];
    if (sports is List) {
      _selectedSports.addAll(sports.whereType<String>());
    }
  }

  String _typeLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'Student':
        return t.acctLogTypeStudent;
      case 'Club':
        return t.acctLogTypeClub;
      case 'Casual':
        return t.acctLogTypeCasual;
      case 'Competitive':
        return t.acctLogTypeCompetitive;
      default:
        return v;
    }
  }

  String _levelLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'Beginner':
        return t.acctLogExpBeginner;
      case 'Intermediate':
        return t.acctLogExpIntermediate;
      case 'Advanced':
        return t.acctLogExpAdvanced;
      default:
        return v;
    }
  }

  String _sportLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'Football':
        return t.acctLogSportFootball;
      case 'Track':
        return t.acctLogSportTrack;
      case 'Cricket':
        return t.acctLogSportCricket;
      case 'Basketball':
        return t.acctLogSportBasketball;
      case 'Motor sport':
        return t.acctLogSportMotorSport;
      case 'Golf':
        return t.acctLogSportGolf;
      case 'Badminton':
        return t.acctLogSportBadminton;
      case 'Tennis':
        return t.acctLogSportTennis;
      case 'Gymnastics':
        return t.acctLogSportGymnastics;
      case 'Volleyball':
        return t.acctLogSportVolleyball;
      case 'Martial arts':
        return t.acctLogSportMartialArts;
      case 'Swimming':
        return t.acctLogSportSwimming;
      case 'Cycling':
        return t.acctLogSportCycling;
      case 'Running':
        return t.acctLogSportRunning;
      case 'Rugby':
        return t.acctLogSportRugby;
      case 'Hockey':
        return t.acctLogSportHockey;
      default:
        return v;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'athleteType': _athleteType,
          'experienceLevel': _experienceLevel,
          'selectedSports': _selectedSports,
        }, SetOptions(merge: true));
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DefaultTextStyle(
          style: GoogleFonts.plusJakartaSans(),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.acctLogAthleteProfile,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    UniversalCloseButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  t.acctLogAthleteSubtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.55),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _SectionLabel(t.acctLogTypeOfAthlete, textColor: textColor),
                    const SizedBox(height: 10),
                    _PillGrid(
                      options: _athleteTypes,
                      selected: _athleteType == null
                          ? const <String>{}
                          : {_athleteType!},
                      onTap: (v) => setState(
                        () => _athleteType = _athleteType == v ? null : v,
                      ),
                      multiSelect: false,
                      isDark: isDark,
                      textColor: textColor,
                      labelOf: (v) => _typeLabel(t, v),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(t.acctLogExperienceLevel, textColor: textColor),
                    const SizedBox(height: 10),
                    _PillGrid(
                      options: _experienceLevels,
                      selected: _experienceLevel == null
                          ? const <String>{}
                          : {_experienceLevel!},
                      onTap: (v) => setState(
                        () =>
                            _experienceLevel = _experienceLevel == v ? null : v,
                      ),
                      multiSelect: false,
                      isDark: isDark,
                      textColor: textColor,
                      labelOf: (v) => _levelLabel(t, v),
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(
                      t.acctLogSportsProfile,
                      textColor: textColor,
                      hint: t.acctLogSelectAll,
                    ),
                    const SizedBox(height: 10),
                    _PillGrid(
                      options: _sportsCatalogue,
                      selected: _selectedSports.toSet(),
                      onTap: (v) => setState(() {
                        if (_selectedSports.contains(v)) {
                          _selectedSports.remove(v);
                        } else {
                          _selectedSports.add(v);
                        }
                      }),
                      multiSelect: true,
                      isDark: isDark,
                      textColor: textColor,
                      labelOf: (v) => _sportLabel(t, v),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: PremiumButton(
                    text: t.commonSave,
                    isLoading: _saving,
                    onPressed: _saving ? () {} : _save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  final String? hint;
  const _SectionLabel(this.label, {required this.textColor, this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: TextStyle(
              color: textColor.withOpacity(0.32),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _PillGrid extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final void Function(String) onTap;
  final bool multiSelect;
  final bool isDark;
  final Color textColor;

  /// Maps a stable option value (stored in Firestore) to its localized label.
  final String Function(String)? labelOf;

  const _PillGrid({
    required this.options,
    required this.selected,
    required this.onTap,
    required this.multiSelect,
    required this.isDark,
    required this.textColor,
    this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(opt);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF4CD964) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded,
                      color: Color(0xFF4CD964), size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  labelOf?.call(opt) ?? opt,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _IntWheelCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final int min;
  final int max;
  final int step;
  final String unit;
  final int value;
  final void Function(int) onChanged;

  const _IntWheelCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final count = ((max - min) ~/ step) + 1;
    final initialIndex = ((value - min) ~/ step).clamp(0, count - 1);
    final controller = FixedExtentScrollController(initialItem: initialIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 110,
            child: CupertinoPicker(
              itemExtent: 38,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: controller,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: accent.withOpacity(0.12),
              ),
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                onChanged(min + (i * step));
              },
              children: List.generate(count, (i) {
                final v = min + (i * step);
                return Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "$v",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: " $unit",
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

class _DoubleWheelCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final double min;
  final double max;
  final double step;
  final String unit;
  final double value;
  final String Function(double) formatter;
  final void Function(double) onChanged;

  const _DoubleWheelCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.value,
    required this.formatter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final count = ((max - min) / step).round() + 1;
    final initialIndex = ((value - min) / step).round().clamp(0, count - 1);
    final controller = FixedExtentScrollController(initialItem: initialIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 110,
            child: CupertinoPicker(
              itemExtent: 38,
              diameterRatio: 1.5,
              squeeze: 1.2,
              scrollController: controller,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: accent.withOpacity(0.12),
              ),
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                onChanged(min + (i * step));
              },
              children: List.generate(count, (i) {
                final v = min + (i * step);
                return Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: formatter(v),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: " $unit",
                          style: TextStyle(
                            color: textColor.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
