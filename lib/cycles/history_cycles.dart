import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class HistoryCyclesModal extends StatefulWidget {
  const HistoryCyclesModal({super.key});

  @override
  State<HistoryCyclesModal> createState() => _HistoryCyclesModalState();
}

class _HistoryCyclesModalState extends State<HistoryCyclesModal> {
  String? _selectedCycleId;
  final Map<String, GlobalKey> _itemKeys = {};

  // Cache the stream so it doesn't reconnect on every tap
  Stream<QuerySnapshot>? _cyclesStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _cyclesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cycles')
          .snapshots();
    }
  }

  void _scrollToItem(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[id];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.3, // Centers the expanded card slightly higher on screen
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        padding: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            // --- HEADER ---
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Cycle History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: UniversalCloseButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- MAIN CONTENT ---
            Expanded(
              child: _cyclesStream == null
                  ? const Center(child: Text("Please log in to view history."))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _cyclesStream,
                      builder: (context, snapshot) {
                        // Only show loading if we have absolutely no data yet
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: BouncingDotsLoader(color: Color(0xFFEC548A)),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // EMPTY STATE
                        if (docs.isEmpty) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _buildSummaryStatsBar(
                                  isDark: isDark,
                                  avgCycle: 0,
                                  avgPeriod: 0,
                                  maxCycle: 0,
                                  minCycle: 0,
                                ),
                                const SizedBox(height: 24),
                                _buildChart(
                                  isDark: isDark,
                                  recentCycles: [],
                                  avgCycle: 0,
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  "No cycles logged yet.",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // --- DATA PROCESSING ---
                        List<Map<String, dynamic>> allCycles = docs.map((d) {
                          return {
                            'id': d.id,
                            ...d.data() as Map<String, dynamic>,
                          };
                        }).toList();

                        allCycles.sort((a, b) {
                          Timestamp tA =
                              a['startDate'] as Timestamp? ?? Timestamp.now();
                          Timestamp tB =
                              b['startDate'] as Timestamp? ?? Timestamp.now();
                          return tB.compareTo(tA);
                        });

                        int totalCycle = 0,
                            totalPeriod = 0,
                            maxCycle = 0,
                            minCycle = 999,
                            validCycles = 0;

                        for (var c in allCycles) {
                          String cId = c['id'];
                          // Ensure keys are created before building
                          _itemKeys.putIfAbsent(cId, () => GlobalKey());

                          int cLen = c['cycleLength'] as int? ?? 0;
                          int pLen = c['periodLength'] as int? ?? 0;
                          if (cLen > 0) {
                            totalCycle += cLen;
                            validCycles++;
                            if (cLen > maxCycle) maxCycle = cLen;
                            if (cLen < minCycle) minCycle = cLen;
                          }
                          if (pLen > 0) totalPeriod += pLen;
                        }

                        int avgCycle = validCycles > 0
                            ? (totalCycle / validCycles).round()
                            : 0;
                        int avgPeriod = validCycles > 0
                            ? (totalPeriod / validCycles).round()
                            : 0;
                        if (minCycle == 999) minCycle = 0;

                        List<Map<String, dynamic>> recent6 = allCycles
                            .take(6)
                            .toList()
                            .reversed
                            .toList();

                        // Select the most recent cycle by default on first load
                        if (_selectedCycleId == null && recent6.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              setState(
                                () => _selectedCycleId = allCycles.first['id'],
                              );
                          });
                        }

                        // ENTIRE PAGE IS SCROLLABLE
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildSummaryStatsBar(
                                isDark: isDark,
                                avgCycle: avgCycle,
                                avgPeriod: avgPeriod,
                                maxCycle: maxCycle,
                                minCycle: minCycle,
                              ),
                              const SizedBox(height: 24),
                              _buildChart(
                                isDark: isDark,
                                recentCycles: recent6,
                                avgCycle: avgCycle,
                              ),
                              const SizedBox(height: 24),
                              _buildHistoryList(
                                isDark: isDark,
                                cycles: allCycles,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. SUMMARY STATS BAR ---
  Widget _buildSummaryStatsBar({
    required bool isDark,
    required int avgCycle,
    required int avgPeriod,
    required int maxCycle,
    required int minCycle,
  }) {
    final cardColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatColumn(
              "Avg Cycle",
              "$avgCycle",
              "d",
              textColor,
              subTextColor,
            ),
          ),
          Expanded(
            child: _buildStatColumn(
              "Avg Period",
              "$avgPeriod",
              "d",
              textColor,
              subTextColor,
            ),
          ),
          Expanded(
            child: _buildStatColumn(
              "Longest",
              "$maxCycle",
              "d",
              textColor,
              subTextColor,
            ),
          ),
          Expanded(
            child: _buildStatColumn(
              "Shortest",
              "$minCycle",
              "d",
              textColor,
              subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    String unit,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. INTERACTIVE CHART ---
  Widget _buildChart({
    required bool isDark,
    required List<Map<String, dynamic>> recentCycles,
    required int avgCycle,
  }) {
    final cardColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    const pinkColor = Color(0xFFEC548A);

    int localMax = recentCycles.isEmpty
        ? 30
        : recentCycles.map((c) => c['cycleLength'] as int? ?? 0).reduce(max);
    double maxScale = max(localMax.toDouble(), 35.0);

    const double chartHeight = 120.0;
    double avgRatio = (avgCycle / maxScale).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Cycles",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Average ($avgCycle d)",
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: chartHeight + 40,
            child: Stack(
              children: [
                Positioned(
                  bottom: 20 + (chartHeight * avgRatio),
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: recentCycles.map((c) {
                    int cLen = c['cycleLength'] as int? ?? 0;
                    double barHeight = (cLen / maxScale) * chartHeight;
                    bool isSelected = c['id'] == _selectedCycleId;

                    Timestamp? ts = c['startDate'] as Timestamp?;
                    String monthStr = ts != null
                        ? DateFormat('MMM').format(ts.toDate())
                        : '-';

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (_selectedCycleId != c['id']) {
                          setState(() => _selectedCycleId = c['id']);
                        }
                        // Always scroll to the card when tapping the chart
                        _scrollToItem(c['id']);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "$cLen",
                            style: TextStyle(
                              color: isSelected ? pinkColor : subTextColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? pinkColor
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthStr,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. DETAILED HISTORY LIST (EXPANDABLE) ---
  Widget _buildHistoryList({
    required bool isDark,
    required List<Map<String, dynamic>> cycles,
  }) {
    final cardColor = isDark ? const Color(0xFF151515) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    const pinkColor = Color(0xFFEC548A);

    return Column(
      children: cycles.map((c) {
        final String cycleId = c['id'];
        final bool isSelected = cycleId == _selectedCycleId;

        final Timestamp? ts = c['startDate'] as Timestamp?;
        final String dateStr = ts != null
            ? DateFormat('MMMM d, yyyy').format(ts.toDate())
            : 'Unknown Date';

        final int cLen = c['cycleLength'] as int? ?? 0;
        final int pLen = c['periodLength'] as int? ?? 0;

        // Determine cycle status for colored dot
        Color statusColor;
        String statusText;
        if (cLen < 21) {
          statusColor = const Color(0xFFFF9500); // iOS Orange
          statusText = "Short Cycle";
        } else if (cLen > 35) {
          statusColor = const Color(0xFFAF52DE); // iOS Purple
          statusText = "Long Cycle";
        } else {
          statusColor = const Color(0xFF34C759); // iOS Green
          statusText = "Normal Cycle";
        }

        // Pull symptoms (Assumes DB saves them as a list under "symptoms")
        List<dynamic> rawSymptoms = c['symptoms'] is List ? c['symptoms'] : [];
        String symText = rawSymptoms.isNotEmpty
            ? rawSymptoms
                  .take(3)
                  .join(', ') // Takes top 3 symptoms
            : "No symptoms logged";

        return Container(
          key: _itemKeys[cycleId],
          margin: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? pinkColor.withOpacity(0.05) : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? pinkColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Top Header Section (Always Visible)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (_selectedCycleId == cycleId) {
                      // Tap to close if already open
                      setState(() => _selectedCycleId = null);
                    } else {
                      // Tap to open
                      setState(() => _selectedCycleId = cycleId);
                      _scrollToItem(cycleId);
                    }
                  },
                  title: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: isSelected ? pinkColor : textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(
                      top: 6.0,
                      left: 20.0,
                    ), // Aligns with text, ignoring dot
                    child: Text(
                      "Cycle: $cLen days  •  Period: $pLen days",
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ),
                  trailing: Icon(
                    isSelected
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: isSelected
                        ? pinkColor
                        : subTextColor.withOpacity(0.5),
                    size: 18,
                  ),
                ),

                // Expanded Details Section
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                                height: 1,
                              ),
                              const SizedBox(height: 16),

                              // Extended Cycle Info
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.calendar,
                                    size: 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "$statusText ($cLen days)",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Extended Period Info
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.drop_fill,
                                    size: 16,
                                    color: Color(0xFFEC548A),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "$pLen day period",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Top Symptoms
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    CupertinoIcons.heart_circle_fill,
                                    size: 16,
                                    color: subTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Top Symptoms: $symText",
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- CUSTOM PAINTER FOR DASHED LINE ---
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
