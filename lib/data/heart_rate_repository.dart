import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A single intraday heart-rate reading.
typedef HeartReading = ({int bpm, DateTime time});

/// The single owner of heart-rate storage.
///
/// Every read and write of the `heartRate` / `hrHistory` fields on
/// `users/{uid}/dashboardDaily/{yyyy-MM-dd}` goes through here. Because there
/// is exactly one place that *writes* this data, two screens can no longer
/// fight each other (the bug that previously wiped the intraday history when
/// the dashboard and the detail page both wrote the doc).
///
/// Swapping the backing store later (e.g. Firestore -> local DB) means changing
/// only this file; callers never touch Firestore directly.
class HeartRateRepository {
  HeartRateRepository._();
  static final HeartRateRepository instance = HeartRateRepository._();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _dayDoc(String uid, DateTime day) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dashboardDaily')
          .doc(_dateKey(day));

  // ── Writes ────────────────────────────────────────────────────────────────

  /// The ONLY place heart-rate data is written. Updates the latest scalar and
  /// appends to the intraday history with `arrayUnion`, so existing readings
  /// (from this or another device) are never clobbered.
  Future<void> addReading({required DateTime when, required int bpm}) async {
    final uid = _uid;
    if (uid == null) return;
    final key = _dateKey(when);
    await _dayDoc(uid, when).set({
      'heartRate': bpm,
      'hrHistory': FieldValue.arrayUnion([
        {'bpm': bpm, 'time': Timestamp.fromDate(when)},
      ]),
      'dateKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// All readings stored for [day], positive bpm only, sorted by time.
  Future<List<HeartReading>> readingsForDay(DateTime day) async {
    final uid = _uid;
    if (uid == null) return const [];
    final doc = await _dayDoc(uid, day).get();
    return parseReadings(doc.data());
  }

  /// Mon→Sun peak BPM for the current week. Future days stay 0; [seedTodayBpm]
  /// pre-fills today's slot so the live value always shows even before the
  /// stored doc is read.
  Future<List<int>> weeklyMax({required int seedTodayBpm}) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final daysSinceMonday = now.weekday - 1;
    final maxes = List.filled(7, 0);
    maxes[daysSinceMonday] = seedTodayBpm;

    final uid = _uid;
    if (uid == null) return maxes;

    final futures = <Future<void>>[];
    for (int i = 0; i <= daysSinceMonday; i++) {
      final day = monday.add(Duration(days: i));
      final idx = i;
      futures.add(
        _dayDoc(uid, day).get().then((doc) {
          final peak = peakBpm(doc.data());
          if (peak > 0) maxes[idx] = peak;
        }),
      );
    }
    await Future.wait(futures);
    return maxes;
  }

  // ── Pure parsers ────────────────────────────────────────────────────────
  // Single source of truth for the stored shape. Callers that already hold a
  // raw `dashboardDaily` doc (e.g. the dashboard's bulk loader) reuse these so
  // the storage layout lives in exactly one file — without an extra read.

  /// Parse the intraday history out of a raw `dashboardDaily` doc.
  static List<HeartReading> parseReadings(Map<String, dynamic>? data) {
    final raw = data?['hrHistory'] as List<dynamic>?;
    if (raw == null) return const [];
    final out =
        raw.map((e) {
            final bpm = (e['bpm'] as num?)?.toInt() ?? 0;
            final ts = (e['time'] as Timestamp?)?.toDate();
            return (bpm: bpm, time: ts ?? DateTime.now());
          }).where((r) => r.bpm > 0).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Latest scalar BPM stored for a day (0 if none).
  static int parseScalar(Map<String, dynamic>? data) =>
      (data?['heartRate'] as num?)?.toInt() ?? 0;

  /// Peak BPM for a day: the max of the intraday history, falling back to the
  /// stored scalar when there is no history.
  static int peakBpm(Map<String, dynamic>? data) {
    final readings = parseReadings(data);
    if (readings.isNotEmpty) {
      return readings.map((r) => r.bpm).reduce(math.max);
    }
    return parseScalar(data);
  }

  static String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
