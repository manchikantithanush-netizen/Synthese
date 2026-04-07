import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DailyLoggingScreen extends StatefulWidget {
  final DateTime? selectedDate; 

  const DailyLoggingScreen({super.key, this.selectedDate});

  @override
  State<DailyLoggingScreen> createState() => _DailyLoggingScreenState();
}

class _DailyLoggingScreenState extends State<DailyLoggingScreen> {
  bool _isSaving = false;
  late DateTime _logDate; 
  
  // Carousel Controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Locks in the date passed to the screen, defaults to today
    _logDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _flow = 'None';
  final List<String> _flowOptions = ['None', 'Spotting', 'Light', 'Medium', 'Heavy', 'Very Heavy'];

  final List<String> _selectedSymptoms = [];
  final List<String> _symptomOptions = [
    'Cramps (mild)', 'Cramps (severe)', 'Bloating', 'Breast tenderness', 
    'Headache', 'Fatigue', 'Lower back pain', 'Nausea', 'Acne', 'Food cravings'
  ];

  final List<String> _selectedMoods = [];
  final List<String> _moodOptions = [
    'Happy', 'Calm', 'Confident', 'Irritable', 'Anxious', 
    'Sad', 'Sensitive', 'Stressed', 'Brain fog', 'Tired'
  ];

  String? _cervicalMucus;
  final List<String> _mucusOptions = ['Dry', 'Sticky', 'Creamy', 'Egg white', 'Watery'];

  final Color pinkColor = const Color(0xFFEC548A);

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  // --- LOGIC REMAINS 100% UNTOUCHED ---
  Future<void> _saveLog() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final DateTime logDateOnly = _dateOnly(_logDate);

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final DateTime lastPeriodStart = (data['lastPeriodStart'] as Timestamp?)?.toDate() ?? DateTime.now();
      final DateTime lastStartOnly = _dateOnly(lastPeriodStart);
      
      final int cycleLength = data['cycleLength'] ?? 28;
      final int periodLength = data['periodLength'] ?? 5;
      final int cycleDay = logDateOnly.difference(lastStartOnly).inDays + 1;
      
      bool isNewPeriod = false;
      bool spottingOutsidePeriod = false;

      if (['Spotting', 'Light', 'Medium', 'Heavy', 'Very Heavy'].contains(_flow)) {
        if (cycleDay <= periodLength + 2) {
          isNewPeriod = false; 
        } else if (cycleDay > periodLength + 4 && cycleDay < (cycleLength - 2)) {
          setState(() => _isSaving = false);
          final bool? isEarlyPeriod = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              title: Text("Did your period start early?", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              content: Text(
                _flow == 'Spotting' 
                  ? "You logged spotting. Is this the start of a new period?"
                  : "You logged bleeding, but your period isn't due yet.", 
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("No, just spotting", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, it started", style: TextStyle(color: Color(0xFFEC548A), fontWeight: FontWeight.bold))),
              ],
            )
          );
          if (isEarlyPeriod == null) return; 
          setState(() => _isSaving = true);
          
          if (isEarlyPeriod == true) isNewPeriod = true; 
          else spottingOutsidePeriod = true; 
          
        } else if (cycleDay >= (cycleLength * 2)) {
          if (_flow == 'Spotting') spottingOutsidePeriod = true; 
          else isNewPeriod = true; 
        } else {
          if (_flow == 'Spotting') {
            setState(() => _isSaving = false);
            final bool? isPeriod = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                title: Text("Did your period start?", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                content: Text("You logged spotting around the time your period is due. Is this the start of your period?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text("No, just spotting", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, it started", style: TextStyle(color: Color(0xFFEC548A), fontWeight: FontWeight.bold))),
                ],
              )
            );
            if (isPeriod == null) return;
            setState(() => _isSaving = true);
            
            if (isPeriod == true) isNewPeriod = true; 
            else spottingOutsidePeriod = true; 
          } else {
            isNewPeriod = true; 
          }
        }
      } 

      final String logId = DateFormat('yyyy-MM-dd').format(_logDate);
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('daily_logs').doc(logId)
          .set({
        'date': logDateOnly,
        'flow': _flow,
        'spottingOutsidePeriod': spottingOutsidePeriod,
        'symptoms': _selectedSymptoms,
        'mood': _selectedMoods,
        'cervicalMucus': _cervicalMucus,
      }, SetOptions(merge: true));

      Map<String, dynamic> userUpdates = {};

      if (isNewPeriod && logDateOnly.isAfter(lastStartOnly)) {
        final logsQuery = await userRef.collection('daily_logs')
            .where('date', isGreaterThanOrEqualTo: lastStartOnly)
            .where('date', isLessThan: logDateOnly)
            .orderBy('date')
            .get();

        DateTime? periodEndDate = lastStartOnly;
        int spottingDays = 0, veryHeavyDays = 0;
        bool isBleedingPhase = true;

        for (var doc in logsQuery.docs) {
          final docData = doc.data();
          final date = (docData['date'] as Timestamp).toDate();
          final f = docData['flow'] as String?;
          final isBleeding = ['Light', 'Medium', 'Heavy', 'Very Heavy'].contains(f);
          
          if (f == 'Very Heavy') veryHeavyDays++;

          if (isBleedingPhase) {
            if (isBleeding && (docData['spottingOutsidePeriod'] != true || date.difference(lastStartOnly).inDays < periodLength + 4)) {
              periodEndDate = date;
            } else if (date.difference(periodEndDate!).inDays > 2) {
              isBleedingPhase = false; 
            }
          } 
          
          if (!isBleedingPhase && (f == 'Spotting' || docData['spottingOutsidePeriod'] == true)) spottingDays++; 
        }

        final int actualPeriodLength = periodEndDate!.difference(lastStartOnly).inDays + 1;
        final int actualCycleLength = logDateOnly.difference(lastStartOnly).inDays.clamp(1, 60);

        final newCycleData = {
          'cycleLength': actualCycleLength,
          'periodLength': actualPeriodLength > 0 ? actualPeriodLength : periodLength, 
          'spottingDays': spottingDays,
          'veryHeavyDays': veryHeavyDays, 
          'startDate': lastStartOnly,
        };

        String cycleDocId = lastStartOnly.toIso8601String();
        await userRef.collection('cycles').doc(cycleDocId).set(newCycleData);

        userUpdates['lastPeriodStart'] = logDateOnly;
        userUpdates['loggedCyclesCount'] = FieldValue.increment(1);
      }

      if (userUpdates.isNotEmpty) await userRef.update(userUpdates);
      if (mounted) Navigator.pop(context, true); 
    } catch (e) {
      debugPrint("Error saving log: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Generate the massive bold header date
  String get _formattedHeaderDate {
    final now = DateTime.now();
    final isToday = _dateOnly(_logDate).isAtSameMomentAs(_dateOnly(now));
    
    if (isToday) {
      return "Today, ${DateFormat('d MMMM').format(_logDate)}";
    } else {
      return DateFormat('EEEE, d MMMM').format(_logDate); 
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveLog();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDark ? Colors.black : const Color(0xFFF2F2F7); 
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
        // --- LIQUID GLASS X MARK ICON ON THE TOP RIGHT ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: CNButton.icon(
                  icon: const CNSymbol('xmark'), 
                  style: CNButtonStyle.glass,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- BOLD FIXED DATE HEADER ---
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: Text(
              _formattedHeaderDate,
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // --- THE CAROUSEL ---
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                HapticFeedback.selectionClick();
              },
              children: [
                _buildCarouselSlide(
                  title: "FLOW LEVEL",
                  isDark: isDark,
                  options: _flowOptions,
                  isMultiSelect: false,
                  selectedSingle: _flow,
                  onSelect: (val) => setState(() => _flow = val),
                ),
                _buildCarouselSlide(
                  title: "SYMPTOMS",
                  isDark: isDark,
                  options: _symptomOptions,
                  isMultiSelect: true,
                  selectedList: _selectedSymptoms,
                  onSelect: (val) {
                    setState(() {
                      if (_selectedSymptoms.contains(val)) _selectedSymptoms.remove(val);
                      else _selectedSymptoms.add(val);
                    });
                  },
                ),
                _buildCarouselSlide(
                  title: "MOOD",
                  isDark: isDark,
                  options: _moodOptions,
                  isMultiSelect: true,
                  selectedList: _selectedMoods,
                  onSelect: (val) {
                    setState(() {
                      if (_selectedMoods.contains(val)) _selectedMoods.remove(val);
                      else _selectedMoods.add(val);
                    });
                  },
                ),
                _buildCarouselSlide(
                  title: "CERVICAL MUCUS",
                  isDark: isDark,
                  options: _mucusOptions,
                  isMultiSelect: false,
                  selectedSingle: _cervicalMucus,
                  onSelect: (val) => setState(() => _cervicalMucus = (_cervicalMucus == val) ? null : val),
                ),
              ],
            ),
          ),

          // --- BOTTOM NAVIGATION CONTROLS ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- LIQUID GLASS BACK BUTTON (FIXED BOUNCE & SIZE) ---
                AnimatedOpacity(
                  opacity: _currentPage > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _currentPage == 0,
                    child: SizedBox(
                      height: 40, // Larger premium height
                      width: 95, // Wider for perfectly balanced symmetry
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50), // Forces the pill shape mask
                        child: Transform.scale(
                          scale: 1.1, // Hides the native rectangular corners during the bounce
                          child: CNButton(
                            label: "Back",
                            style: CNButtonStyle.glass,
                            onPressed: _prevPage,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // FLAT DASH INDICATORS
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) {
                    bool isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4, 
                      width: 24, 
                      decoration: BoxDecoration(
                        color: isActive 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white24 : Colors.black12), 
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),

                // --- PROMINENT GLASS NEXT/SAVE BUTTON (FIXED BOUNCE & SIZE) ---
                SizedBox(
                  height: 40, // Larger premium height
                  width: 95, // Wider so text never wraps and matches back button symmetrically
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50), // Forces the pill shape mask
                    child: _isSaving 
                      ? Container(
                          decoration: BoxDecoration(
                            color: pinkColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: pinkColor, strokeWidth: 2)
                            ),
                          ),
                        )
                      : Transform.scale(
                          scale: 1.1, // Hides the native rectangular corners during the bounce
                          child: CNButton(
                            label: _currentPage == 3 ? "Save" : "Next", 
                            style: CNButtonStyle.prominentGlass,
                            tint: pinkColor,
                            onPressed: () {
                              if (!_isSaving) _nextPage();
                            },
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM PILL-SHAPED CAROUSEL SLIDE ---
  Widget _buildCarouselSlide({
    required String title,
    required bool isDark,
    required List<String> options,
    required bool isMultiSelect,
    required Function(String) onSelect,
    String? selectedSingle,
    List<String>? selectedList,
  }) {
    final pillBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; 
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: options.length,
            itemBuilder: (context, index) {
              String option = options[index];
              bool isSelected = isMultiSelect 
                  ? (selectedList?.contains(option) ?? false)
                  : (selectedSingle == option);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact(); 
                  onSelect(option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: pillBgColor,
                    borderRadius: BorderRadius.circular(50), 
                    border: Border.all(
                      color: isSelected ? pinkColor : Colors.transparent, 
                      width: 2,
                    ),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: isSelected
                            ? Icon(Icons.check_circle, color: pinkColor, size: 24, key: const ValueKey('checked'))
                            : const SizedBox(width: 24, height: 24, key: ValueKey('unchecked')),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}