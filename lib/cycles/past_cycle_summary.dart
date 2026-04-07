// File: lib/past_cycle_summary.dart

class PastCycleSummary {
  final int cycleLength;
  final int bleedingDays;
  final bool hadHeavyBleeding;
  final int spottingDays; 
  final bool loggedLevel3Data;
  final bool ovulationDetected;

  PastCycleSummary({
    required this.cycleLength,
    required this.bleedingDays,
    required this.hadHeavyBleeding,
    required this.spottingDays,
    required this.loggedLevel3Data,
    required this.ovulationDetected,
  });
}