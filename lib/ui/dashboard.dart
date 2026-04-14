import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';     
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert'; 

import 'package:synthese/ui/account/accountpage.dart';
import 'package:synthese/cycles/cycles.dart';
import 'package:synthese/finance/finance.dart';
import 'package:synthese/mindfulness/mindfulness_page.dart';
import 'package:synthese/mindfulness/mindfulness_onboarding.dart';
import 'package:synthese/diet/diet_page.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalbottomnavbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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

  // Previous values (for comparisons)
  int? _prevActiveCalories;
  int? _prevHeartRate;
  int? _prevSteps;
  int? _prevExerciseMinutes;
  List<int>? _prevSleepData;

  @override
  void initState() {
    super.initState();
    _updateScore();
    _fetchUserGender(); 
    _fetchMindfulnessOnboarding();
  }

  // --- FETCH USER DATA ---
  Future<void> _fetchUserGender() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
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
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final completed = data?['mindfulnessOnboardingCompleted'] as bool? ?? false;
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

    double healthScore = (stepsScore * 0.25) + (calScore * 0.25) + (exerciseScore * 0.25) + (sleepScore * 0.25);

    _score = healthScore.round();
  }

  // --- SCORE HELPERS ---
  String _getScoreMessage(int score) {
    if (!_hasUploadedOnce && score == 0) return "Upload your data to get started!";
    
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
  ({String text, Color color}) _getTrend(int current, int? previous, double realisticMax, {bool isHeartRate = false}) {
    if (previous == null) {
      return (text: "Not enough data yet", color: Colors.grey.withOpacity(0.5));
    }
    if (current == previous) {
      return (text: "No change", color: Colors.grey.withOpacity(0.5));
    }

    double change = isHeartRate ? (previous - current).toDouble() : (current - previous).toDouble();
    double percentage = (change / realisticMax) * 100.0;
    percentage = percentage.clamp(-100.0, 100.0);
    
    Color c = percentage > 0 ? const Color(0xFF4CAF50) : Colors.redAccent;
    String sign = percentage > 0 ? "+" : "";
    
    return (text: "$sign${percentage.toStringAsFixed(1)}%", color: c);
  }

  ({String text, Color color}) _getSleepTrend(List<int> currentData, List<int>? previousData) {
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
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}";
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
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
    int thu = _sleepData[3], fri = _sleepData[4], sat = _sleepData[5], sun = _sleepData[6];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('=');
      
      if (parts.length >= 2) {
        final key = parts[0].trim().toLowerCase();
        final valStr = parts[1].trim();
        final val = int.tryParse(valStr) ?? 0;

        switch (key) {
          case 'activecal': tempActive = val; break;
          case 'heartrate': tempHR = val; break;
          case 'steps': tempSteps = val; break;
          case 'excersizetime': tempExTime = val; break;
          case 'sleepmon': mon = val; break;
          case 'sleeptue': tue = val; break;
          case 'sleepwed': wed = val; break;
          case 'sleepthur': thu = val; break;
          case 'sleepfri': fri = val; break;
          case 'sleepsat': sat = val; break;
          case 'sleepsun': sun = val; break;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final cardColor = isDark ? const Color(0xFF151515) : Colors.grey.shade100;

    final safePadding = MediaQuery.of(context).padding;

    final avgSleepMinutes = _sleepData.reduce((a, b) => a + b) ~/ 7;
    final maxSleep = math.max(_sleepData.reduce(math.max), 1).toDouble(); 
    
    final calTrend = _getTrend(_activeCalories, _prevActiveCalories, 800);
    final hrTrend = _getTrend(_heartRate, _prevHeartRate, 40, isHeartRate: true);
    final stepTrend = _getTrend(_steps, _prevSteps, 15000);
    final exTrend = _getTrend(_exerciseMinutes, _prevExerciseMinutes, 120);
    final sleepTrend = _getSleepTrend(_sleepData, _prevSleepData);

    // --- DETERMINE WHICH PAGE TO SHOW BASED ON TAB INDEX ---
    Widget currentScreen;
    if (_tabIndex == 0) {
      // Home Tab
      currentScreen = SingleChildScrollView(
        key: const ValueKey('home_tab'), // The key ensures AnimatedSwitcher knows when to animate
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Synthese", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                    const SizedBox(height: 4),
                    Text(_getFormattedDate(), style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                AnimatedOpacity(
                  opacity: _isModalOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: IgnorePointer(
                    ignoring: _isModalOpen,
                    child: Theme(
                      data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent, splashColor: Colors.transparent),
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
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
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
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
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
                    painter: RingPainter(progress: animatedValue, isDark: isDark),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_score.toString(), style: TextStyle(color: textColor, fontSize: 72, fontWeight: FontWeight.w300, height: 1.1, letterSpacing: -2)),
                            Text("SCORE", style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2)),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28.0),
                              child: Text(
                                _getScoreMessage(_score),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _getScoreColor(_score), fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
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
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      cardColor: cardColor, textColor: textColor, subTextColor: subTextColor,
                      icon: Icons.local_fire_department, iconColor: Colors.orange, 
                      trendText: calTrend.text, trendColor: calTrend.color,
                      title: "Active", value: _formatNumber(_activeCalories), unit: "kcal",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      cardColor: cardColor, textColor: textColor, subTextColor: subTextColor,
                      icon: Icons.favorite_border, iconColor: Colors.redAccent, 
                      trendText: hrTrend.text, trendColor: hrTrend.color,
                      title: "Heart Rate", value: _heartRate.toString(), unit: "AVG", valueInlineUnit: true,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- ROW 2: Steps & Exercise Time ---
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      cardColor: cardColor, textColor: textColor, subTextColor: subTextColor,
                      icon: Icons.directions_walk_rounded, iconColor: const Color(0xFF6C63FF), 
                      trendText: stepTrend.text, trendColor: stepTrend.color,
                      title: "Steps", value: _formatNumber(_steps), unit: "steps", valueInlineUnit: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      cardColor: cardColor, textColor: textColor, subTextColor: subTextColor,
                      icon: Icons.timer, iconColor: const Color(0xFFFF4B4B), 
                      trendText: exTrend.text, trendColor: exTrend.color,
                      title: "Exercise Time", value: _formatMinutes(_exerciseMinutes), unit: "AVG", valueInlineUnit: false,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- SLEEP ANALYSIS CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sleep Analysis", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Last 7 Nights", style: TextStyle(color: subTextColor, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatMinutes(avgSleepMinutes), style: const TextStyle(color: Color(0xFFB022FF), fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("AVG DURATION", style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(sleepTrend.text, style: TextStyle(color: sleepTrend.color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      BarChartColumn(label: "M", heightRatio: _sleepData[0] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "T", heightRatio: _sleepData[1] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "W", heightRatio: _sleepData[2] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "T", heightRatio: _sleepData[3] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "F", heightRatio: _sleepData[4] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "S", heightRatio: _sleepData[5] / maxSleep, isDark: isDark),
                      BarChartColumn(label: "S", heightRatio: _sleepData[6] / maxSleep, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_isFemale && _tabIndex == 4) {
      // Cycles Tab
      currentScreen = CyclesPage(
        key: const ValueKey('cycles_tab'),
        onModalStateChanged: (isOpen) {
          setState(() {
            _isModalOpen = isOpen;
          });
        },
      );
    } else if (_tabIndex == 3) {
      // Finance Tab
      currentScreen = FinancePage(
        key: const ValueKey('finance_tab'),
        onModalStateChanged: (isOpen) {
          setState(() {
            _isModalOpen = isOpen;
          });
        },
      );
    } else if (_tabIndex == 2) {
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
            // Save to Firestore
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              try {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'mindfulnessOnboardingCompleted': true,
                });
              } catch (e) {
                debugPrint("Error saving mindfulness onboarding status: $e");
              }
            }
          },
        );
      }
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
    } else {
      currentScreen = Container(key: ValueKey('empty_tab_$_tabIndex'));
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, 
      
      bottomNavigationBar: UniversalBottomNavBar(
        hidden: _isModalOpen,
        currentIndex: _tabIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _tabIndex = index);
        },
        items: _isFemale
            ? [
                const NavItem(label: 'Home', icon: Icons.home_rounded),
                const NavItem(label: 'Diet', icon: Icons.restaurant_rounded),
                const NavItem(label: 'Mindfulness', icon: Icons.self_improvement_rounded),
                const NavItem(label: 'Finance', icon: Icons.account_balance_wallet_rounded),
                const NavItem(label: 'Cycles', icon: Icons.water_drop_rounded),
              ]
            : [
                const NavItem(label: 'Home', icon: Icons.home_rounded),
                const NavItem(label: 'Diet', icon: Icons.restaurant_rounded),
                const NavItem(label: 'Mindfulness', icon: Icons.self_improvement_rounded),
                const NavItem(label: 'Finance', icon: Icons.account_balance_wallet_rounded),
              ],
      ),

      // --- ANIMATED SWITCHER REPLACES YOUR OLD SINGLE CHILD SCROLL VIEW ---
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: currentScreen,
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

  const MetricCard({
    super.key, required this.cardColor, required this.textColor, required this.subTextColor,
    required this.icon, required this.iconColor, required this.trendText, required this.trendColor,
    required this.title, required this.value, required this.unit,
    this.valueInlineUnit = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trendText, 
                  textAlign: TextAlign.right,
                  style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          
          if (valueInlineUnit)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(unit, style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}

class BarChartColumn extends StatelessWidget {
  final String label;
  final double heightRatio;
  final bool isDark;

  const BarChartColumn({super.key, required this.label, required this.heightRatio, required this.isDark});

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
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
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
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}