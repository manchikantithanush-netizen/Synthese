import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';

class BreathingExerciseModal extends StatefulWidget {
  const BreathingExerciseModal({super.key});

  @override
  State<BreathingExerciseModal> createState() => _BreathingExerciseModalState();
}

class _BreathingExerciseModalState extends State<BreathingExerciseModal>
    with TickerProviderStateMixin {
  int _selectedTechnique = 0;
  
  static const List<String> _techniques = ['Box', '4-7-8', 'Simple'];
  static const Color tealColor = Color(0xFF33BEBE);
  
  // Animation state
  bool _isRunning = false;
  String _currentPhase = 'rest';
  int _secondsRemaining = 0;
  int _totalSecondsElapsed = 0;
  
  // Animation controllers
  late AnimationController _breathingController;
  late Animation<double> _breathProgress;
  late AnimationController _rippleController;
  
  Timer? _phaseTimer;
  Timer? _elapsedTimer;
  Timer? _hapticTimer;

  String get _currentTechniqueName => _techniques[_selectedTechnique];
  
  Map<String, List<int>> get _techniqueTimings => {
    'Box': [4, 4, 4, 4],
    '4-7-8': [4, 7, 8, 0],
    'Simple': [4, 0, 4, 0],
  };
  
  List<int> get _currentTimings => _techniqueTimings[_currentTechniqueName]!;
  
  Duration get _totalDuration {
    final timings = _currentTimings;
    return Duration(seconds: timings.reduce((a, b) => a + b));
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    final timings = _currentTimings;
    final total = timings.reduce((a, b) => a + b).toDouble();
    
    _breathingController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    
    _breathProgress = _buildBreathAnimation(timings, total);
    
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isRunning) {
        _breathingController.reset();
        _breathingController.forward();
      }
    });
  }
  
  Animation<double> _buildBreathAnimation(List<int> timings, double total) {
    final List<TweenSequenceItem<double>> items = [];
    
    if (timings[0] > 0) {
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: timings[0] / total,
      ));
    }
    
    if (timings[1] > 0) {
      items.add(TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: timings[1] / total,
      ));
    }
    
    if (timings[2] > 0) {
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: timings[2] / total,
      ));
    }
    
    if (timings[3] > 0) {
      items.add(TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: timings[3] / total,
      ));
    }
    
    return TweenSequence<double>(items).animate(_breathingController);
  }
  
  void _resetAnimations() {
    _breathingController.dispose();
    _rippleController.dispose();
    _initAnimations();
  }
  
  void _startExercise() {
    setState(() {
      _isRunning = true;
      _totalSecondsElapsed = 0;
    });
    
    _breathingController.forward();
    _rippleController.repeat();
    _startPhaseTracking();
    _startElapsedTimer();
  }
  
  void _pauseExercise() {
    setState(() => _isRunning = false);
    _breathingController.stop();
    _rippleController.stop();
    _phaseTimer?.cancel();
    _elapsedTimer?.cancel();
    _hapticTimer?.cancel();
  }
  
  void _startBreathingHaptics(String phase, int duration) {
    _hapticTimer?.cancel();
    
    if (phase == 'inhale') {
      int tick = 0;
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
        if (!_isRunning || tick >= (duration * 2.5)) {
          timer.cancel();
          return;
        }
        HapticFeedback.lightImpact();
        tick++;
      });
    } else if (phase == 'exhale') {
      int tick = 0;
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_isRunning || tick >= (duration * 2)) {
          timer.cancel();
          return;
        }
        HapticFeedback.selectionClick();
        tick++;
      });
    } else if (phase == 'hold') {
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (!_isRunning) {
          timer.cancel();
          return;
        }
        HapticFeedback.selectionClick();
      });
    }
  }
  
  void _startPhaseTracking() {
    final timings = _currentTimings;
    int phaseIndex = 0;
    final phases = ['inhale', 'hold', 'exhale', 'hold'];
    
    void startNextPhase() {
      if (!_isRunning) return;
      
      while (timings[phaseIndex] == 0) {
        phaseIndex = (phaseIndex + 1) % 4;
      }
      
      final phaseDuration = timings[phaseIndex];
      final phaseName = phases[phaseIndex];
      
      setState(() {
        _currentPhase = phaseName;
        _secondsRemaining = phaseDuration;
      });
      
      HapticFeedback.mediumImpact();
      _startBreathingHaptics(phaseName, phaseDuration);
      
      _phaseTimer?.cancel();
      _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isRunning) {
          timer.cancel();
          return;
        }
        
        setState(() {
          _secondsRemaining--;
        });
        
        if (_secondsRemaining <= 0) {
          timer.cancel();
          phaseIndex = (phaseIndex + 1) % 4;
          
          if (phaseIndex == 0) {
            HapticFeedback.heavyImpact();
          }
          
          startNextPhase();
        }
      });
    }
    
    startNextPhase();
  }
  
  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      setState(() {
        _totalSecondsElapsed++;
      });
    });
  }
  
  void _onTechniqueChanged(int value) {
    HapticFeedback.selectionClick();
    
    if (_isRunning) {
      _pauseExercise();
    }
    
    setState(() {
      _selectedTechnique = value;
      _currentPhase = 'rest';
      _secondsRemaining = 0;
      _totalSecondsElapsed = 0;
    });
    
    _resetAnimations();
  }
  
  String get _instructionText {
    switch (_currentPhase) {
      case 'inhale':
        return 'Breathe In';
      case 'hold':
        return 'Hold';
      case 'exhale':
        return 'Breathe Out';
      default:
        return 'Tap Start';
    }
  }
  
  String get _timerText {
    final minutes = _totalSecondsElapsed ~/ 60;
    final seconds = _totalSecondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    _phaseTimer?.cancel();
    _elapsedTimer?.cancel();
    _hapticTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Warm, calm background colors
    final bgColor = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF5EDE6);
    final textColor = isDark ? Colors.white : Colors.black;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: Column(
          children: [
            // Header with title
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Breathing Exercise',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CNButton.icon(
                      icon: const CNSymbol('xmark'),
                      style: CNButtonStyle.glass,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (_isRunning) {
                          _pauseExercise();
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Technique selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: CNSegmentedControl(
                labels: _techniques,
                selectedIndex: _selectedTechnique,
                onValueChanged: _onTechniqueChanged,
              ),
            ),

            // Instruction text below segmented control
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _instructionText,
                  key: ValueKey(_currentPhase + _isRunning.toString()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Main breathing visualization - centered
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _breathProgress,
                    _rippleController,
                  ]),
                  builder: (context, child) {
                    return SizedBox(
                      width: 320,
                      height: 320,
                      child: CustomPaint(
                        size: const Size(320, 320),
                        painter: _RippleBreathPainter(
                          progress: _breathProgress.value,
                          rippleProgress: _rippleController.value,
                          isRunning: _isRunning,
                          phase: _currentPhase,
                          isDark: isDark,
                        ),
                        child: Center(
                          child: _isRunning && _secondsRemaining > 0
                              ? Text(
                                  '$_secondsRemaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -2,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Timer display
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _timerText,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CNButton(
                    label: _isRunning ? 'Pause' : 'Start',
                    style: CNButtonStyle.prominentGlass,
                    tint: tealColor,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (_isRunning) {
                        _pauseExercise();
                      } else {
                        _startExercise();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Warm minimal concentric ripple painter
class _RippleBreathPainter extends CustomPainter {
  final double progress; // 0.0 = contracted, 1.0 = expanded
  final double rippleProgress;
  final bool isRunning;
  final String phase;
  final bool isDark;
  
  _RippleBreathPainter({
    required this.progress,
    required this.rippleProgress,
    required this.isRunning,
    required this.phase,
    required this.isDark,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // Warm background-based colors (subtle variations)
    final baseColor = isDark 
        ? const Color(0xFF3A3A40) // Slightly lighter than dark bg
        : const Color(0xFFE8DED4); // Slightly darker than light bg (warm beige)
    
    // Core size that breathes
    const minCore = 60.0;
    const maxCore = 90.0;
    final coreRadius = minCore + (maxCore - minCore) * progress;
    
    // Fixed ring spacing - rings expand outward with breath
    const ringCount = 4;
    const baseSpacing = 30.0;
    final expandFactor = 1.0 + (progress * 0.3); // Rings spread apart as you breathe in
    
    // Draw concentric rings (subtle, barely visible)
    for (int i = ringCount; i >= 1; i--) {
      final ringRadius = coreRadius + (i * baseSpacing * expandFactor);
      if (ringRadius > maxRadius + 20) continue;
      
      // Subtle opacity - barely visible, fading outward
      final opacity = (0.25 - (i * 0.05)).clamp(0.08, 0.25);
      
      final ringPaint = Paint()
        ..color = baseColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
    
    // Main central circle - solid, warm color
    final corePaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, corePaint);
    
    // Soft outer edge on core
    final coreEdgePaint = Paint()
      ..color = baseColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, coreRadius, coreEdgePaint);
  }
  
  @override
  bool shouldRepaint(covariant _RippleBreathPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        rippleProgress != oldDelegate.rippleProgress ||
        isRunning != oldDelegate.isRunning;
  }
}
