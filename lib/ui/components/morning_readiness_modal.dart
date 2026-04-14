import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/universalbutton.dart';

class MorningReadinessModal extends StatefulWidget {
  const MorningReadinessModal({super.key});

  @override
  State<MorningReadinessModal> createState() => _MorningReadinessModalState();
}

class _MorningReadinessModalState extends State<MorningReadinessModal>
    with SingleTickerProviderStateMixin {
  double _sleepQuality = 3.0;
  double _energyLevel = 3.0;
  double _academicStress = 3.0;
  bool _isSaving = false;
  bool _showSavedOverlay = false;

  late AnimationController _checkmarkController;
  late Animation<double> _checkmarkAnimation;

  static const Color tealColor = Color(0xFF33BEBE);

  // Sleep Quality labels (1-5)
  static const List<String> _sleepLabels = [
    'Poor',
    'Fair',
    'Okay',
    'Good',
    'Great',
  ];

  // Energy Level labels (1-5)
  static const List<String> _energyLabels = [
    'Exhausted',
    'Low',
    'Moderate',
    'High',
    'Energized',
  ];

  // Academic Stress labels (1-5, where 1=bad, 5=good)
  static const List<String> _stressLabels = [
    'Overwhelming',
    'High',
    'Moderate',
    'Low',
    'Minimal',
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

  String _getSleepLabel() =>
      _sleepLabels[(_sleepQuality.round() - 1).clamp(0, 4)];
  String _getEnergyLabel() =>
      _energyLabels[(_energyLevel.round() - 1).clamp(0, 4)];
  String _getStressLabel() =>
      _stressLabels[(_academicStress.round() - 1).clamp(0, 4)];

  // Sleep Quality: tired orange/red to restful blue/purple
  Color _getSleepColor() {
    final value = (_sleepQuality - 1) / 4; // Normalize to 0-1
    return Color.lerp(
      const Color(0xFFE57373), // Tired red/orange
      const Color(0xFF7C4DFF), // Restful purple
      value,
    )!;
  }

  // Energy Level: drained gray/red to vibrant yellow/green
  Color _getEnergyColor() {
    final value = (_energyLevel - 1) / 4;
    return Color.lerp(
      const Color(0xFF9E9E9E), // Drained gray
      const Color(0xFF66BB6A), // Vibrant green
      value,
    )!;
  }

  // Academic Stress: stressed red to calm green (1=bad/red, 5=good/green)
  Color _getStressColor() {
    final value = (_academicStress - 1) / 4;
    return Color.lerp(
      const Color(0xFFEF5350), // Stressed red
      const Color(0xFF4CAF50), // Calm green
      value,
    )!;
  }

  Future<void> _saveReadiness() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('morning_readiness')
          .doc(dateKey)
          .set({
            'sleepQuality': _sleepQuality.round(),
            'energyLevel': _energyLevel.round(),
            'academicStress': _academicStress.round(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _showSavedOverlay = true;
          _isSaving = false;
        });
        _checkmarkController.forward();

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving morning readiness: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF5EDE6);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark
        ? const Color(0xFF252528)
        : const Color(0xFFE5E5E7);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(38),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Morning Readiness',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: UniversalCloseButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'How are you feeling this morning?',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Three vertical sliders
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Sleep Quality Slider
                        Expanded(
                          child: _buildVerticalSliderSection(
                            title: 'Sleep Quality',
                            icon: CupertinoIcons.moon_fill,
                            value: _sleepQuality,
                            label: _getSleepLabel(),
                            color: _getSleepColor(),
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _sleepQuality = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Energy Level Slider
                        Expanded(
                          child: _buildVerticalSliderSection(
                            title: 'Energy Level',
                            icon: CupertinoIcons.bolt_fill,
                            value: _energyLevel,
                            label: _getEnergyLabel(),
                            color: _getEnergyColor(),
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _energyLevel = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Academic Stress Slider
                        Expanded(
                          child: _buildVerticalSliderSection(
                            title: 'Stress Level',
                            icon: CupertinoIcons.book_fill,
                            value: _academicStress,
                            label: _getStressLabel(),
                            color: _getStressColor(),
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _academicStress = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: UniversalButton(
                    text: _isSaving ? 'Saving...' : 'Save',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? () {} : _saveReadiness,
                  ),
                ),
              ],
            ),
          ),

          // Saved overlay with checkmark animation
          if (_showSavedOverlay)
            Container(
              decoration: BoxDecoration(
                color: bgColor,
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
                          color: tealColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: tealColor,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _checkmarkAnimation,
                      child: Text(
                        'Saved',
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

  Widget _buildVerticalSliderSection({
    required String title,
    required IconData icon,
    required double value,
    required String label,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Icon with color
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Vertical Pill Slider (same style as mood tracker)
          Expanded(
            child: _buildVerticalPillSlider(
              value: value,
              color: color,
              trackColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 12),
          // Value indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${value.round()}',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalPillSlider({
    required double value,
    required Color color,
    required Color trackColor,
    required ValueChanged<double> onChanged,
  }) {
    const double trackWidth = 40.0;
    const double thumbSize = 32.0;
    const double padding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        final usableHeight = trackHeight - thumbSize - (padding * 2);
        // Invert because we want 5 at top, 1 at bottom
        final normalizedValue = (value - 1) / 4; // Convert 1-5 to 0-1
        final thumbY = padding + ((1 - normalizedValue) * usableHeight);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            final newY = details.localPosition.dy - (thumbSize / 2);
            final newNormalized =
                1 - ((newY - padding) / usableHeight).clamp(0.0, 1.0);
            final newValue = 1 + (newNormalized * 4); // Convert 0-1 back to 1-5
            onChanged(newValue.clamp(1.0, 5.0));
          },
          onTapDown: (details) {
            final newY = details.localPosition.dy - (thumbSize / 2);
            final newNormalized =
                1 - ((newY - padding) / usableHeight).clamp(0.0, 1.0);
            final newValue = 1 + (newNormalized * 4);
            onChanged(newValue.clamp(1.0, 5.0));
          },
          child: Center(
            child: Container(
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(trackWidth / 2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: padding,
                    top: thumbY,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows the Morning Readiness modal bottom sheet
Future<bool?> showMorningReadinessModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const MorningReadinessModal(),
  );
}
