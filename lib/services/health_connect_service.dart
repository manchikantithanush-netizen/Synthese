import 'dart:async';
import 'dart:io';

import 'package:health/health.dart';

enum HealthConnectStatus {
  ready,
  notSupported,
  notInstalled,
  permissionDenied,
  error,
}

class HealthConnectFetchResult {
  HealthConnectFetchResult({
    required this.status,
    this.points = const <HealthDataPoint>[],
    this.error,
  });

  final HealthConnectStatus status;
  final List<HealthDataPoint> points;
  final Object? error;

  bool get ok => status == HealthConnectStatus.ready;

  Iterable<HealthDataPoint> whereType(HealthDataType type) =>
      points.where((p) => p.type == type);
}

/// Thin wrapper around the `health` package for Google Health Connect.
///
/// - No UI, only permission + data fetching logic.
/// - Call `initializeAndEnsureReadPermissions()` once during app startup.
/// - Call `fetchPast7Days()` from anywhere afterwards.
class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const List<HealthDataType> _requiredTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataAccess> _requiredReadAccess = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<HealthConnectStatus> initializeAndEnsureReadPermissions() async {
    if (!Platform.isAndroid) {
      return HealthConnectStatus.notSupported;
    }

    try {
      await _health.configure();

      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        return HealthConnectStatus.notInstalled;
      }

      final hasPerms = await _health.hasPermissions(
        _requiredTypes,
        permissions: _requiredReadAccess,
      );

      if (hasPerms == true) {
        return HealthConnectStatus.ready;
      }

      final granted = await _health.requestAuthorization(
        _requiredTypes,
        permissions: _requiredReadAccess,
      );

      return granted ? HealthConnectStatus.ready : HealthConnectStatus.permissionDenied;
    } catch (_) {
      return HealthConnectStatus.error;
    }
  }

  Future<HealthConnectFetchResult> fetchPast7Days() async {
    if (!Platform.isAndroid) {
      return HealthConnectFetchResult(status: HealthConnectStatus.notSupported);
    }

    try {
      await _health.configure();

      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        return HealthConnectFetchResult(status: HealthConnectStatus.notInstalled);
      }

      final hasPerms = await _health.hasPermissions(
        _requiredTypes,
        permissions: _requiredReadAccess,
      );
      if (hasPerms != true) {
        return HealthConnectFetchResult(status: HealthConnectStatus.permissionDenied);
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      final requiredPoints = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _requiredTypes,
      );

      final deduped = _health.removeDuplicates(requiredPoints);
      return HealthConnectFetchResult(
        status: HealthConnectStatus.ready,
        points: List<HealthDataPoint>.unmodifiable(deduped),
      );
    } catch (e) {
      return HealthConnectFetchResult(
        status: HealthConnectStatus.error,
        error: e,
      );
    }
  }
}

