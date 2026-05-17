import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReviewService — Google Play In-App Reviews trigger.
//
// The Play API doesn't expose whether the user actually submitted a review
// (privacy by design), so we use a count + cadence policy:
//   • First eligible goal completion → show.
//   • Then wait 30 days before showing again.
//   • Stop after 3 lifetime prompts (Play also enforces its own quota).
// ─────────────────────────────────────────────────────────────────────────────
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const String _kShownCount = 'review_shown_count';
  static const String _kLastShownAt = 'review_last_shown_at';
  static const int _maxPrompts = 3;
  static const Duration _cadence = Duration(days: 30);

  final InAppReview _api = InAppReview.instance;
  bool _requestInFlight = false;

  Future<void> maybeRequestAfterGoal() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownCount = prefs.getInt(_kShownCount) ?? 0;
      if (shownCount >= _maxPrompts) return;

      final lastShownRaw = prefs.getString(_kLastShownAt);
      if (lastShownRaw != null) {
        final last = DateTime.tryParse(lastShownRaw);
        if (last != null && DateTime.now().difference(last) < _cadence) {
          return;
        }
      }

      final available = await _api.isAvailable();
      if (!available) return;

      await _api.requestReview();

      await prefs.setInt(_kShownCount, shownCount + 1);
      await prefs.setString(_kLastShownAt, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[ReviewService] $e');
    } finally {
      _requestInFlight = false;
    }
  }
}
