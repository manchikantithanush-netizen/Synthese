import 'package:cloud_firestore/cloud_firestore.dart';

class DataAggregationService {
  DataAggregationService._();

  static DateTime _dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static Future<void> markMoodLogged({
    required String uid,
    required DateTime when,
  }) async {
    await _upsertDailyAgg(
      uid: uid,
      when: when,
      mergeData: <String, dynamic>{
        'moodLogged': true,
      },
    );
  }

  static Future<void> markReadinessLogged({
    required String uid,
    required DateTime when,
  }) async {
    await _upsertDailyAgg(
      uid: uid,
      when: when,
      mergeData: <String, dynamic>{
        'readinessLogged': true,
      },
    );
  }

  static Future<void> updateDietCalories({
    required String uid,
    required DateTime when,
    required int deltaCalories,
  }) async {
    await _upsertDailyAgg(
      uid: uid,
      when: when,
      mergeData: <String, dynamic>{
        'caloriesLogged': FieldValue.increment(deltaCalories),
        'mealLogged': true,
      },
    );
  }

  static Future<void> setWaterGlasses({
    required String uid,
    required DateTime when,
    required int glasses,
  }) async {
    await _upsertDailyAgg(
      uid: uid,
      when: when,
      mergeData: <String, dynamic>{
        'waterGlasses': glasses,
      },
    );
  }

  static Future<void> updateDashboardSnapshot({
    required String uid,
    required DateTime when,
    required int steps,
    required int activeCalories,
  }) async {
    await _upsertDailyAgg(
      uid: uid,
      when: when,
      mergeData: <String, dynamic>{
        'dashboardUpdated': true,
        'dashboardSteps': steps,
        'dashboardActiveCalories': activeCalories,
      },
    );
  }

  static Future<void> updateFinanceMonthlyExpense({
    required String uid,
    required DateTime when,
    required double amountDelta,
  }) async {
    final monthKey = _monthKey(when);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('financeMonthly')
        .doc(monthKey);
    await ref.set({
      'monthKey': monthKey,
      'expenseTotal': FieldValue.increment(amountDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _upsertDailyAgg({
    required String uid,
    required DateTime when,
    required Map<String, dynamic> mergeData,
  }) async {
    final day = _dayStart(when);
    final key = _dateKey(day);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyAgg')
        .doc(key);
    await ref.set({
      'dateKey': key,
      'date': Timestamp.fromDate(day),
      ...mergeData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
