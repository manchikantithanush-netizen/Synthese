import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _MoodTrackerModalState extends State<MoodTrackerModal> with SingleTickerProviderStateMixin {
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
      description: "It's rough right now. Give yourself grace — you're doing what you can.",
      subFeelings: [
        'Angry', 'Anxious', 'Scared', 'Overwhelmed', 'Ashamed',
        'Devastated', 'Panicked', 'Hopeless', 'Furious', 'Terrified',
        'Disgusted', 'Resentful', 'Miserable',
      ],
    ),
    MoodOption(
      value: 1/6,
      label: 'Unpleasant',
      color: Color.fromRGBO(177, 106, 23, 1),
      description: "Things feel heavy. Take it one step at a time.",
      subFeelings: [
        'Frustrated', 'Worried', 'Sad', 'Stressed', 'Lonely',
        'Disappointed', 'Insecure', 'Irritated', 'Guilty', 'Hurt',
        'Nervous', 'Jealous', 'Embarrassed',
      ],
    ),
    MoodOption(
      value: 2/6,
      label: 'Slightly Unpleasant',
      color: Color.fromRGBO(194, 150, 40, 1),
      description: "A little off-track. Not great, but you're hanging in there.",
      subFeelings: [
        'Tired', 'Bored', 'Uneasy', 'Distracted', 'Restless',
        'Apathetic', 'Drained', 'Impatient', 'Disconnected', 'Sluggish',
        'Uncertain', 'Unfocused', 'Melancholic',
      ],
    ),
    MoodOption(
      value: 3/6,
      label: 'Neutral',
      color: Color.fromRGBO(48, 127, 216, 1),
      description: "Balanced and centered. Ready for what's next.",
      subFeelings: [
        'Content', 'Calm', 'Peaceful', 'Indifferent', 'Steady',
        'Balanced', 'Accepting', 'Present', 'Mellow', 'Composed',
        'Grounded', 'Reserved', 'Thoughtful',
      ],
    ),
    MoodOption(
      value: 4/6,
      label: 'Slightly Pleasant',
      color: Color.fromRGBO(82, 145, 50, 1),
      description: "Doing alright! A steady, positive energy is building.",
      subFeelings: [
        'Hopeful', 'Relaxed', 'Focused', 'Grateful', 'Optimistic',
        'Curious', 'Refreshed', 'Relieved', 'Comfortable', 'Open',
        'Encouraged', 'Interested', 'Serene',
      ],
    ),
    MoodOption(
      value: 5/6,
      label: 'Pleasant',
      color: Color.fromRGBO(52, 98, 18, 1),
      description: "Feeling solid and on track. You've got a good flow going.",
      subFeelings: [
        'Happy', 'Confident', 'Energized', 'Motivated', 'Joyful',
        'Proud', 'Fulfilled', 'Cheerful', 'Playful', 'Empowered',
        'Creative', 'Appreciated', 'Loving',
      ],
    ),
    MoodOption(
      value: 1.0,
      label: 'Very Pleasant',
      color: Color.fromRGBO(17, 99, 76, 1),
      description: "Absolutely great! You're in peak form and feeling energized.",
      subFeelings: [
        'Amazed', 'Excited', 'Surprised', 'Passionate', 'Inspired',
        'Euphoric', 'Thrilled', 'Elated', 'Ecstatic', 'Blissful',
        'Radiant', 'Alive', 'Grateful',
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
    if (_moodValue <= 1/7) return 0;
    if (_moodValue <= 2/7) return 1;
    if (_moodValue <= 3/7) return 2;
    if (_moodValue <= 4/7) return 3;
    if (_moodValue <= 5/7) return 4;
    if (_moodValue <= 6/7) return 5;
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
    final baseColor = isDark ? const Color(0xFF252528) : const Color(0xFFE5E5E7);
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
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _showLoggedOverlay = true;
          _isSaving = false;
        });
        _checkmarkController.forward();
        
        // Wait and then close
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
    final trackColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);
    
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $amPm';

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: _getModalBackground(isDark),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isOnSecondPage 
                  ? _buildSecondPage(isDark, textColor, subTextColor, currentColor)
                  : _buildFirstPage(isDark, textColor, subTextColor, currentColor, trackColor, timeString),
            ),
          ),
          
          // Logged overlay with checkmark animation
          if (_showLoggedOverlay)
            Container(
              decoration: BoxDecoration(
                color: _getModalBackground(isDark),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
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
                        'Logged',
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

  Widget _buildFirstPage(bool isDark, Color textColor, Color subTextColor, Color currentColor, Color trackColor, String timeString) {
    return Column(
      key: const ValueKey('first'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'How are you feeling?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: CNButton.icon(
                  icon: const CNSymbol('xmark'),
                  style: CNButtonStyle.glass,
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
            border: Border.all(
              color: currentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Log for $timeString',
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
                    "You're feeling",
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
                      _selectedMood.label,
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
                      _selectedMood.description,
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
                      Text('Unpleasant', style: TextStyle(color: subTextColor, fontSize: 12)),
                      Text('Pleasant', style: TextStyle(color: subTextColor, fontSize: 12)),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: CNButton(
                label: 'Next',
                style: CNButtonStyle.prominentGlass,
                tint: currentColor,
                onPressed: _goToSecondPage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondPage(bool isDark, Color textColor, Color subTextColor, Color currentColor) {
    return Column(
      key: const ValueKey('second'),
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CNButton.icon(
                  icon: const CNSymbol('chevron.left'),
                  style: CNButtonStyle.glass,
                  onPressed: _goBack,
                ),
              ),
              Text(
                'Describe your feeling',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: CNButton.icon(
                  icon: const CNSymbol('xmark'),
                  style: CNButtonStyle.glass,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
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
            _selectedMood.label,
            style: TextStyle(
              color: currentColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What best describes this feeling?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Sub-feeling pills
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? currentColor 
                              : currentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected 
                                ? currentColor 
                                : currentColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          feeling,
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : currentColor,
                            fontSize: 16,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: CNButton(
                label: _isSaving ? 'Saving...' : 'Finish',
                style: CNButtonStyle.prominentGlass,
                tint: currentColor,
                onPressed: _isSaving ? () {} : _saveMood,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
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
