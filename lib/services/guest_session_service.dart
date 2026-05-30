import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the local lifetime of a guest (anonymous) session.
///
/// Guest data lives only on this device and is never synced or backed up, so
/// the session anchor is stored locally in [SharedPreferences] to match. The
/// session is limited to [sessionDuration]; once it elapses the user is signed
/// out (handled by the dashboard, which checks [isExpired] on launch/resume).
///
/// Singleton, following the app's service convention.
class GuestSessionService {
  GuestSessionService._();
  static final GuestSessionService instance = GuestSessionService._();

  /// How long a guest account stays signed in before it is signed out.
  static const Duration sessionDuration = Duration(days: 3);

  static const String _kCreatedAt = 'guest_session_created_at_millis';

  /// Start (or restart) a fresh guest session anchored at now. Call this right
  /// after a successful anonymous sign-in.
  Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCreatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Ensure a session anchor exists — used for guests created before this
  /// feature existed. Does nothing if one is already set.
  Future<void> ensureSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kCreatedAt)) {
      await prefs.setInt(_kCreatedAt, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// The moment the current guest session expires, or null if none exists.
  Future<DateTime?> expiry() async {
    final prefs = await SharedPreferences.getInstance();
    final created = prefs.getInt(_kCreatedAt);
    if (created == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(created).add(sessionDuration);
  }

  /// Remaining time before sign-out, or null if no session anchor. May be
  /// negative/zero once expired.
  Future<Duration?> timeLeft() async {
    final exp = await expiry();
    if (exp == null) return null;
    return exp.difference(DateTime.now());
  }

  /// Whether the current guest session has elapsed.
  Future<bool> isExpired() async {
    final left = await timeLeft();
    if (left == null) return false;
    return left.isNegative || left == Duration.zero;
  }

  /// Clear the session anchor (on sign-out / expiry).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCreatedAt);
  }
}
