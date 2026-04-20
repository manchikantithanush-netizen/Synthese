import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:synthese/services/app_notifications_service.dart';

class NotificationRulesEngine {
  NotificationRulesEngine._();

  static bool _running = false;

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<void> evaluateGlobal() async {
    if (_running) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _running = true;
    try {
      await AppNotificationsService.instance.init();
      final now = DateTime.now();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data() ?? const <String, dynamic>{};

      await Future.wait([
        _evaluateDiet(userRef: userRef, uid: uid, userData: userData, now: now),
        _evaluateMindfulness(
          userRef: userRef,
          uid: uid,
          userData: userData,
          now: now,
        ),
        _evaluateCycles(userRef: userRef, userData: userData, now: now),
        _evaluateFinance(userRef: userRef, uid: uid, userData: userData, now: now),
        _evaluateDashboard(userRef: userRef, now: now),
      ]);
    } catch (error) {
      debugNotification('Rules engine failed: $error');
    } finally {
      _running = false;
    }
  }

  static Future<void> _evaluateDiet({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    final todayStart = _dayStart(now);
    final todayKey = _dateKey(now);
    final dailyCalorieGoal =
        (userData['dailyCalorieGoal'] as num?)?.toInt() ?? 2000;
    final waterGoal = (userData['dailyWaterGoalGlasses'] as num?)?.toInt() ?? 8;

    final foodSnap = await userRef
        .collection('foodLogs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .get();
    final todayCalories = foodSnap.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc.data()['calories'] as num?)?.toInt() ?? 0),
    );
    final hasMealToday = foodSnap.docs.isNotEmpty;

    if (!hasMealToday && now.hour >= 20) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_meal_logging_$todayKey',
        title: 'Log today\'s meals',
        body: 'Keep your nutrition streak alive by logging at least one meal.',
        now: now,
      );
    }

    final waterDoc = await userRef.collection('waterDaily').doc(todayKey).get();
    final waterGlasses = (waterDoc.data()?['glasses'] as num?)?.toInt() ?? 0;
    if (waterGlasses < waterGoal && now.hour >= 12 && now.hour <= 21) {
      await AppNotificationsService.instance.showWithCooldown(
        uniqueKey: 'diet_water_behind',
        title: 'Hydration check',
        body:
            'You are at $waterGlasses/$waterGoal glasses today. Drink a glass now.',
        cooldown: const Duration(hours: 4),
        now: now,
      );
    }

    final eightyPercent = (dailyCalorieGoal * 0.8).round();
    if (todayCalories >= eightyPercent &&
        todayCalories < dailyCalorieGoal &&
        now.hour >= 12) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_goal_nudge_$todayKey',
        title: 'You\'re close to your calorie goal',
        body:
            'You\'ve logged $todayCalories/$dailyCalorieGoal kcal. Finish strong.',
        now: now,
      );
    }

    var streak = 0;
    for (var i = 0; i < 14; i++) {
      final day = now.subtract(Duration(days: i));
      final dayStart = _dayStart(day);
      final snap = await userRef
          .collection('foodLogs')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
          )
          .where(
            'timestamp',
            isLessThan: Timestamp.fromDate(dayStart.add(const Duration(days: 1))),
          )
          .get();
      final cal = snap.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['calories'] as num?)?.toInt() ?? 0),
      );
      if (cal >= dailyCalorieGoal) {
        streak += 1;
      } else {
        break;
      }
    }
    if (streak > 0 && streak % 3 == 0) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'diet_streak_$streak\_$todayKey',
        title: 'Nutrition streak: $streak days',
        body: 'You have hit your calorie goal for $streak days in a row.',
        now: now,
      );
    }
  }

  static Future<void> _evaluateMindfulness({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    final todayKey = _dateKey(now);
    final moodDoc = await userRef.collection('mood_logs').doc(todayKey).get();
    if (!moodDoc.exists && now.hour >= 19) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_mood_check_$todayKey',
        title: 'Mood check-in',
        body: 'Take 10 seconds to log your mood today.',
        now: now,
      );
    }

    final readinessDoc =
        await userRef.collection('morning_readiness').doc(todayKey).get();
    if (!readinessDoc.exists && now.hour >= 10 && now.hour <= 14) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_readiness_$todayKey',
        title: 'Morning readiness',
        body: 'Log sleep, energy and stress to tune your day better.',
        now: now,
      );
    }

    // Small evening breathing nudge if both entries are missing.
    if (!moodDoc.exists && !readinessDoc.exists && now.hour >= 21) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'mindfulness_breathe_$todayKey',
        title: 'Take a short breathing break',
        body: 'A 2-minute breathing session can help close your day calmly.',
        now: now,
      );
    }

    // Access userData to avoid analyzer warning for future rule extensions.
    if (userData.isEmpty || uid.isEmpty) return;
  }

  static Future<void> _evaluateCycles({
    required DocumentReference<Map<String, dynamic>> userRef,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    final setupDone = (userData['cyclesSetupCompleted'] as bool?) ?? false;
    if (!setupDone) return;

    final lastStartTs = userData['lastPeriodStart'] as Timestamp?;
    if (lastStartTs == null) return;
    final cycleLength = (userData['cycleLength'] as num?)?.toInt() ?? 28;
    final periodLength = (userData['periodLength'] as num?)?.toInt() ?? 5;
    final lastPeriodStart = _dayStart(lastStartTs.toDate());
    final nextPeriod = lastPeriodStart.add(Duration(days: cycleLength));
    final daysUntilNext = _dayStart(nextPeriod).difference(_dayStart(now)).inDays;
    final cycleDay = _dayStart(now).difference(lastPeriodStart).inDays + 1;
    final ovulationDay = math.max(1, cycleLength - 14);

    final todayKey = _dateKey(now);
    final logDoc = await userRef.collection('daily_logs').doc(todayKey).get();
    if (!logDoc.exists && now.hour >= 20) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_daily_log_$todayKey',
        title: 'Cycle log reminder',
        body: 'Log today\'s flow/symptoms to keep cycle predictions accurate.',
        now: now,
      );
    }

    if (daysUntilNext == 2) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_period_soon_$todayKey',
        title: 'Period likely in ~2 days',
        body: 'Keep products handy and track symptoms today.',
        now: now,
      );
    } else if (daysUntilNext == 0) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_due_today_$todayKey',
        title: 'Period due today',
        body: 'Your cycle suggests today may be day 1 of your period.',
        now: now,
      );
    } else if (daysUntilNext <= -7 && daysUntilNext > -14) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_7_$todayKey',
        title: 'Period is 7+ days late',
        body: 'Stress and routine changes can delay periods. Keep tracking.',
        now: now,
      );
    } else if (daysUntilNext <= -14 && daysUntilNext > -90) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_14_$todayKey',
        title: 'Period is 14+ days late',
        body: 'If this is unusual for you, consider checking with a doctor.',
        now: now,
      );
    } else if (daysUntilNext <= -90) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_late_90_$todayKey',
        title: 'Period over 3 months late',
        body: 'Please consult a healthcare provider as soon as possible.',
        now: now,
      );
    }

    if (cycleDay == ovulationDay - 2) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_ovulation_window_$todayKey',
        title: 'Fertile window likely starting',
        body: 'You may be entering your ovulation window.',
        now: now,
      );
    }
    if (cycleDay == ovulationDay) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'cycles_ovulation_peak_$todayKey',
        title: 'Ovulation likely today',
        body: 'Your cycle indicates ovulation is likely around today.',
        now: now,
      );
    }

    final recentCycles = (userData['pastCycles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (recentCycles.length >= 3) {
      final last3 = recentCycles.sublist(recentCycles.length - 3);
      final allShort = last3.every((c) => ((c['cycleLength'] as num?) ?? 28) < 21);
      final allLong = last3.every((c) => ((c['cycleLength'] as num?) ?? 28) > 35);
      if (allShort) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_short_cycle_$todayKey',
          title: 'Pattern: short cycles',
          body: 'Your last 3 cycles were unusually short. Keep monitoring.',
          now: now,
        );
      }
      if (allLong) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_long_cycle_$todayKey',
          title: 'Pattern: long cycles',
          body: 'Your last 3 cycles were unusually long. Track closely.',
          now: now,
        );
      }
    }
    if (recentCycles.length >= 2) {
      final last2 = recentCycles.sublist(recentCycles.length - 2);
      final longPeriods = last2.every(
        (c) => ((c['periodLength'] as num?) ?? periodLength) > 8,
      );
      if (longPeriods) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_long_period_$todayKey',
          title: 'Long periods detected',
          body: 'Your period length has been above 8 days recently.',
          now: now,
        );
      }
    }
    if (recentCycles.isNotEmpty) {
      final last = recentCycles.last;
      final veryHeavyDays = ((last['veryHeavyDays'] as num?) ?? 0).toInt();
      if (veryHeavyDays >= 5) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'cycles_heavy_bleeding_$todayKey',
          title: 'Heavy bleeding trend',
          body: 'Your last cycle had 5+ very heavy flow days.',
          now: now,
        );
      }
    }
  }

  static Future<void> _evaluateFinance({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String uid,
    required Map<String, dynamic> userData,
    required DateTime now,
  }) async {
    final financeDebtsRef = userRef.collection('finance_debts');
    final debtsSnap = await financeDebtsRef.get();
    final todayKey = _dateKey(now);
    final todayStart = _dayStart(now);

    for (final debtDoc in debtsSnap.docs) {
      final debt = debtDoc.data();
      final isPaid = (debt['isPaid'] as bool?) ?? false;
      final title = (debt['title'] as String?)?.trim().isNotEmpty == true
          ? debt['title'] as String
          : 'Debt';

      if (isPaid) {
        final paidKey = 'finance_debt_paid_${debtDoc.id}';
        final alreadyMarked = await AppNotificationsService.instance.hasMarked(
          paidKey,
        );
        if (!alreadyMarked) {
          await AppNotificationsService.instance.show(
            uniqueKey: paidKey,
            title: 'Debt cleared',
            body: '$title has been marked as fully paid. Great progress!',
          );
          await AppNotificationsService.instance.markOnce(uniqueKey: paidKey);
        }
        continue;
      }

      final dueTs = debt['dueDate'] as Timestamp?;
      if (dueTs != null) {
        final dueDate = _dayStart(dueTs.toDate());
        final daysUntilDue = dueDate.difference(todayStart).inDays;
        if (daysUntilDue == 7 ||
            daysUntilDue == 3 ||
            daysUntilDue == 1 ||
            daysUntilDue == 0) {
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_debt_due_${debtDoc.id}_$todayKey',
            title: 'Debt reminder: $title',
            body: daysUntilDue == 0
                ? 'This payment is due today.'
                : 'Payment due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}.',
            now: now,
          );
        } else if (daysUntilDue < 0) {
          final overdueDays = daysUntilDue.abs();
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_debt_overdue_${debtDoc.id}_$todayKey',
            title: 'Payment overdue',
            body: '$title is overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}.',
            now: now,
          );
        }
      }

      final isRecurring = (debt['isRecurring'] as bool?) ?? false;
      if (isRecurring && dueTs != null) {
        final dueDate = _dayStart(dueTs.toDate());
        final daysUntilDue = dueDate.difference(todayStart).inDays;
        if (daysUntilDue <= 2 && daysUntilDue >= 0) {
          await AppNotificationsService.instance.showOncePerDay(
            uniqueKey: 'finance_installment_${debtDoc.id}_$todayKey',
            title: 'Installment reminder',
            body: '$title installment is coming up soon.',
            now: now,
          );
        }
      }
    }

    final accountsSnap = await userRef.collection('finance_accounts').get();
    final lowBalanceThreshold =
        (userData['financeLowBalanceThreshold'] as num?)?.toDouble() ?? 100.0;
    for (final accountDoc in accountsSnap.docs) {
      final name = (accountDoc.data()['name'] as String?) ?? 'Account';
      final balance =
          (accountDoc.data()['balance'] as num?)?.toDouble() ?? 0.0;
      if (balance <= lowBalanceThreshold) {
        await AppNotificationsService.instance.showOncePerDay(
          uniqueKey: 'finance_low_balance_${accountDoc.id}_$todayKey',
          title: 'Low balance alert',
          body:
              '$name is at ${balance.toStringAsFixed(2)}. Consider topping up soon.',
          now: now,
        );
      }
    }

    final txSnap = await userRef
        .collection('finance_transactions')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .orderBy('date', descending: true)
        .get();

    final largeExpenseThreshold =
        (userData['financeLargeExpenseThreshold'] as num?)?.toDouble() ?? 500.0;
    final monthlyBudget =
        (userData['financeMonthlyBudget'] as num?)?.toDouble() ?? 2000.0;
    var monthExpense = 0.0;

    for (final txDoc in txSnap.docs) {
      final tx = txDoc.data();
      final type = (tx['type'] as String?) ?? 'expense';
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
      final date = (tx['date'] as Timestamp?)?.toDate() ?? now;
      if (date.month == now.month && date.year == now.year && type == 'expense') {
        monthExpense += amount;
      }

      if (type == 'expense' && amount >= largeExpenseThreshold) {
        final key = 'finance_large_expense_${txDoc.id}';
        final already = await AppNotificationsService.instance.hasMarked(key);
        if (!already) {
          await AppNotificationsService.instance.show(
            uniqueKey: key,
            title: 'Large expense detected',
            body: 'A large spend of ${amount.toStringAsFixed(2)} was recorded.',
          );
          await AppNotificationsService.instance.markOnce(uniqueKey: key);
        }
      }
    }

    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final expectedSpendByNow = monthlyBudget * (now.day / daysInMonth);
    if (monthExpense > expectedSpendByNow * 1.2 && now.day >= 10) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'finance_budget_pacing_$todayKey',
        title: 'Budget pacing alert',
        body:
            'You are spending faster than this month\'s pace (${monthExpense.toStringAsFixed(0)} used).',
        now: now,
      );
    }

    if (uid.isEmpty) return;
  }

  static Future<void> _evaluateDashboard({
    required DocumentReference<Map<String, dynamic>> userRef,
    required DateTime now,
  }) async {
    final todayKey = _dateKey(now);
    final doc = await userRef.collection('dashboardDaily').doc(todayKey).get();
    final hasUploadedOnce = (doc.data()?['hasUploadedOnce'] as bool?) ?? false;
    final steps = (doc.data()?['steps'] as num?)?.toInt() ?? 0;
    final activeCalories = (doc.data()?['activeCalories'] as num?)?.toInt() ?? 0;

    if ((!hasUploadedOnce || (steps == 0 && activeCalories == 0)) && now.hour >= 19) {
      await AppNotificationsService.instance.showOncePerDay(
        uniqueKey: 'dashboard_daily_health_reminder_$todayKey',
        title: 'Daily health score reminder',
        body: 'No health update yet today. Log activity to refresh your score.',
        now: now,
      );
    }
  }
}
