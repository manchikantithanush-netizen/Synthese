import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:intl/intl.dart';

import 'food_analysis_service.dart';
import 'diet_onboarding.dart';
import 'water_tracker_widget.dart';
import '../ui/components/universalbutton.dart';
import '../ui/components/universalresetbutton.dart';

class DietPage extends StatefulWidget {
  final Function(bool)? onModalStateChanged;

  const DietPage({super.key, this.onModalStateChanged});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  late ImagePicker _picker;
  late FoodAnalysisService _foodService;

  File? _selectedImage;
  FoodAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  final List<FoodLogEntry> _foodLog = [];

  // Water tracking state
  int _waterGlasses = 0;
  String _activeWaterDayKey = '';
  static int _dailyWaterGoal = 8; // Will be fetched from Firestore
  double _baselineWaterIntakeLitres = 2.0; // From first onboarding
  List<double> _weeklyWaterIntakeLitres = []; // Last 7 days

  // Orange theme color
  static const Color orangeColor = Color(0xFFFF9500);

  // Onboarding state
  bool? _dietSetupCompleted;
  int _dailyCalorieGoal = 2000;

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _foodService = FoodAnalysisService();
    _checkDietSetup();
    _loadFoodLogs();
    _loadTodayWaterIntake();
    _loadWaterHistory();
  }

  String _waterDayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _checkDietSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final completed = doc.data()?['dietSetupCompleted'] as bool? ?? false;
    final goal = doc.data()?['dailyCalorieGoal'] as int? ?? 2000;
    final waterGoal = doc.data()?['dailyWaterGoalGlasses'] as int? ?? 8;
    final baseline = doc.data()?['waterIntake'] as num? ?? 2.0;

    if (mounted) {
      setState(() {
        _dietSetupCompleted = completed;
        _dailyCalorieGoal = goal;
        _dailyWaterGoal = waterGoal;
        _baselineWaterIntakeLitres = baseline.toDouble();
      });
    }
  }

  Future<void> _loadWaterHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final weeklyData = <double>[];

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayKey = _waterDayKey(day);
        final dayDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('waterDaily')
            .doc(dayKey)
            .get();
        final totalGlasses = (dayDoc.data()?['glasses'] as num?)?.toInt() ?? 0;
        final litres = totalGlasses * 0.25;
        weeklyData.add(litres);
      }

      if (mounted) {
        setState(() {
          _weeklyWaterIntakeLitres = weeklyData;
        });
      }
    } catch (e) {
      debugPrint("Error loading water history: $e");
    }
  }

  Future<void> _loadTodayWaterIntake() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final todayKey = _waterDayKey(now);
      final dayDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterDaily')
          .doc(todayKey)
          .get();

      final glasses = (dayDoc.data()?['glasses'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() {
          _waterGlasses = glasses;
          _activeWaterDayKey = todayKey;
        });
      }
    } catch (e) {
      debugPrint("Error loading today's water intake: $e");
    }
  }

  Future<void> _saveWaterIntake(int glasses) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final todayKey = _waterDayKey(now);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterDaily')
          .doc(todayKey)
          .set({
            'dateKey': todayKey,
            'glasses': glasses,
            'litres': glasses * 0.25,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _activeWaterDayKey = todayKey;
        });
      }

      // Reload water history to update the graph
      await _loadWaterHistory();
    } catch (e) {
      debugPrint("Error saving water intake: $e");
    }
  }

  Future<void> _loadFoodLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Load today's food logs only
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('timestamp', descending: true)
          .get();

      if (mounted) {
        final loadedLogs = snapshot.docs.map((doc) {
          final data = doc.data();
          return FoodLogEntry(
            foodName: data['foodName'] ?? 'Unknown',
            calories: data['calories'] ?? 0,
            description: data['description'] ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageFile: null, // Images are not stored in Firestore
            protein: data['protein'] ?? 0,
            carbs: data['carbs'] ?? 0,
            fats: data['fats'] ?? 0,
            firestoreId: doc.id, // Store the document ID
          );
        }).toList();

        setState(() {
          _foodLog.clear();
          _foodLog.addAll(loadedLogs);
        });
      }
    } catch (e) {
      debugPrint('Error loading food logs: $e');
    }
  }

  Future<String?> _saveFoodLog(FoodLogEntry entry) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('foodLogs')
          .add({
            'foodName': entry.foodName,
            'calories': entry.calories,
            'description': entry.description,
            'timestamp': Timestamp.fromDate(entry.timestamp),
            'protein': entry.protein,
            'carbs': entry.carbs,
            'fats': entry.fats,
          });
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving food log: $e');
      return null;
    }
  }

  void _onDietOnboardingComplete() {
    setState(() => _dietSetupCompleted = true);
    _checkDietSetup(); // Refresh the goal data
  }

  Future<void> _handleResetDietData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Reset Diet Data?", style: TextStyle(color: textColor)),
        content: Text(
          "This will clear your calorie goal and food log, and send you back to the onboarding screen. This cannot be undone.",
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
              "Reset Data",
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
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'dietSetupCompleted': false,
          'dailyCalorieGoal': 2000,
          'dailyWaterGoalGlasses': 8,
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() {
            _dietSetupCompleted = false;
            _dailyCalorieGoal = 2000;
            _dailyWaterGoal = 8;
            _waterGlasses = 0;
            _activeWaterDayKey = _waterDayKey(DateTime.now());
            _weeklyWaterIntakeLitres = List.filled(7, 0.0);
            _foodLog.clear();
            _selectedImage = null;
            _analysisResult = null;
          });
        }

        HapticFeedback.mediumImpact();
      } catch (e) {
        debugPrint("Error resetting diet data: $e");
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });

        _analyzeImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);
    HapticFeedback.selectionClick();

    final result = await _foodService.analyzeFood(_selectedImage!);

    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      // Haptic feedback based on result
      if (result.success) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _addToLog() async {
    if (_analysisResult == null || !_analysisResult!.success) return;

    HapticFeedback.mediumImpact();

    final newEntry = FoodLogEntry(
      foodName: _analysisResult!.foodName,
      calories: _analysisResult!.estimatedCalories,
      description: _analysisResult!.description,
      timestamp: DateTime.now(),
      imageFile: _selectedImage,
      protein: _analysisResult!.protein,
      carbs: _analysisResult!.carbs,
      fats: _analysisResult!.fats,
    );

    setState(() {
      _foodLog.insert(0, newEntry);
      _selectedImage = null;
      _analysisResult = null;
    });

    // Save to Firestore and update with document ID
    final docId = await _saveFoodLog(newEntry);
    if (docId != null && mounted) {
      setState(() {
        final index = _foodLog.indexOf(newEntry);
        if (index >= 0) {
          _foodLog[index] = FoodLogEntry(
            foodName: newEntry.foodName,
            calories: newEntry.calories,
            description: newEntry.description,
            timestamp: newEntry.timestamp,
            imageFile: newEntry.imageFile,
            protein: newEntry.protein,
            carbs: newEntry.carbs,
            fats: newEntry.fats,
            firestoreId: docId,
          );
        }
      });
    }

    // Trigger haptic after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    bool isDark,
  ) async {
    bool result = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Food Log',
      message:
          'Are you sure you want to delete this food entry? This will remove it from your calorie count.',
      icon: 'trash.fill',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Delete',
          style: AlertActionStyle.destructive,
          onPressed: () {
            HapticFeedback.lightImpact();
            result = true;
          },
        ),
      ],
    );
    return result;
  }

  void _deleteFoodLog(int index) async {
    if (index >= 0 && index < _foodLog.length) {
      final entry = _foodLog[index];

      setState(() {
        _foodLog.removeAt(index);
      });

      HapticFeedback.mediumImpact();

      // Delete from Firestore if it has a document ID
      if (entry.firestoreId != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('foodLogs')
                .doc(entry.firestoreId)
                .delete();
          } catch (e) {
            debugPrint('Error deleting food log from Firestore: $e');
          }
        }
      }
    }
  }

  void _showImageSourcePicker() {
    HapticFeedback.lightImpact();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Image Source'),
        message: const Text('Choose where to get your food image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Photo Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  int get _totalCaloriesToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _foodLog
        .where((entry) {
          final entryDate = DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          );
          return entryDate == today;
        })
        .fold(0, (sum, entry) => sum + entry.calories);
  }

  int get _totalProteinToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _foodLog
        .where((entry) {
          final entryDate = DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          );
          return entryDate == today;
        })
        .fold(0, (sum, entry) => sum + entry.protein);
  }

  int get _totalCarbsToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _foodLog
        .where((entry) {
          final entryDate = DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          );
          return entryDate == today;
        })
        .fold(0, (sum, entry) => sum + entry.carbs);
  }

  int get _totalFatsToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _foodLog
        .where((entry) {
          final entryDate = DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          );
          return entryDate == today;
        })
        .fold(0, (sum, entry) => sum + entry.fats);
  }

  Widget _buildGoalCalendar({
    required BuildContext context,
    required String title,
    required Stream<Map<String, int>> goalsByDateStream,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF151515) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black;
    final now = DateTime.now();
    final isNarrow = MediaQuery.of(context).size.width < 380;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: isNarrow ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isNarrow ? 56 : 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const itemWidth = 48.0;
                final totalWidth = 14 * itemWidth;
                final scrollOffset = (totalWidth - constraints.maxWidth).clamp(
                  0.0,
                  double.infinity,
                );
                final controller = ScrollController(
                  initialScrollOffset: scrollOffset,
                );

                return StreamBuilder<Map<String, int>>(
                  stream: goalsByDateStream,
                  builder: (context, snapshot) {
                    final goalsByDate = snapshot.data ?? const <String, int>{};

                    return ListView.builder(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final daysAgo = 13 - index;
                        final date = now.subtract(Duration(days: daysAgo));
                        final isToday = daysAgo == 0;
                        final dateKey = _dateKey(date);
                        final achieved = (goalsByDate[dateKey] ?? 0) > 0;

                        return _buildGoalCalendarDay(
                          context: context,
                          date: date,
                          isToday: isToday,
                          achieved: achieved,
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

  Widget _buildGoalCalendarDay({
    required BuildContext context,
    required DateTime date,
    required bool isToday,
    required bool achieved,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    const achievedColor = Color(0xFF30D158);
    const notAchievedColor = Color(0xFFFFCC00);
    final statusColor = achieved ? achievedColor : notAchievedColor;

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
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: statusColor, width: 2) : null,
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.circle_fill,
                color: statusColor,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, int>> _calorieGoalStatusStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const <String, int>{});
    }

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 13));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('foodLogs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .snapshots()
        .map((snapshot) {
          final caloriesByDate = <String, int>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final ts = data['timestamp'] as Timestamp?;
            if (ts == null) continue;

            final date = ts.toDate();
            final key = _dateKey(DateTime(date.year, date.month, date.day));
            final calories = (data['calories'] as num?)?.toInt() ?? 0;
            caloriesByDate[key] = (caloriesByDate[key] ?? 0) + calories;
          }

          final result = <String, int>{};
          for (int i = 0; i <= 13; i++) {
            final day = startDate.add(Duration(days: i));
            final key = _dateKey(day);
            final total = caloriesByDate[key] ?? 0;
            result[key] = total >= _dailyCalorieGoal ? 1 : 0;
          }
          return result;
        });
  }

  Stream<Map<String, int>> _waterGoalStatusStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const <String, int>{});
    }

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 13));
    final startKey = _dateKey(startDate);
    final endKey = _dateKey(DateTime(now.year, now.month, now.day));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('waterDaily')
        .where('dateKey', isGreaterThanOrEqualTo: startKey)
        .where('dateKey', isLessThanOrEqualTo: endKey)
        .snapshots()
        .map((snapshot) {
          final achievedByDate = <String, int>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final key = data['dateKey'] as String?;
            if (key == null) continue;
            final glasses = (data['glasses'] as num?)?.toInt() ?? 0;
            achievedByDate[key] = glasses >= _dailyWaterGoal ? 1 : 0;
          }

          for (int i = 0; i <= 13; i++) {
            final day = startDate.add(Duration(days: i));
            final key = _dateKey(day);
            achievedByDate[key] = achievedByDate[key] ?? 0;
          }
          return achievedByDate;
        });
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding if not completed
    if (_dietSetupCompleted == false) {
      return DietOnboarding(onContinue: _onDietOnboardingComplete);
    }

    // Show loading while checking
    if (_dietSetupCompleted == null) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safePadding = mediaQuery.padding;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withOpacity(0.5);
    final cardColor = isDark ? const Color(0xFF151515) : Colors.grey.shade100;
    final isNarrow = mediaQuery.size.width < 380;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(clampedTextScale.toDouble()),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: safePadding.top + 24.0,
            bottom: safePadding.bottom + 120.0,
            left: 24.0,
            right: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reset button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Food Tracker",
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
                      _handleResetDietData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Track your calories with AI",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              _buildGoalCalendar(
                context: context,
                title: "Calorie Goal",
                goalsByDateStream: _calorieGoalStatusStream(),
              ),
              const SizedBox(height: 16),

              // Today's Calories Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI accuracy disclaimer label (top, less visible)
                    Opacity(
                      opacity: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: Color(0xFFFF9500),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "AI estimates may be inaccurate",
                              style: TextStyle(
                                color: Color(0xFFFF9500),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: orangeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.flame_fill,
                            color: orangeColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Today's Intake",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Goal: $_dailyCalorieGoal",
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<int>(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          tween: IntTween(begin: 0, end: _totalCaloriesToday),
                          builder: (context, value, child) {
                            return Text(
                              "$value",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -2,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "/ $_dailyCalorieGoal",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "calories",
                      style: TextStyle(color: subTextColor, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Progress bar with animation
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(
                          begin: 0.0,
                          end: _dailyCalorieGoal > 0
                              ? (_totalCaloriesToday / _dailyCalorieGoal).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0.0,
                        ),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(
                                _totalCaloriesToday,
                                _dailyCalorieGoal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _getProgressMessage(
                          _totalCaloriesToday,
                          _dailyCalorieGoal,
                        ),
                        key: ValueKey(
                          _getProgressMessage(
                            _totalCaloriesToday,
                            _dailyCalorieGoal,
                          ),
                        ),
                        style: TextStyle(
                          color: _getProgressColor(
                            _totalCaloriesToday,
                            _dailyCalorieGoal,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Macros mini cards for today's totals
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroCard(
                            'Protein',
                            '${_totalProteinToday}g',
                            const Color(0xFF30D158), // Green
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroCard(
                            'Carbs',
                            '${_totalCarbsToday}g',
                            const Color(0xFF32ADE6), // Blue
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroCard(
                            'Fats',
                            '${_totalFatsToday}g',
                            const Color(0xFFFFCC00), // Yellow
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analyze Food",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Preview or Upload Button
                    if (_selectedImage != null) ...[
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Analysis Result
                      if (_isAnalyzing) ...[
                        Center(
                          child: Column(
                            children: [
                              const CupertinoActivityIndicator(),
                              const SizedBox(height: 12),
                              Text(
                                "Analyzing your food...",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_analysisResult != null) ...[
                        if (_analysisResult!.success) ...[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey(_analysisResult!.estimatedCalories),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: orangeColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Food name with success icon
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons
                                                .checkmark_circle_fill,
                                            color: orangeColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _analysisResult!.foodName,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // AI Disclaimer
                                      Text(
                                        "AI-Estimated Nutritional Info",
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Calories
                                      Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.flame_fill,
                                            color: orangeColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${_analysisResult!.estimatedCalories}",
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "kcal",
                                            style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Macros - 3 mini cards side by side
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildMacroCard(
                                              'Protein',
                                              '${_analysisResult!.protein}g',
                                              const Color(0xFF30D158), // Green
                                              isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildMacroCard(
                                              'Carbs',
                                              '${_analysisResult!.carbs}g',
                                              const Color(0xFF32ADE6), // Blue
                                              isDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildMacroCard(
                                              'Fats',
                                              '${_analysisResult!.fats}g',
                                              const Color(0xFFFFCC00), // Yellow
                                              isDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _analysisResult!.description,
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: UniversalButton(
                                        text: "Add to Log",
                                        onPressed: _addToLog,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    UniversalResetButton(
                                      onPressed: _analyzeImage,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _analysisResult!.errorMessage ??
                                        'Analysis failed',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          CNButton(
                            label: "Try Again",
                            style: CNButtonStyle.glass,
                            onPressed: _analyzeImage,
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      UniversalButton(
                        text: "Choose Different Image",
                        onPressed: _showImageSourcePicker,
                      ),
                    ] else ...[
                      // Empty state - upload button
                      GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.camera_fill,
                                color: subTextColor,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Tap to upload food image",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Camera or Photo Library",
                                style: TextStyle(
                                  color: subTextColor.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Food Log Section
              if (_foodLog.isNotEmpty) ...[
                Text(
                  "Food Log",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...(_foodLog.asMap().entries.map((entry) {
                  final index = entry.key;
                  final logEntry = entry.value;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(logEntry.timestamp),
                    duration: Duration(milliseconds: 400 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Dismissible(
                      key: Key(logEntry.timestamp.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        HapticFeedback.mediumImpact();
                        return await _showDeleteConfirmation(context, isDark);
                      },
                      onDismissed: (direction) {
                        _deleteFoodLog(index);
                      },
                      child: _buildFoodLogEntry(
                        logEntry,
                        isDark,
                        textColor,
                        subTextColor,
                        cardColor,
                      ),
                    ),
                  );
                })),
              ],

              const SizedBox(height: 32),

              _buildGoalCalendar(
                context: context,
                title: "Water Goal",
                goalsByDateStream: _waterGoalStatusStream(),
              ),
              const SizedBox(height: 16),

              // Water Tracking Section
              WaterTrackerSection(
                waterGlasses: _waterGlasses,
                dailyGoal: _dailyWaterGoal,
                onWaterChanged: (newValue) async {
                  final todayKey = _waterDayKey(DateTime.now());
                  final crossedIntoNewDay =
                      _activeWaterDayKey.isNotEmpty &&
                      _activeWaterDayKey != todayKey;

                  int valueToPersist = newValue;
                  if (crossedIntoNewDay) {
                    // If midnight passed while app stayed open, start a fresh day.
                    final isIncrement = newValue > _waterGlasses;
                    valueToPersist = isIncrement ? 1 : 0;
                  }

                  setState(() {
                    _waterGlasses = valueToPersist;
                    _activeWaterDayKey = todayKey;
                  });
                  await _saveWaterIntake(valueToPersist);
                },
                isDark: isDark,
                textColor: textColor,
                subTextColor: subTextColor,
                cardColor: cardColor,
                baselineWaterIntakeLitres: _baselineWaterIntakeLitres,
                weeklyIntakeLitres: _weeklyWaterIntakeLitres,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodLogEntry(
    FoodLogEntry entry,
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color cardColor,
  ) {
    final timeStr = _formatTime(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (entry.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                entry.imageFile!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: orangeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.flame_fill,
                color: orangeColor,
                size: 24,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${entry.calories}",
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text("kcal", style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(time.year, time.month, time.day);

    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    if (entryDate == today) {
      return 'Today at $hour:$minute $period';
    } else if (entryDate == yesterday) {
      return 'Yesterday at $hour:$minute $period';
    } else {
      return '${time.month}/${time.day} at $hour:$minute $period';
    }
  }

  Color _getProgressColor(int current, int goal) {
    if (goal == 0) return Colors.grey;
    final percentage = current / goal;

    if (percentage < 0.7)
      return const Color(0xFF30D158); // Green - well under goal
    if (percentage < 0.9) return orangeColor; // Orange - approaching goal
    if (percentage <= 1.0) return const Color(0xFFFFCC00); // Yellow - near goal
    return const Color(0xFFFF453A); // Red - over goal
  }

  String _getProgressMessage(int current, int goal) {
    if (goal == 0) return "Set a goal to track progress";
    final remaining = goal - current;

    if (remaining > 0) {
      return "$remaining cal remaining";
    } else if (remaining == 0) {
      return "Goal reached!";
    } else {
      return "${remaining.abs()} cal over goal";
    }
  }

  Widget _buildMacroCard(String label, String value, Color color, bool isDark) {
    // Extract numeric value for animation
    final numericValue =
        int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: IntTween(begin: 0, end: numericValue),
            builder: (context, animatedValue, child) {
              return Text(
                '${animatedValue}g',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class FoodLogEntry {
  final String foodName;
  final int calories;
  final String description;
  final DateTime timestamp;
  final File? imageFile;
  final int protein;
  final int carbs;
  final int fats;
  final String? firestoreId; // Add Firestore document ID

  FoodLogEntry({
    required this.foodName,
    required this.calories,
    required this.description,
    required this.timestamp,
    this.imageFile,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.firestoreId,
  });
}
