import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enforces a single active session per account.
///
/// On each explicit login a new random session id is stored locally and written
/// to `users/{uid}.activeSessionId`. Every device watches that field; when it
/// changes (because the account logged in on another device) the now-stale
/// device signs itself out.
///
/// This is a purely client-side scheme — no Cloud Functions / Admin SDK — so it
/// runs on the free plan. A superseded device is signed out as soon as it's
/// online to receive the change (or on its next launch if it was offline).
class SessionGuardService {
  SessionGuardService._();
  static final SessionGuardService instance = SessionGuardService._();

  static const String _kSessionId = 'active_session_id';
  static const String _kSessionUid = 'active_session_uid';
  static const String _kSuperseded = 'session_superseded';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _watchingUid;

  /// While set, this device has just claimed a session but hasn't yet seen its
  /// own write reflected in the snapshot. Until it does, we ignore mismatches so
  /// the device never signs *itself* out during its own login.
  String? _pendingClaimId;

  /// Claim this device as the single active session for [uid]. Call right after
  /// a successful sign-in / sign-up.
  Future<void> claimSession(String uid) async {
    final sessionId = _generateId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionId, sessionId);
    await prefs.setString(_kSessionUid, uid);
    await prefs.remove(_kSuperseded);
    _pendingClaimId = sessionId;

    // Fire-and-forget: never block login while offline. The write syncs when
    // connectivity returns, at which point other devices get signed out.
    unawaited(
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'activeSessionId': sessionId,
        'activeSessionAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((Object e) {
        debugPrint('SessionGuard claim write failed: $e');
      }),
    );

    await attach(uid);
  }

  /// Start watching [uid]'s session field. Safe to call repeatedly. Enforcement
  /// only kicks in for devices that have actually claimed a session for [uid] —
  /// accounts logged in before this feature shipped stay passive until their
  /// next explicit login.
  Future<void> attach(String uid) async {
    if (_watchingUid == uid && _sub != null) return;
    await detach();
    _watchingUid = uid;
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snap) => _onSnapshot(uid, snap),
          onError: (Object e) => debugPrint('SessionGuard listen error: $e'),
        );
  }

  Future<void> _onSnapshot(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    final remoteId = snap.data()?['activeSessionId'] as String?;
    if (remoteId == null) return; // no enforcement for this account yet

    // Wait until our own claim has propagated before enforcing, so we don't
    // sign ourselves out against the previous device's id mid-login.
    if (_pendingClaimId != null) {
      if (remoteId == _pendingClaimId) _pendingClaimId = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localUid = prefs.getString(_kSessionUid);
    final localId = prefs.getString(_kSessionId);
    // Only enforce if THIS device claimed a session for THIS user.
    if (localUid != uid || localId == null) return;

    if (remoteId != localId) {
      // Superseded by a login on another device.
      await prefs.setBool(_kSuperseded, true);
      await prefs.remove(_kSessionId);
      await detach();
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('SessionGuard signOut failed: $e');
      }
    }
  }

  /// Stop watching. Called on sign-out.
  Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
    _watchingUid = null;
  }

  /// Whether the last sign-out was caused by another device logging in. Reads
  /// and clears the flag so the message is shown only once.
  Future<bool> consumeSupersededFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_kSuperseded) ?? false;
    if (v) await prefs.remove(_kSuperseded);
    return v;
  }

  String _generateId() {
    final rand = Random();
    final a = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final b = rand.nextInt(1 << 32).toRadixString(16);
    final c = rand.nextInt(1 << 32).toRadixString(16);
    return '$a-$b-$c';
  }
}
