import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';

enum CyclePhase { period, follicular, ovulation, luteal, periodDueSoon }
enum CycleInsight { late_, periodSoon, period, follicular, ovulation, luteal }
enum CycleConfidence { high, medium, low }

/// A data class to smoothly pass all processed data over to the UI file
class CycleDashboardData {
  final int avgCycleLength;
  final int cycleDayToday;
  final DateTime nextPeriodDate;
  final int daysUntilNextPeriod;
  final String currentCycleId;
  final List<Map<String, String>> deviationAlerts;
  final CyclePhase phaseId;
  final CycleInsight insightId;
  final String phaseText;
  final String countdownText;
  final String insightText;
  final int healthScore;
  final Color healthColor;
  final CycleConfidence? confidenceLevel;
  final String? confidenceBadge;
  final List<int> loggedCycleDays;

  CycleDashboardData({
    required this.avgCycleLength,
    required this.cycleDayToday,
    required this.nextPeriodDate,
    required this.daysUntilNextPeriod,
    required this.currentCycleId,
    required this.deviationAlerts,
    required this.phaseId,
    required this.insightId,
    required this.phaseText,
    required this.countdownText,
    required this.insightText,
    required this.healthScore,
    required this.healthColor,
    this.confidenceLevel,
    this.confidenceBadge,
    required this.loggedCycleDays,
  });
}

/// The logic mechanism that powers CyclesPage without cluttering the UI
mixin CyclesMechanism<T extends StatefulWidget> on State<T> {
  DateTime simulatedToday = DateTime.now();

  DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  // --- FIRESTORE BATCH OVERFLOW & BUG 4 FIX ---
  Future<void> performDataWipe() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final logsSnap = await userRef.collection('daily_logs').get();
    final cyclesSnap = await userRef.collection('cycles').get();

    final allDocs = [...logsSnap.docs, ...cyclesSnap.docs];

    const int chunkSize = 400;
    for (int i = 0; i < allDocs.length; i += chunkSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = allDocs.sublist(i, min(i + chunkSize, allDocs.length));
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await userRef.update({
      'cyclesSetupCompleted': false,
      'loggedCyclesCount': 0, 
      'pastCycles': FieldValue.delete(), 
      'dismissedAlerts': FieldValue.delete(), 
      'lastPeriodStart': FieldValue.delete(),
    });
  }

  double calculateStdDev(List<int> values) {
    if (values.length < 2) return 0.0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  int calculateHealthScore(List<Map<String, dynamic>> recentCycles) {
    if (recentCycles.isEmpty) return 100;
    int score = 100;

    for (var c in recentCycles) {
      int cLen = c['cycleLength'] ?? 28;
      
      if (cLen < 21 || cLen > 35) score -= 10;
      if ((c['spottingDays'] ?? 0) > 2) score -= 5;
      if ((c['veryHeavyDays'] ?? 0) >= 5) score -= 10;
    }

    final lengths = recentCycles.map((c) => c['cycleLength'] as int).toList();
    double stdDev = calculateStdDev(lengths);

    if (stdDev > 5) score -= 15;
    else if (stdDev > 3) score -= 5;

    return score.clamp(0, 100);
  }

  Future<void> dismissAlert(String alertId, String currentCycleId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'dismissedAlerts': { alertId: currentCycleId }
    }, SetOptions(merge: true));
  }

  List<Map<String, String>> getDeviationAlerts(AppLocalizations t, Map<String, dynamic> userData, int daysUntilNextPeriod, List<Map<String, dynamic>> recentCycles, String currentCycleId) {
    List<Map<String, String>> alerts = [];

    bool isDismissed(String alertId) {
      final dismissedAlerts = userData['dismissedAlerts'] as Map<String, dynamic>? ?? {};
      return dismissedAlerts[alertId] == currentCycleId;
    }

    if (daysUntilNextPeriod < -90 && !isDismissed('missing_90')) {
      alerts.add({
        'id': 'missing_90',
        'title': t.cycleAlertMissing90Title,
        'msg': t.cycleAlertMissing90Msg,
      });
    } else if (daysUntilNextPeriod < -14 && !isDismissed('late_14')) {
      alerts.add({
        'id': 'late_14',
        'title': t.cycleAlertLate14Title,
        'msg': t.cycleAlertLate14Msg,
      });
    } else if (daysUntilNextPeriod < -7 && daysUntilNextPeriod >= -14 && !isDismissed('late_7')) {
      alerts.add({
        'id': 'late_7',
        'title': t.cycleAlertLate7Title,
        'msg': t.cycleAlertLate7Msg,
      });
    }

    if (recentCycles.length >= 6) {
      final lengths = recentCycles.map((c) => c['cycleLength'] as int).toList();
      double stdDev = calculateStdDev(lengths);
      if (stdDev > 4.5 && !isDismissed('irregular')) {
        alerts.add({
          'id': 'irregular',
          'title': t.cycleAlertIrregularTitle,
          'msg': t.cycleAlertIrregularMsg,
        });
      }
    }

    if (recentCycles.length >= 3) {
      final last3 = recentCycles.sublist(recentCycles.length - 3);
      bool allShort = last3.every((c) => (c['cycleLength'] as int) < 21);
      bool allLong = last3.every((c) => (c['cycleLength'] as int) > 35);

      if (allShort && !isDismissed('short_cycle')) {
        alerts.add({
          'id': 'short_cycle',
          'title': t.cycleAlertShortCycleTitle,
          'msg': t.cycleAlertShortCycleMsg,
        });
      }
      if (allLong && !isDismissed('long_cycle')) {
        alerts.add({
          'id': 'long_cycle',
          'title': t.cycleAlertLongCycleTitle,
          'msg': t.cycleAlertLongCycleMsg,
        });
      }
    }

    if (recentCycles.length >= 2 && !isDismissed('long_period')) {
      final last2 = recentCycles.sublist(recentCycles.length - 2);
      bool bothLongPeriods = last2.every((c) => (c['periodLength'] as int) > 8);
      if (bothLongPeriods) {
        alerts.add({
          'id': 'long_period',
          'title': t.cycleAlertLongPeriodTitle,
          'msg': t.cycleAlertLongPeriodMsg,
        });
      }
    }

    if (recentCycles.isNotEmpty) {
      final lastCycle = recentCycles.last;
      if ((lastCycle['veryHeavyDays'] ?? 0) >= 5 && !isDismissed('heavy_bleeding')) {
         alerts.add({
          'id': 'heavy_bleeding',
          'title': t.cycleAlertHeavyBleedingTitle,
          'msg': t.cycleAlertHeavyBleedingMsg,
         });
      }
    }

    return alerts;
  }

  /// Processes all strings, colors, and math logic to keep it out of the UI
  CycleDashboardData processDashboardData(
    AppLocalizations t,
    Map<String, dynamic> userData,
    List<Map<String, dynamic>> recentCycles,
    List<Map<String, dynamic>> currentCycleLogs
  ) {
    final DateTime lastPeriodStart = (userData['lastPeriodStart'] as Timestamp?)?.toDate() ?? simulatedToday;
    final int loggedCyclesCount = userData['loggedCyclesCount'] ?? 0;

    int avgCycleLength = userData['cycleLength'] ?? 28;
    int avgPeriodLength = userData['periodLength'] ?? 5;

    if (recentCycles.isNotEmpty) {
      avgCycleLength = (recentCycles.map((c) => c['cycleLength'] as int).reduce((a, b) => a + b) / recentCycles.length).round();
      avgPeriodLength = (recentCycles.map((c) => c['periodLength'] as int).reduce((a, b) => a + b) / recentCycles.length).round();
    }

    int estimatedOvulationDay = avgCycleLength - 14;
    DateTime nextPeriodDate = dateOnly(lastPeriodStart).add(Duration(days: avgCycleLength));

    int cycleDayToday = dateOnly(simulatedToday).difference(dateOnly(lastPeriodStart)).inDays + 1;
    final int daysUntilNextPeriod = dateOnly(nextPeriodDate).difference(dateOnly(simulatedToday)).inDays;

    cycleDayToday = min(cycleDayToday, avgCycleLength * 2);

    final String currentCycleId = (userData['lastPeriodStart'] as Timestamp?)?.toDate().toIso8601String() ?? 'unknown';
    final List<Map<String, String>> deviationAlerts = getDeviationAlerts(t, userData, daysUntilNextPeriod, recentCycles, currentCycleId);

    List<int> loggedCycleDays = [];
    for (var log in currentCycleLogs) {
      String flow = log['flow'] ?? 'None';

      bool isPeriodFlow = ['Spotting', 'Light', 'Medium', 'Heavy', 'Very Heavy'].contains(flow);

      if (!isPeriodFlow) {
        DateTime logDate = (log['date'] as Timestamp).toDate();
        int loggedDay = dateOnly(logDate).difference(dateOnly(lastPeriodStart)).inDays + 1;
        if (loggedDay > 0) {
          loggedCycleDays.add(loggedDay);
        }
      }
    }

    CyclePhase phaseId;
    String phaseText;
    String countdownText;

    if (cycleDayToday >= 1 && cycleDayToday <= avgPeriodLength) {
      phaseId = CyclePhase.period;
      phaseText = t.cyclePhaseTextPeriod;
    } else if (cycleDayToday > avgPeriodLength && cycleDayToday < estimatedOvulationDay) {
      phaseId = CyclePhase.follicular;
      phaseText = t.cyclePhaseTextFollicular;
    } else if (cycleDayToday == estimatedOvulationDay) {
      phaseId = CyclePhase.ovulation;
      phaseText = t.cyclePhaseTextOvulation;
    } else if (cycleDayToday > estimatedOvulationDay && cycleDayToday <= avgCycleLength) {
      phaseId = CyclePhase.luteal;
      phaseText = t.cyclePhaseTextLuteal;
    } else {
      phaseId = CyclePhase.periodDueSoon;
      phaseText = t.cyclePhaseTextPeriodDueSoon;
    }

    if (daysUntilNextPeriod > 0) {
      countdownText = t.cycleCountdownInDays(daysUntilNextPeriod);
    } else if (daysUntilNextPeriod == 0) {
      countdownText = t.cycleCountdownDueToday;
    } else {
      countdownText = t.cycleCountdownDaysLate(daysUntilNextPeriod.abs());
    }

    CycleInsight insightId;
    String insightText;
    if (daysUntilNextPeriod < 0) {
      insightId = CycleInsight.late_;
      insightText = t.cycleInsightLate;
    } else if (daysUntilNextPeriod <= 2 && cycleDayToday > estimatedOvulationDay) {
      insightId = CycleInsight.periodSoon;
      insightText = t.cycleInsightPeriodSoon;
    } else if (cycleDayToday <= avgPeriodLength) {
      insightId = CycleInsight.period;
      insightText = t.cycleInsightPeriod;
    } else if (cycleDayToday < estimatedOvulationDay) {
      insightId = CycleInsight.follicular;
      insightText = t.cycleInsightFollicular;
    } else if (cycleDayToday == estimatedOvulationDay) {
      insightId = CycleInsight.ovulation;
      insightText = t.cycleInsightOvulation;
    } else {
      insightId = CycleInsight.luteal;
      insightText = t.cycleInsightLuteal;
    }

    int healthScore = calculateHealthScore(recentCycles);
    Color healthColor = healthScore > 80 ? Colors.greenAccent : (healthScore > 50 ? Colors.orangeAccent : Colors.redAccent);

    CycleConfidence confidenceLevel;
    String? confidenceBadge;
    double stdDev = recentCycles.isEmpty ? 0 : calculateStdDev(recentCycles.map((c) => c['cycleLength'] as int).toList());

    if (loggedCyclesCount >= 6 && stdDev <= 4.5) {
      confidenceLevel = CycleConfidence.high;
      confidenceBadge = t.cycleConfidenceHigh;
    } else if (loggedCyclesCount >= 3 && stdDev <= 6.0) {
      confidenceLevel = CycleConfidence.medium;
      confidenceBadge = t.cycleConfidenceMedium;
    } else {
      confidenceLevel = CycleConfidence.low;
      confidenceBadge = t.cycleConfidenceLow;
    }

    return CycleDashboardData(
      avgCycleLength: avgCycleLength,
      cycleDayToday: cycleDayToday,
      nextPeriodDate: nextPeriodDate,
      daysUntilNextPeriod: daysUntilNextPeriod,
      currentCycleId: currentCycleId,
      deviationAlerts: deviationAlerts,
      phaseId: phaseId,
      insightId: insightId,
      phaseText: phaseText,
      countdownText: countdownText,
      insightText: insightText,
      healthScore: healthScore,
      healthColor: healthColor,
      confidenceLevel: confidenceLevel,
      confidenceBadge: confidenceBadge,
      loggedCycleDays: loggedCycleDays,
    );
  }
}