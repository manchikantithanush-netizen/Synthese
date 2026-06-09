import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Permanently removes a guest's cloud footprint when their session ends, so
/// abandoned guest data and anonymous accounts don't pile up in the project.
///
/// This runs on the client while the guest is still signed in (Firestore rules
/// only allow a user to delete their own `users/{uid}` tree). It deletes every
/// per-user subcollection, then the profile doc, then the anonymous auth
/// account itself.
///
/// Limitation: this only fires when the app is open at expiry. A guest who
/// installs, abandons the app and never returns leaves their data behind —
/// covering that case needs a small server-side (Cloud Function) sweep.
///
/// Note: the top-level `ai_reports` collection is intentionally NOT touched —
/// those are issue reports submitted to the developer, not the guest's personal
/// data.
class GuestAccountService {
  GuestAccountService._();
  static final GuestAccountService instance = GuestAccountService._();

  /// Per-user subcollections nested under `users/{uid}`. Keep this in sync with
  /// the Firestore data model — anything missing here is orphaned on cleanup.
  /// `finance_debts` is handled separately because it has its own nested
  /// `payments` subcollection.
  static const List<String> _subcollections = [
    'dashboardDaily',
    'dailyAgg',
    'daily_logs',
    'cycles',
    'foodLogs',
    'waterDaily',
    'mood_logs',
    'morning_readiness',
    'workout_sessions',
    'financeMonthly',
    'finance_accounts',
    'finance_categories',
    'finance_transactions',
    'accounts',
  ];

  /// Wipe the current anonymous guest's data and delete the account. No-ops for
  /// signed-out or non-anonymous users. Best-effort: never throws, and always
  /// leaves the user signed out so the app routes back to the start page.
  Future<void> purge() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      for (final name in _subcollections) {
        await _deleteCollection(userDoc.collection(name));
      }
      await _deleteDebtsWithPayments(userDoc.collection('finance_debts'));
      await userDoc.delete();
    } catch (e) {
      debugPrint('GuestAccountService.purge: data delete failed: $e');
    }

    // Deleting the user also signs them out. Fall back to an explicit sign-out
    // if the account deletion fails for any reason, so we never strand a guest
    // in a half-expired state.
    try {
      await user.delete();
    } catch (e) {
      debugPrint('GuestAccountService.purge: account delete failed: $e');
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  /// `finance_debts/{debtId}/payments` is nested, so delete each debt's
  /// payments before the debt doc itself.
  Future<void> _deleteDebtsWithPayments(
    CollectionReference<Map<String, dynamic>> debts,
  ) async {
    final snap = await debts.get();
    for (final debt in snap.docs) {
      await _deleteCollection(debt.reference.collection('payments'));
      await debt.reference.delete();
    }
  }

  /// Delete every doc in [col], batched to stay under Firestore's 500-op limit.
  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await col.get();
    if (snap.docs.isEmpty) return;
    const chunk = 400;
    for (var i = 0; i < snap.docs.length; i += chunk) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs.skip(i).take(chunk)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
