import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of a single Play Age Signals check, as handed to us by Google Play.
class AgeSignal {
  /// Stable status string mirrored from the native layer. One of:
  /// VERIFIED, DECLARED, SUPERVISED, SUPERVISED_APPROVAL_PENDING,
  /// SUPERVISED_APPROVAL_DENIED, UNKNOWN, NONE, UNAVAILABLE.
  final String status;

  /// Lower bound of the user's age band (e.g. 18 for the "18+" band). Nullable.
  final int? ageLower;

  /// Upper bound of the user's age band (e.g. 17 for the "16-17" band).
  /// Null for the open-ended "18+" band.
  final int? ageUpper;

  /// Play-generated id for supervised installs. Not used for any tracking.
  final String? installId;

  const AgeSignal({
    required this.status,
    this.ageLower,
    this.ageUpper,
    this.installId,
  });

  factory AgeSignal.unavailable() => const AgeSignal(status: 'UNAVAILABLE');

  /// Whether Google Play has told us the user is definitively a minor, so an
  /// adults-only app must restrict access.
  ///
  /// We only block when we are *sure*:
  ///  - the user's age band tops out below 18, OR
  ///  - a supervised account's parent explicitly denied approval.
  ///
  /// Everything else (18+ band, unknown age, no signal, API unavailable,
  /// pending approval) is allowed. This "fail open" stance is deliberate: the
  /// Play Store already prevents under-18 users from installing an 18+ app, so
  /// a transient API hiccup must never lock out a legitimate adult.
  bool get isMinor {
    if (status == 'SUPERVISED_APPROVAL_DENIED') return true;
    final upper = ageUpper;
    if (upper != null && upper < 18) return true;
    return false;
  }
}

/// Thin wrapper around the native Play Age Signals bridge (see MainActivity.kt).
///
/// Google Play performs the actual age verification and parental-consent flow.
/// This service only reads the resulting signal so the app can comply with
/// age-verification laws such as Texas SB 2420. The signal must never be used
/// for advertising, analytics, tracking or profiling.
class AgeSignalsService {
  AgeSignalsService._();
  static final AgeSignalsService instance = AgeSignalsService._();

  static const MethodChannel _channel =
      MethodChannel('com.thanush.synthesehealth/age_signals');

  /// Cached for the lifetime of the process — the signal does not change
  /// within a session, and we don't want to re-query Play repeatedly.
  AgeSignal? _cached;

  /// Fetches the age signal for the current user. Always resolves (never
  /// throws); on non-Android platforms or any error it returns `UNAVAILABLE`.
  Future<AgeSignal> check() async {
    if (_cached != null) return _cached!;

    // The native bridge only exists on Android.
    if (kIsWeb || !Platform.isAndroid) {
      return _cached = AgeSignal.unavailable();
    }

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'checkAgeSignals',
      );
      if (raw == null) return _cached = AgeSignal.unavailable();
      return _cached = AgeSignal(
        status: (raw['status'] as String?) ?? 'UNAVAILABLE',
        ageLower: (raw['ageLower'] as num?)?.toInt(),
        ageUpper: (raw['ageUpper'] as num?)?.toInt(),
        installId: raw['installId'] as String?,
      );
    } catch (e) {
      debugPrint('AgeSignalsService.check failed: $e');
      return _cached = AgeSignal.unavailable();
    }
  }
}
