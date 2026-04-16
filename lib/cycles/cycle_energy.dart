import 'package:flutter/material.dart';

class CycleEnergyCard extends StatelessWidget {
  final String phaseText;
  final String healthScore;
  final Color healthColor;
  final String? confidenceBadge;
  final int cycleDayToday;
  final int avgCycleLength;
  final String nextPeriodFormatted;
  final List<int> loggedCycleDays;

  const CycleEnergyCard({
    super.key,
    required this.phaseText,
    required this.healthScore,
    required this.healthColor,
    this.confidenceBadge,
    required this.cycleDayToday,
    required this.avgCycleLength,
    required this.nextPeriodFormatted,
    this.loggedCycleDays = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 380;
    // --- THEME & STATE ADAPTATION ---
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isPeriod = phaseText == "Your period is here";

    final textColor = isLightMode ? Colors.black : Colors.white;
    final mutedTextColor = isLightMode ? Colors.grey[700]! : Colors.white70;
    final subtitleColor = isLightMode ? Colors.grey[600]! : Colors.grey[400]!;

    // NEW: Dynamic Background & Border Colors based on Period State
    final cardBgColor = isPeriod
        ? (isLightMode
              ? const Color(0xFFFDECEE)
              : const Color(0xFF2A1516)) // Soft red tint
        : (isLightMode
              ? const Color(0xFFF4F4F5)
              : const Color(0xFF151515)); // Default grey/black

    final borderColor = isPeriod
        ? const Color(0xFFEF5350) // Full red border
        : Colors.transparent; // Invisible otherwise

    final innerCardBg = isLightMode ? Colors.white : const Color(0xFF222222);
    final progressBarBg = isLightMode ? Colors.grey[300]! : Colors.black;
    const Color pinkColor = Color(0xFFEC548A);
    // --------------------------------

    // --- DYNAMIC ICONS & HORMONE DATA ---
    IconData thumbIcon = Icons.circle;
    Color thumbIconColor = Colors.grey;
    String exactPhase = "";
    String hormoneLabel = "";

    if (isPeriod) {
      thumbIcon = Icons.water_drop;
      thumbIconColor = const Color(0xFFEF5350); // Red
      exactPhase = "Period";
      hormoneLabel = "Estrogen & progesterone dropping";
    } else if (phaseText == "Your egg is growing") {
      thumbIcon = Icons.spa;
      thumbIconColor = const Color(0xFF66BB6A); // Green
      exactPhase = "Follicular";
      hormoneLabel = "Estrogen rising";
    } else if (phaseText == "Ovulation today") {
      thumbIcon = Icons.flare;
      thumbIconColor = const Color(0xFFFFA726); // Orange
      exactPhase = "Ovulation";
      hormoneLabel = "LH surge · Estrogen peak";
    } else if (phaseText == "Body is waiting") {
      thumbIcon = Icons.hourglass_bottom;
      thumbIconColor = const Color(0xFFAB47BC); // Purple
      exactPhase = "Luteal";
      hormoneLabel = "Progesterone dominant";
    } else {
      thumbIcon = Icons.watch_later;
      thumbIconColor = const Color(0xFF5C6BC0); // Indigo
      exactPhase = "Period due soon";
      hormoneLabel = "Progesterone dropping";
    }
    // ------------------------------------

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(28),
        // NEW: Dynamic red border applied here
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  phaseText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isNarrow ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: isNarrow ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Health Score: $healthScore",
                  style: TextStyle(
                    color: healthColor,
                    fontSize: isNarrow ? 11 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (confidenceBadge != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                confidenceBadge!,
                style: TextStyle(
                  color: mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // --- SCIENTIFIC PHASE & HORMONE LABEL ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: thumbIconColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: thumbIconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(thumbIcon, size: 18, color: thumbIconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exactPhase,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hormoneLabel,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------------
          const SizedBox(height: 28),

          Text(
            "Current Cycle Day",
            style: TextStyle(
              color: subtitleColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$cycleDayToday",
                style: TextStyle(
                  color: textColor,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              Text(
                " / $avgCycleLength",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              double progressRatio = (cycleDayToday / avgCycleLength);
              progressRatio = progressRatio.clamp(0.0, 1.0);
              final double activeWidth = maxWidth * progressRatio;

              return SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      width: maxWidth,
                      height: 50,
                      decoration: BoxDecoration(
                        color: progressBarBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Container(
                      width: activeWidth,
                      height: 50,
                      decoration: BoxDecoration(
                        color: pinkColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          bottomLeft: const Radius.circular(16),
                          topRight: Radius.circular(
                            progressRatio >= 1.0 ? 16 : 0,
                          ),
                          bottomRight: Radius.circular(
                            progressRatio >= 1.0 ? 16 : 0,
                          ),
                        ),
                      ),
                    ),

                    for (int day in loggedCycleDays)
                      if (day > 0 && day <= avgCycleLength)
                        Positioned(
                          left:
                              ((day / avgCycleLength) * maxWidth).clamp(
                                8.0,
                                maxWidth - 8.0,
                              ) -
                              1.5,
                          child: Container(
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: day <= cycleDayToday
                                  ? Colors.white.withOpacity(0.55)
                                  : (isLightMode
                                        ? Colors.black12
                                        : Colors.white24),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                    Positioned(
                      left: (activeWidth - 17).clamp(0.0, maxWidth - 34.0),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          // Outline of thumb adapts to the tinted background perfectly
                          border: Border.all(color: cardBgColor, width: 4),
                        ),
                        child: Center(
                          child: Icon(
                            thumbIcon,
                            size: 16,
                            color: thumbIconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: pinkColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Next: $nextPeriodFormatted",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
