import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'cycledeviationmodal.dart';
import 'package:synthese/onboarding/onboarding_cycles.dart';
import 'package:synthese/ui/daily_logging_screen.dart';
import 'cycles_mechanism.dart';
import 'history_cycles.dart';
import 'cycle_energy.dart';
import 'cyclecalendar.dart';
import 'help_cycles.dart'; // <--- ADD THIS IMPORT

class CyclesPage extends StatefulWidget {
  final Function(bool)? onModalStateChanged; 
  const CyclesPage({super.key, this.onModalStateChanged});

  @override
  State<CyclesPage> createState() => _CyclesPageState();
}

class _CyclesPageState extends State<CyclesPage> with CyclesMechanism<CyclesPage> {
  // --- STATE VARIABLE FOR MODAL ANIMATION ---
  bool _isModalOpen = false;

  // --- History Modal Method ---
  void _showHistoryBottomSheet() async {
    HapticFeedback.lightImpact();

    // Fade out buttons before opening
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);
    await Future.delayed(const Duration(milliseconds: 150));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useRootNavigator: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => const HistoryCyclesModal(),
    );

    // Fade buttons back in when closed
    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false); 
    }
  }

  // --- Help Modal Method ---
  // --- Help Page Method ---
  void _showHelpBottomSheet() async {
    HapticFeedback.lightImpact();

    // Fade out buttons before navigating
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);

    // Navigate to the full page instead of opening a bottom sheet.
    // fullscreenDialog: true makes it slide up from the bottom natively on iOS!
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpCyclesPage(), // Uses the new full page name
        fullscreenDialog: true, 
      ),
    );

    // Fade buttons back in when the user returns
    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false); 
    }
  }

  // UI-Specific Dialog for Resetting Data
  Future<void> _handleResetCycleData() async {
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
        title: Text("Reset All Data?", style: TextStyle(color: textColor)),
        content: Text(
          "This will wipe all your daily logs and send you back to the onboarding screen. This cannot be undone.", 
          style: TextStyle(color: mutedText)
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: TextStyle(color: textColor))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Wipe Data", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      )
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFEC548A)))
      );

      await performDataWipe(); 

      if (mounted) {
        Navigator.pop(context); 
        setState(() => simulatedToday = DateTime.now());
      }
    }
  }

  // --- POLISHED DIALOG POPUP ---
  // --- POLISHED DIALOG POPUP ---
  // --- POLISHED DIALOG POPUP (Redesigned to bypass IntrinsicWidth crash) ---
  // --- ARTICLE SLIDE-UP MODAL ---
  void _showLearnMoreArticle(String alertId) async {
    HapticFeedback.lightImpact();

    // Fade out buttons before opening
    setState(() => _isModalOpen = true);
    widget.onModalStateChanged?.call(true);
    await Future.delayed(const Duration(milliseconds: 150));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      useRootNavigator: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => CycleDeviationModal(alertId: alertId), // Calls the new file
    );

    // Fade buttons back in when closed
    if (mounted) {
      setState(() => _isModalOpen = false);
      widget.onModalStateChanged?.call(false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    if (uid == null) {
      return Scaffold(
        backgroundColor: bgColor, 
        body: Center(child: Text("Please log in", style: TextStyle(color: textColor)))
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(
            backgroundColor: bgColor, 
            body: const Center(child: CircularProgressIndicator(color: Color(0xFFEC548A)))
          );
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        if (!(userData['cyclesSetupCompleted'] ?? false)) {
          return OnboardingCycles(onContinue: () {});
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users').doc(uid).collection('cycles')
              .orderBy('startDate', descending: true).limit(6)
              .snapshots(),
          builder: (context, cyclesSnapshot) {
            
            List<Map<String, dynamic>> recentCycles = [];
            if (cyclesSnapshot.hasData) {
              recentCycles = cyclesSnapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
              recentCycles.sort((a, b) => (a['startDate'] as Timestamp).compareTo(b['startDate'] as Timestamp));
            }

            final DateTime lastPeriodStart = (userData['lastPeriodStart'] as Timestamp?)?.toDate() ?? dateOnly(DateTime.now());
            
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(uid)
                  .collection('daily_logs')
                  .where('date', isGreaterThanOrEqualTo: dateOnly(lastPeriodStart))
                  .snapshots(),
              builder: (context, logsSnapshot) {
                
                List<Map<String, dynamic>> currentCycleLogs = [];
                Map<String, dynamic>? todayLogData;
                bool hasLoggedToday = false;

                if (logsSnapshot.hasData) {
                  for (var doc in logsSnapshot.data!.docs) {
                    final log = doc.data() as Map<String, dynamic>;
                    currentCycleLogs.add(log);
                    
                    DateTime logDate = (log['date'] as Timestamp).toDate();
                    if (dateOnly(logDate).isAtSameMomentAs(dateOnly(simulatedToday))) {
                      todayLogData = log;
                      hasLoggedToday = true;
                    }
                  }
                }
                
                return _buildMainDashboard(userData, recentCycles, currentCycleLogs, todayLogData, hasLoggedToday);
              },
            );
          }
        );
      },
    );
  }

  Widget _buildMainDashboard(
    Map<String, dynamic> userData, 
    List<Map<String, dynamic>> recentCycles, 
    List<Map<String, dynamic>> currentCycleLogs, 
    Map<String, dynamic>? logData, 
    bool hasLoggedToday
  ) {
    final data = processDashboardData(userData, recentCycles, currentCycleLogs);

    // --- THEME ADAPTATION ---
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final textColor = isLightMode ? Colors.black : Colors.white;
    final mutedTextColor = isLightMode ? Colors.grey[700]! : Colors.white70;
    final subtitleColor = isLightMode ? Colors.grey[600]! : Colors.grey[400]!;

    final cardBgColor = isLightMode ? const Color(0xFFF4F4F5) : const Color(0xFF151515);
    final insightBgColor = isLightMode ? const Color(0xFFEC548A).withOpacity(0.08) : const Color(0xFF2C1924);
    final iconColor = isLightMode ? Colors.black87 : Colors.white;
    
    // Alert Theming
    final alertBgColor = isLightMode ? const Color(0xFFFFF4E5) : const Color(0xFF2A1F10);
    final alertBorderColor = isLightMode ? const Color(0xFFFFD8A8) : const Color(0xFF4A3215);
    const alertIconColor = Color(0xFFF57C00); // Elegant dark amber
    // ------------------------

    final safePadding = MediaQuery.of(context).padding;
    const Color pinkColor = Color(0xFFEC548A);

    String todayFormatted = DateFormat('EEEE, MMMM d').format(simulatedToday); 
    String nextPeriodFormatted = DateFormat('MMM d').format(data.nextPeriodDate); 
    bool isRealToday = dateOnly(simulatedToday).isAtSameMomentAs(dateOnly(DateTime.now()));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: safePadding.top + 24.0, left: 24.0, right: 24.0, bottom: safePadding.bottom + 140.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Cycles", style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                    
                    AnimatedOpacity(
                      opacity: _isModalOpen ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: IgnorePointer(
                        ignoring: _isModalOpen,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                          ),
                          
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CNButton.icon(
                                icon: const CNSymbol('questionmark.circle', size: 22),
                                style: CNButtonStyle.glass,
                                onPressed: _showHelpBottomSheet,
                              ),
                              const SizedBox(width: 10),
                              CNButton.icon(
                                icon: const CNSymbol('clock.arrow.circlepath', size: 22),
                                style: CNButtonStyle.glass,
                                onPressed: _showHistoryBottomSheet,
                              ),
                              const SizedBox(width: 10),
                              CNButton.icon(
                                icon: const CNSymbol('arrow.clockwise', size: 22),
                                style: CNButtonStyle.glass,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _handleResetCycleData();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Center(
                  child: Column(
                    children: [
                      Text(isRealToday ? "Today" : "Simulated Date", style: TextStyle(color: subtitleColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: iconColor, size: 30),
                            onPressed: () => setState(() => simulatedToday = simulatedToday.subtract(const Duration(days: 1))),
                          ),
                          Text(todayFormatted, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: iconColor, size: 30),
                            onPressed: () => setState(() => simulatedToday = simulatedToday.add(const Duration(days: 1))),
                          ),
                        ],
                      ),
                      if (!isRealToday)
                        GestureDetector(
                          onTap: () => setState(() => simulatedToday = DateTime.now()),
                          child: const Padding(padding: EdgeInsets.only(top: 4.0), child: Text("Reset to Present", style: TextStyle(color: pinkColor, fontSize: 14, fontWeight: FontWeight.w600))),
                        ),
                      const SizedBox(height: 12),
                      Text(data.countdownText, style: const TextStyle(color: pinkColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                CycleEnergyCard(
                  phaseText: data.phaseText,
                  healthScore: data.healthScore.toString(),
                  healthColor: data.healthColor,
                  confidenceBadge: data.confidenceBadge,
                  cycleDayToday: data.cycleDayToday,
                  avgCycleLength: data.avgCycleLength,
                  nextPeriodFormatted: nextPeriodFormatted,
                  loggedCycleDays: data.loggedCycleDays,
                ),

                // --- REDESIGNED DEVIATION ALERTS ---
                if (data.deviationAlerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Column(
                    children: data.deviationAlerts.map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20), 
                        decoration: BoxDecoration(
                          color: alertBgColor, 
                          borderRadius: BorderRadius.circular(24), 
                          border: Border.all(color: alertBorderColor, width: 1.5), 
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: alertIconColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.notifications_active_outlined, color: alertIconColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    alert['title']!, 
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(alert['msg']!, style: TextStyle(color: mutedTextColor, height: 1.5, fontSize: 14)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CNButton(
                                  label: 'Dismiss',
                                  style: CNButtonStyle.plain,
                                  tint: subtitleColor,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    dismissAlert(alert['id']!, data.currentCycleId);
                                  },
                                ),
                                const SizedBox(width: 8),
                                CNButton(
                                  label: 'Learn more',
                                  style: CNButtonStyle.tinted,
                                  tint: alertIconColor,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _showLearnMoreArticle(alert['id']!);
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // --- 2. THE NEW CYCLE CALENDAR WIDGET ---
                const SizedBox(height: 20),
                CycleCalendar(
                  simulatedToday: simulatedToday,
                  lastPeriodStart: (userData['lastPeriodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  avgCycleLength: data.avgCycleLength,
                  avgPeriodLength: userData['periodLength'] ?? 5,
                  recentCycles: recentCycles,
                ),

                if (hasLoggedToday && logData != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(color: cardBgColor, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Log Summary", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        _buildSummaryRow(Icons.water_drop, "Flow", logData['flow'] ?? '', isLightMode),
                        _buildSummaryRow(Icons.opacity, "Mucus", logData['cervicalMucus'] ?? '', isLightMode),
                        _buildSummaryRow(Icons.sick, "Symptoms", (logData['symptoms'] as List<dynamic>?)?.join(' · ') ?? '', isLightMode),
                        _buildSummaryRow(Icons.mood, "Mood", (logData['mood'] as List<dynamic>?)?.join(' · ') ?? '', isLightMode),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: insightBgColor, 
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: pinkColor.withOpacity(isLightMode ? 0.15 : 0.3))
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.auto_awesome, color: pinkColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("What's happening right now?", style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(data.insightText, style: TextStyle(color: mutedTextColor, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          AnimatedOpacity(
            opacity: _isModalOpen ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: _isModalOpen,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  bottom: true, 
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0),
                    child: PremiumButton(
                      text: hasLoggedToday ? "Edit Today's Log" : "Log Symptoms Today",
                      isGlassStyle: hasLoggedToday,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DailyLoggingScreen(selectedDate: simulatedToday)));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String value, bool isLightMode) {
    if (value.isEmpty || value == 'None') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isLightMode ? Colors.grey[500] : Colors.white70),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(title, style: TextStyle(color: isLightMode ? Colors.grey[600] : const Color(0xFF9E9E9E), fontSize: 14, fontWeight: FontWeight.w500))
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: isLightMode ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.3))
          ),
        ],
      ),
    );
  }
}

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isGlassStyle;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isGlassStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color buttonColor = Colors.red;

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: isLoading
            ? Container(
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: buttonColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : CNButton(
                label: text,
                style: isGlassStyle ? CNButtonStyle.glass : CNButtonStyle.prominentGlass, 
                tint: buttonColor,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
              ),
      ),
    );
  }
}