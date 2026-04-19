import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel('synthese/home_widget');

  static Future<void> updateDashboardMetrics({
    required int steps,
    required int heartRate,
    required int activeCalories,
    required int exerciseMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'updateDashboardMetrics',
        <String, dynamic>{
          'steps': steps,
          'heartRate': heartRate,
          'activeCalories': activeCalories,
          'exerciseMinutes': exerciseMinutes,
        },
      );
    } catch (e) {
      debugPrint('Home widget dashboard sync failed: $e');
    }
  }

  static Future<void> updateWorkoutSummary({
    required String mode,
    required String distance,
    required String duration,
    required int calories,
    required String paceLabel,
    required String paceValue,
    required List<Map<String, double>> routePoints,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'updateWorkoutSummary',
        <String, dynamic>{
          'mode': mode,
          'distance': distance,
          'duration': duration,
          'calories': calories,
          'paceLabel': paceLabel,
          'paceValue': paceValue,
          'routePoints': routePoints,
        },
      );
    } catch (e) {
      debugPrint('Home widget workout sync failed: $e');
    }
  }

  static Future<void> updateSteps(
    int steps, {
    int heartRate = 0,
    int activeCalories = 0,
    int exerciseMinutes = 0,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateSteps', <String, dynamic>{
        'steps': steps,
        'heartRate': heartRate,
        'activeCalories': activeCalories,
        'exerciseMinutes': exerciseMinutes,
      });
    } catch (e) {
      debugPrint('Home widget update failed: $e');
    }
  }
}
