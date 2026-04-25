import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:synthese/ui/components/bouncing_dots_loader.dart';
import 'package:synthese/ui/components/app_toast.dart';
import 'package:synthese/services/app_notifications_service.dart';
import 'package:synthese/services/home_widget_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

LatLngBounds _boundsForRoutePoints(List<LatLng> points) {
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;
  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }
  if (minLat == maxLat && minLng == maxLng) {
    const pad = 0.002;
    return LatLngBounds(
      southwest: LatLng(minLat - pad, minLng - pad),
      northeast: LatLng(maxLat + pad, maxLng + pad),
    );
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

enum WorkoutMode {
  running,
  trailRun,
  outdoorWalking,
  cycling,
  mountainBikeRide,
  eBikeRide,
  swimming,
}

WorkoutMode? _workoutModeFromName(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  for (final v in WorkoutMode.values) {
    if (v.name == raw) {
      return v;
    }
  }
  return null;
}

String formatWorkoutDistance(WorkoutMode? mode, double meters) {
  switch (mode) {
    case WorkoutMode.swimming:
      if (meters < 1) {
        return '0 m';
      }
      if (meters < 1000) {
        return '${meters.round()} m';
      }
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    case WorkoutMode.running:
    case WorkoutMode.trailRun:
    case WorkoutMode.outdoorWalking:
    case WorkoutMode.cycling:
    case WorkoutMode.mountainBikeRide:
    case WorkoutMode.eBikeRide:
    case null:
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
  }
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
    this.onMetricsChanged,
    this.onTrackingBaselineCleared,
    this.onWorkoutModeChanged,
  });

  final void Function(int calories, int activeMinutes)? onMetricsChanged;

  /// Called after the user clears the route/session so the dashboard can reset
  /// its workout delta baseline without changing today's cumulative calories.
  final VoidCallback? onTrackingBaselineCleared;
  final ValueChanged<bool>? onWorkoutModeChanged;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  static const LatLng _defaultStart = LatLng(25.2048, 55.2708);
  static const int _trackingNotificationId = 4501;
  static const String _trackingChannelId = 'workout_tracking_channel';
  static const String _trackingChannelName = 'Workout tracking';
  static const String _trackingChannelDescription =
      'Shows active workout stats while tracking.';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  WorkoutMode? _selectedMode;
  GoogleMapController? _workoutMapController;
  LatLng? _pendingMapCameraTarget;
  double? _pendingMapCameraZoom;
  bool _programmaticCameraMove = false;
  double _mapCameraZoom = 17;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _previewPositionSubscription;
  Timer? _durationTicker;
  Timer? _countdownTimer;
  Timer? _positionFallbackTimer;

  bool _isTracking = false;
  bool _isManuallyPaused = false;
  bool _showMetricsFullscreen = false;
  bool _hideTrackingUi = false;
  bool _isPreparingLocation = false;
  bool _isCountdownActive = false;
  int _countdownValue = 3;
  String? _statusMessage;
  DateTime? _trackingStartAt;
  Duration _elapsedBeforeCurrentRun = Duration.zero;
  double _totalDistanceMeters = 0;
  double _userWeightKg = 60;
  int _lastReportedCalories = -1;
  int _lastReportedActiveMinutes = -1;
  DateTime? _sessionStartedAt;
  bool _isWeatherLoading = false;
  String? _weatherError;
  String? _weatherCondition;
  String? _weatherLocationLabel;
  double? _weatherTempC;
  double? _weatherFeelsLikeC;
  int? _weatherHumidity;
  double? _weatherWindKph;
  // Use dotenv for runtime API key loading
  static String get _weatherApiKey => const String.fromEnvironment('WEATHER_API_KEY', defaultValue: '') != ''
      ? const String.fromEnvironment('WEATHER_API_KEY', defaultValue: '')
      : (const bool.hasEnvironment('FLUTTER_TEST') ? '' : (dotenv.env['WEATHER_API_KEY'] ?? ''));

  int _lastDistanceMilestoneKm = 0;
  int _lastDurationMilestoneMinutes = 0;
  bool _goalReachedNotified = false;

  final List<LatLng> _routePoints = <LatLng>[];
  LatLng? _currentPosition;

  /// When true, GPS updates recenter the map. User pan/zoom sets this false until
  /// they use the recenter control or reset the workout.
  bool _mapFollowsUserLocation = true;

  Duration get _elapsed {
    if (_trackingStartAt == null) {
      return _elapsedBeforeCurrentRun;
    }
    return _elapsedBeforeCurrentRun +
        DateTime.now().difference(_trackingStartAt!);
  }

  bool get _isPaused => _isManuallyPaused;
  bool get _isLocationReady =>
      _currentPosition != null && !_isPreparingLocation;
  bool get _canResetRoute =>
      (_routePoints.isNotEmpty || _isTracking) && (!_isTracking || _isPaused);

  double get _currentMetValue {
    switch (_selectedMode) {
      case WorkoutMode.running:
        return 8.0;
      case WorkoutMode.trailRun:
        return 9.0;
      case WorkoutMode.cycling:
        return 7.5;
      case WorkoutMode.mountainBikeRide:
        return 8.5;
      case WorkoutMode.eBikeRide:
        return 4.5;
      case WorkoutMode.swimming:
        return 7.0;
      case WorkoutMode.outdoorWalking:
      case null:
        return 3.5;
    }
  }

  int get _activeMinutes => _elapsed.inMinutes;

  bool get _caloriesFromElapsedOnly =>
      _selectedMode == WorkoutMode.swimming;

  int get _estimatedCalories {
    final hours = _elapsed.inSeconds / 3600.0;
    if (!hours.isFinite || hours <= 0) {
      return 0;
    }
    if (_caloriesFromElapsedOnly) {
      return (_currentMetValue * _userWeightKg * hours).round();
    }
    if (_routePoints.length < 2 || _totalDistanceMeters < 1) {
      return 0;
    }
    return (_currentMetValue * _userWeightKg * hours).round();
  }

  double? get _avgSpeedKmPerHour {
    if (_totalDistanceMeters <= 0) {
      return null;
    }
    final totalHours = _elapsed.inSeconds / 3600.0;
    if (!totalHours.isFinite || totalHours <= 0) {
      return null;
    }
    final distanceKm = _totalDistanceMeters / 1000.0;
    final speedKmPerHour = distanceKm / totalHours;
    if (!speedKmPerHour.isFinite || speedKmPerHour <= 0) {
      return null;
    }
    return speedKmPerHour;
  }

  String get _paceOrSpeedLabel {
    switch (_selectedMode) {
      case WorkoutMode.swimming:
      case WorkoutMode.trailRun:
        return 'Pace';
      case WorkoutMode.running:
      case WorkoutMode.cycling:
      case WorkoutMode.mountainBikeRide:
      case WorkoutMode.eBikeRide:
      case WorkoutMode.outdoorWalking:
      case null:
        return 'Speed';
    }
  }

  String get _paceOrSpeedValueText {
    switch (_selectedMode) {
      case WorkoutMode.swimming:
        return _formatSwimPacePer100m();
      case WorkoutMode.trailRun:
        return _formatRunPaceMinPerKm(_avgSpeedKmPerHour);
      case WorkoutMode.running:
      case WorkoutMode.cycling:
      case WorkoutMode.mountainBikeRide:
      case WorkoutMode.eBikeRide:
      case WorkoutMode.outdoorWalking:
      case null:
        final kmh = _avgSpeedKmPerHour;
        if (kmh == null) {
          return '-- km/h';
        }
        return '${kmh.toStringAsFixed(2)} km/h';
    }
  }

  String _formatRunPaceMinPerKm(double? kmh) {
    if (kmh == null || kmh <= 0) {
      return '-- min/km';
    }
    final minPerKm = 60.0 / kmh;
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round().clamp(0, 59);
    return '$m:${s.toString().padLeft(2, '0')} min/km';
  }

  String _formatSwimPacePer100m() {
    if (_totalDistanceMeters < 50) {
      return '-- /100m';
    }
    final totalSec = _elapsed.inMilliseconds / 1000.0;
    if (totalSec <= 0) {
      return '-- /100m';
    }
    final hundreds = _totalDistanceMeters / 100.0;
    if (hundreds <= 0) {
      return '-- /100m';
    }
    final secPer100 = totalSec / hundreds;
    final whole = secPer100.floor();
    final ss = (whole % 60).toString().padLeft(2, '0');
    final mm = (whole ~/ 60).toString();
    return '$mm:$ss /100m';
  }

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  void _forgetWorkoutMapController() {
    _workoutMapController = null;
    _pendingMapCameraTarget = null;
    _pendingMapCameraZoom = null;
  }

  @override
  void dispose() {
    _workoutMapController?.dispose();
    _workoutMapController = null;
    _durationTicker?.cancel();
    _positionSubscription?.cancel();
    _previewPositionSubscription?.cancel();
    _countdownTimer?.cancel();
    _positionFallbackTimer?.cancel();
    if (_isTracking) {
      unawaited(_cancelTrackingNotification());
    }
    super.dispose();
  }

  Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized || !Platform.isAndroid) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notificationsPlugin.initialize(settings);

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _trackingChannelId,
        _trackingChannelName,
        description: _trackingChannelDescription,
        importance: Importance.low,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
    _notificationsInitialized = true;
  }

  Future<void> _updateTrackingNotification() async {
    if (!_isTracking || !Platform.isAndroid) {
      return;
    }
    await _ensureNotificationsInitialized();

    final notificationTitle =
        '${_modeLabel(_selectedMode ?? WorkoutMode.outdoorWalking)} in progress';
    final notificationBody =
        '${formatWorkoutDistance(_selectedMode, _totalDistanceMeters)} | ${_formatDuration(_elapsed)} | $_estimatedCalories kcal | $_paceOrSpeedValueText';

    await _notificationsPlugin.show(
      _trackingNotificationId,
      notificationTitle,
      notificationBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _trackingChannelId,
          _trackingChannelName,
          channelDescription: _trackingChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showWhen: false,
          category: AndroidNotificationCategory.workout,
        ),
      ),
    );
  }

  Future<void> _cancelTrackingNotification() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _notificationsPlugin.cancel(_trackingNotificationId);
  }

  Future<void> _loadUserWeight() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      final rawWeight = data?['weight'];
      final parsedWeight = double.tryParse(rawWeight?.toString() ?? '');

      if (!mounted || parsedWeight == null || parsedWeight <= 0) {
        return;
      }
      setState(() {
        _userWeightKg = parsedWeight;
      });
    } catch (error) {
      debugPrint('Failed to load user weight: $error');
    }
  }

  Future<void> _loadWorkoutWeather() async {
    final point = _currentPosition;
    if (point == null || !mounted) {
      return;
    }

    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });

    try {
      final uri = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$_weatherApiKey&q=${point.latitude},${point.longitude}&aqi=no',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Weather API returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      final current = data['current'] as Map<String, dynamic>?;
      final condition = current?['condition'] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _weatherCondition = condition?['text']?.toString();
        _weatherLocationLabel = [
          location?['name']?.toString(),
          location?['region']?.toString(),
          location?['country']?.toString(),
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
        _weatherTempC = (current?['temp_c'] as num?)?.toDouble();
        _weatherFeelsLikeC = (current?['feelslike_c'] as num?)?.toDouble();
        _weatherHumidity = (current?['humidity'] as num?)?.toInt();
        _weatherWindKph = (current?['wind_kph'] as num?)?.toDouble();
        _isWeatherLoading = false;
      });
      await _maybeNotifyWeatherAdvisory();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWeatherLoading = false;
        _weatherError = 'Unable to load weather';
      });
      debugPrint('Workout weather load failed: $error');
    }
  }

  Future<void> _notifyWorkoutStarted() async {
    final mode = _selectedMode ?? WorkoutMode.outdoorWalking;
    await AppNotificationsService.instance.showWithCooldown(
      uniqueKey: 'workout_started_${mode.name}',
      title: 'Workout started',
      body: '${_modeLabel(mode)} tracking is live. Keep your pace steady.',
      cooldown: const Duration(minutes: 2),
    );
  }

  Future<void> _maybeNotifyWeatherAdvisory() async {
    if (_weatherError != null) return;
    final temp = _weatherTempC;
    final wind = _weatherWindKph;
    final condition = (_weatherCondition ?? '').toLowerCase();
    final severeCondition = condition.contains('rain') ||
        condition.contains('storm') ||
        condition.contains('thunder') ||
        condition.contains('snow');
    final hot = temp != null && temp >= 35;
    final windy = wind != null && wind >= 30;
    if (!severeCondition && !hot && !windy) return;

    await AppNotificationsService.instance.showWithCooldown(
      uniqueKey: 'workout_weather_advisory',
      title: 'Workout weather advisory',
      body: hot
          ? 'High heat detected (${temp!.toStringAsFixed(1)}°C). Hydrate and ease intensity.'
          : severeCondition
          ? 'Current weather is ${_weatherCondition ?? 'unfavorable'}. Consider safer indoor training.'
          : 'Strong wind detected (${wind!.toStringAsFixed(1)} kph). Adjust your route and effort.',
      cooldown: const Duration(hours: 4),
    );
  }

  Future<void> _checkWorkoutMilestoneNotifications() async {
    if (!_isTracking || _isPaused) return;

    final distanceKm = (_totalDistanceMeters / 1000).floor();
    if (distanceKm > 0 && distanceKm > _lastDistanceMilestoneKm) {
      _lastDistanceMilestoneKm = distanceKm;
      await AppNotificationsService.instance.showWithCooldown(
        uniqueKey: 'workout_distance_milestone_$distanceKm',
        title: 'Distance milestone',
        body: 'Great work! You just crossed ${distanceKm} km.',
        cooldown: const Duration(minutes: 1),
      );
    }

    final minutes = _activeMinutes;
    final milestoneMinutes = (minutes ~/ 10) * 10;
    if (milestoneMinutes >= 10 &&
        milestoneMinutes > _lastDurationMilestoneMinutes) {
      _lastDurationMilestoneMinutes = milestoneMinutes;
      await AppNotificationsService.instance.showWithCooldown(
        uniqueKey: 'workout_time_milestone_$milestoneMinutes',
        title: 'Time milestone',
        body: 'You have trained for $milestoneMinutes minutes.',
        cooldown: const Duration(minutes: 1),
      );
    }

    if (!_goalReachedNotified &&
        (_estimatedCalories >= 300 || _activeMinutes >= 30)) {
      _goalReachedNotified = true;
      await AppNotificationsService.instance.showWithCooldown(
        uniqueKey: 'workout_goal_reached',
        title: 'Goal reached',
        body:
            'Workout goal complete: ${_estimatedCalories} kcal and ${_activeMinutes} min.',
        cooldown: const Duration(minutes: 5),
      );
    }
  }

  void _notifyMetricsChangedIfNeeded() {
    final calories = _estimatedCalories;
    final activeMinutes = _activeMinutes;
    _syncWorkoutWidget();
    if (_lastReportedCalories == calories &&
        _lastReportedActiveMinutes == activeMinutes) {
      return;
    }
    _lastReportedCalories = calories;
    _lastReportedActiveMinutes = activeMinutes;
    widget.onMetricsChanged?.call(calories, activeMinutes);
  }

  List<Map<String, double>> _sampleRoutePointsForWidget() {
    if (_routePoints.isEmpty) return const <Map<String, double>>[];
    const int maxPoints = 48;
    if (_routePoints.length <= maxPoints) {
      return _routePoints
          .map((p) => <String, double>{'lat': p.latitude, 'lng': p.longitude})
          .toList();
    }

    final sampled = <Map<String, double>>[];
    final step = (_routePoints.length - 1) / (maxPoints - 1);
    for (var i = 0; i < maxPoints; i++) {
      final idx = (i * step).round().clamp(0, _routePoints.length - 1);
      final point = _routePoints[idx];
      sampled.add(<String, double>{'lat': point.latitude, 'lng': point.longitude});
    }
    return sampled;
  }

  void _syncWorkoutWidget() {
    final mode = _selectedMode == null ? 'Workout' : _modeLabel(_selectedMode!);
    unawaited(
      HomeWidgetService.updateWorkoutSummary(
        mode: mode,
        distance: formatWorkoutDistance(_selectedMode, _totalDistanceMeters),
        duration: _formatDuration(_elapsed),
        calories: _estimatedCalories,
        paceLabel: _paceOrSpeedLabel,
        paceValue: _paceOrSpeedValueText,
        routePoints: _sampleRoutePointsForWidget(),
      ),
    );
  }

  Future<Position?> _fetchCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } on MissingPluginException {
      if (!mounted) {
        return null;
      }
      setState(() {
        _statusMessage =
            'Location plugin not loaded. Fully restart the app (stop and run again).';
      });
      return null;
    } on PlatformException catch (error) {
      if (!mounted) {
        return null;
      }
      setState(() {
        _statusMessage =
            'Location platform error: ${error.message ?? error.code}';
      });
      return null;
    } on TimeoutException {
      if (!mounted) {
        return null;
      }
      setState(() {
        _statusMessage = 'Timed out while getting your current location.';
      });
      return null;
    } on LocationServiceDisabledException {
      if (!mounted) {
        return null;
      }
      setState(() {
        _statusMessage = 'Location services are disabled.';
      });
      return null;
    } on PermissionDeniedException catch (error) {
      if (!mounted) {
        return null;
      }
      setState(() {
        _statusMessage = 'Unable to get current location: ${error.message}';
      });
      return null;
    }
  }

  Future<bool> _ensureLocationAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _statusMessage = 'Location services are disabled.';
      });
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _statusMessage = 'Location permission denied.';
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _statusMessage = 'Location permission permanently denied.';
      });
      return false;
    }

    return true;
  }

  Future<void> _primeLiveLocation({
    String loadingMessage = 'Getting your live location...',
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPreparingLocation = true;
      _statusMessage = loadingMessage;
    });

    final hasAccess = await _ensureLocationAccess();
    if (!hasAccess) {
      if (mounted) {
        setState(() {
          _isPreparingLocation = false;
        });
      }
      return;
    }

    final position = await _fetchCurrentPosition();
    if (position == null || !mounted) {
      if (mounted) {
        setState(() {
          _isPreparingLocation = false;
        });
      }
      return;
    }

    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _isPreparingLocation = false;
      _currentPosition = point;
      if (!_isTracking) {
        _statusMessage = 'Live location ready.';
      }
    });
    unawaited(_moveWorkoutMapCamera(point, 17));
    await _startPreviewLocationUpdates();
  }

  Future<void> _animateWorkoutMapCamera(LatLng target, double zoom) async {
    final controller = _workoutMapController;
    if (controller == null) {
      return;
    }
    _programmaticCameraMove = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, zoom),
      );
    } finally {
      _programmaticCameraMove = false;
    }
  }

  Future<void> _moveWorkoutMapCamera(LatLng target, double zoom) async {
    if (_showMetricsFullscreen) {
      return;
    }
    if (_workoutMapController == null) {
      _pendingMapCameraTarget = target;
      _pendingMapCameraZoom = zoom;
      return;
    }
    await _animateWorkoutMapCamera(target, zoom);
  }

  void _flushPendingWorkoutMapCamera() {
    final target = _pendingMapCameraTarget;
    final zoom = _pendingMapCameraZoom;
    if (target == null || _workoutMapController == null) {
      return;
    }
    _pendingMapCameraTarget = null;
    _pendingMapCameraZoom = null;
    unawaited(_animateWorkoutMapCamera(target, zoom ?? 17));
  }

  void _onWorkoutMapCreated(GoogleMapController controller) {
    _workoutMapController = controller;
    _flushPendingWorkoutMapCamera();
  }

  void _onWorkoutCameraMoveStarted() {
    if (_programmaticCameraMove) {
      return;
    }
    if (!_mapFollowsUserLocation || !mounted) {
      return;
    }
    setState(() {
      _mapFollowsUserLocation = false;
    });
  }

  void _followMapCameraToUser(LatLng target) {
    if (!_mapFollowsUserLocation || _showMetricsFullscreen) {
      return;
    }
    unawaited(_moveWorkoutMapCamera(target, _mapCameraZoom));
  }

  void _recenterMapOnUser() {
    final point = _currentPosition;
    if (point == null) {
      return;
    }
    setState(() {
      _mapFollowsUserLocation = true;
    });
    unawaited(_moveWorkoutMapCamera(point, 17));
  }

  Widget _buildRecenterMapChip({
    required Color textColor,
    required Color cardColor,
  }) {
    return Tooltip(
      message: _mapFollowsUserLocation
          ? 'Map follows your location (pan map to explore freely)'
          : 'Recenter map on your location',
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        color: cardColor.withValues(alpha: 0.96),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _recenterMapOnUser,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Icon(
              Icons.my_location_rounded,
              size: 18,
              color: _mapFollowsUserLocation
                  ? Colors.blueAccent
                  : textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPreviewLocationUpdates() async {
    if (_isTracking) {
      return;
    }

    final previewSettings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 1),
            forceLocationManager: true,
          )
        : Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            activityType: ActivityType.fitness,
            pauseLocationUpdatesAutomatically: false,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
          );

    await _previewPositionSubscription?.cancel();
    _previewPositionSubscription = Geolocator.getPositionStream(
      locationSettings: previewSettings,
    ).listen((position) {
      if (!mounted || _isTracking) {
        return;
      }
      final nextPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = nextPoint;
        _statusMessage = 'Live location ready.';
      });
      _followMapCameraToUser(nextPoint);
    });
  }

  Future<void> _startTracking() async {
    try {
      final hasAccess = await _ensureLocationAccess();
      if (!hasAccess) {
        return;
      }

      final locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 1),
              forceLocationManager: true,
              foregroundNotificationConfig: ForegroundNotificationConfig(
                notificationTitle: 'Synthese workout tracking',
                notificationText:
                    'Tracking your ${_modeLabel(_selectedMode ?? WorkoutMode.outdoorWalking)} in background',
                enableWakeLock: true,
                setOngoing: true,
              ),
            )
          : Platform.isIOS
          ? AppleSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              activityType: ActivityType.fitness,
              pauseLocationUpdatesAutomatically: false,
              showBackgroundLocationIndicator: true,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            );

      if (_currentPosition == null) {
        await _primeLiveLocation();
        if (_currentPosition == null) {
          return;
        }
      }

      await _previewPositionSubscription?.cancel();
      _previewPositionSubscription = null;
      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _onPositionUpdate,
            onError: (Object error) {
              if (!mounted) {
                return;
              }
              setState(() {
                _statusMessage = 'Location stream error: $error';
                _isTracking = false;
                if (_trackingStartAt != null) {
                  _elapsedBeforeCurrentRun += DateTime.now().difference(
                    _trackingStartAt!,
                  );
                  _trackingStartAt = null;
                }
              });
            },
          );

      // Some devices/emulators intermittently stop emitting stream updates.
      // Polling current position keeps map + metrics progressing as a fallback.
      _positionFallbackTimer?.cancel();
      _positionFallbackTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (!_isTracking || _isManuallyPaused) {
          return;
        }
        final position = await _fetchCurrentPosition();
        if (position != null && mounted && _isTracking) {
          _onPositionUpdate(position, clearStatus: false);
        }
      });

      setState(() {
        _isTracking = true;
        _isManuallyPaused = false;
        _statusMessage = 'Tracking started.';
        _sessionStartedAt = DateTime.now();
        _trackingStartAt = DateTime.now();
        _lastDistanceMilestoneKm = 0;
        _lastDurationMilestoneMinutes = 0;
        _goalReachedNotified = false;
        if (_currentPosition != null) {
          _routePoints.add(_currentPosition!);
        }
      });
      _notifyMetricsChangedIfNeeded();
      unawaited(_updateTrackingNotification());
      unawaited(_notifyWorkoutStarted());
      if (mounted) AppToast.success(context, 'Workout started — let\'s go!', icon: Icons.play_arrow_rounded);

      _durationTicker?.cancel();
      _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isTracking) {
          return;
        }
        setState(() {});
        _notifyMetricsChangedIfNeeded();
        unawaited(_updateTrackingNotification());
        unawaited(_checkWorkoutMilestoneNotifications());
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage =
            'Location plugin not loaded. Fully restart the app (stop and run again).';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage =
            'Location platform error: ${error.message ?? error.code}';
      });
    }
  }

  Future<void> _startRouteWithCountdown() async {
    if (_isTracking || _isCountdownActive) {
      return;
    }

    if (!_isLocationReady) {
      await _primeLiveLocation();
      return;
    }

    setState(() {
      _isCountdownActive = true;
      _countdownValue = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownValue > 0) {
        setState(() {
          _countdownValue -= 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountdownActive = false;
          _countdownValue = 3;
        });
        await _startTracking();
      }
    });
  }

  void _cancelCountdown() {
    if (!_isCountdownActive) {
      return;
    }
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _isCountdownActive = false;
      _countdownValue = 3;
      _statusMessage = 'Start cancelled.';
    });
  }

  Future<void> _confirmStopRoute() async {
    if (!_isTracking) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : const Color(0xFFEDEDEF);
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = textColor.withValues(alpha: 0.65);

    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End route?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Helvetica',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your current tracking session will stop.',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('End Route'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldStop == true) {
      _stopTracking();
    }
  }

  void _stopTracking({bool saveSession = true}) {
    final routeSnapshot = List<LatLng>.from(_routePoints);
    final startedAt = _sessionStartedAt;
    final endedAt = DateTime.now();
    final durationSnapshot = _elapsed;
    final distanceSnapshot = _totalDistanceMeters;
    final caloriesSnapshot = _estimatedCalories;
    final modeSnapshot = _selectedMode;

    _cancelCountdown();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionFallbackTimer?.cancel();
    _positionFallbackTimer = null;
    _durationTicker?.cancel();
    _durationTicker = null;

    setState(() {
      _isTracking = false;
      _isManuallyPaused = false;
      _sessionStartedAt = null;
      if (_trackingStartAt != null) {
        _elapsedBeforeCurrentRun += DateTime.now().difference(
          _trackingStartAt!,
        );
        _trackingStartAt = null;
      }
    });
    _notifyMetricsChangedIfNeeded();
    unawaited(_cancelTrackingNotification());
    unawaited(_startPreviewLocationUpdates());
    if (saveSession && mounted) {
      AppToast.success(context, 'Workout saved', icon: Icons.check_circle_outline_rounded);
    }
    final canSaveSession = modeSnapshot != null &&
        startedAt != null &&
        durationSnapshot.inSeconds > 0 &&
        (routeSnapshot.length >= 2 ||
            (modeSnapshot == WorkoutMode.swimming &&
                routeSnapshot.isNotEmpty &&
                durationSnapshot.inSeconds >= 30));
    if (saveSession && canSaveSession) {
      unawaited(
        _saveWorkoutSession(
          mode: modeSnapshot,
          startedAt: startedAt,
          endedAt: endedAt,
          distanceMeters: distanceSnapshot,
          calories: caloriesSnapshot,
          activeMinutes: durationSnapshot.inMinutes,
          routePoints: routeSnapshot,
        ),
      );
    }
  }

  void _resetRoute() {
    _stopTracking(saveSession: false);
    setState(() {
      _routePoints.clear();
      _currentPosition = null;
      _trackingStartAt = null;
      _elapsedBeforeCurrentRun = Duration.zero;
      _totalDistanceMeters = 0;
      _isManuallyPaused = false;
      _statusMessage = null;
      _mapFollowsUserLocation = true;
    });
    widget.onTrackingBaselineCleared?.call();
    _notifyMetricsChangedIfNeeded();
    unawaited(_updateTrackingNotification());
  }

  Future<void> _saveWorkoutSession({
    required WorkoutMode mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required double distanceMeters,
    required int calories,
    required int activeMinutes,
    required List<LatLng> routePoints,
  }) async {
    try {
      unawaited(
        HomeWidgetService.updateWorkoutSummary(
          mode: _modeLabel(mode),
          distance: formatWorkoutDistance(mode, distanceMeters),
          duration: _formatDuration(Duration(minutes: activeMinutes)),
          calories: calories,
          paceLabel: _paceOrSpeedLabel,
          paceValue: _paceOrSpeedValueText,
          routePoints: routePoints
              .map((p) => <String, double>{'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        ),
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workout_sessions')
          .add({
            'mode': mode.name,
            'startedAt': Timestamp.fromDate(startedAt),
            'endedAt': Timestamp.fromDate(endedAt),
            'distanceMeters': distanceMeters,
            'calories': calories,
            'activeMinutes': activeMinutes,
            'routePoints': routePoints
                .map(
                  (point) => {
                    'lat': point.latitude,
                    'lng': point.longitude,
                  },
                )
                .toList(),
          });
    } catch (error) {
      debugPrint('Failed to save workout session: $error');
    }
  }

  void _openHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const WorkoutHistoryPage(),
      ),
    );
  }

  Widget _buildHeaderCircleButton({
    required bool isDark,
    required bool isNarrowLayout,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final circleSize = isNarrowLayout ? 40.0 : 42.0;
    final iconSize = isNarrowLayout ? 20.0 : 22.0;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _pauseTracking() {
    if (!_isTracking || _isPaused) {
      return;
    }

    setState(() {
      if (_trackingStartAt != null) {
        _elapsedBeforeCurrentRun += DateTime.now().difference(
          _trackingStartAt!,
        );
        _trackingStartAt = null;
      }
      _isManuallyPaused = true;
      _statusMessage = 'Paused. Tap Resume to continue.';
    });
    _notifyMetricsChangedIfNeeded();
  }

  void _resumeTracking() {
    if (!_isTracking) {
      return;
    }

    setState(() {
      _isManuallyPaused = false;
      _trackingStartAt ??= DateTime.now();
      _statusMessage = 'Tracking resumed.';
    });
    _notifyMetricsChangedIfNeeded();
  }

  void _onPositionUpdate(Position position, {bool clearStatus = true}) {
    final nextPoint = LatLng(position.latitude, position.longitude);
    final previousPoint = _routePoints.isEmpty ? null : _routePoints.last;

    var distanceToAdd = 0.0;
    if (previousPoint != null) {
      distanceToAdd = Geolocator.distanceBetween(
        previousPoint.latitude,
        previousPoint.longitude,
        nextPoint.latitude,
        nextPoint.longitude,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (!_isManuallyPaused) {
        _routePoints.add(nextPoint);
        _currentPosition = nextPoint;
        _totalDistanceMeters += distanceToAdd;
      } else {
        _currentPosition = nextPoint;
      }

      if (_isManuallyPaused) {
        _statusMessage = 'Paused. Tap Resume to continue.';
      } else if (clearStatus) {
        _statusMessage = null;
      }
    });

    _followMapCameraToUser(nextPoint);
    _notifyMetricsChangedIfNeeded();
    unawaited(_checkWorkoutMilestoneNotifications());
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _modeLabel(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
        return 'Running';
      case WorkoutMode.trailRun:
        return 'Trail Run';
      case WorkoutMode.outdoorWalking:
        return 'Outdoor Walking';
      case WorkoutMode.cycling:
        return 'Cycling';
      case WorkoutMode.mountainBikeRide:
        return 'Mountain Bike Ride';
      case WorkoutMode.eBikeRide:
        return 'E-Bike Ride';
      case WorkoutMode.swimming:
        return 'Swimming';
    }
  }

  IconData _modeIcon(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
      case WorkoutMode.trailRun:
        return Icons.directions_run_rounded;
      case WorkoutMode.outdoorWalking:
        return Icons.directions_walk_rounded;
      case WorkoutMode.cycling:
      case WorkoutMode.mountainBikeRide:
        return Icons.pedal_bike_rounded;
      case WorkoutMode.eBikeRide:
        return Icons.electric_bike_rounded;
      case WorkoutMode.swimming:
        return Icons.pool_rounded;
    }
  }

  String _modeSubtitle(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
        return 'GPS route, speed (km/h), calories, and active time.';
      case WorkoutMode.trailRun:
        return 'Trail run with GPS, pace (min/km), and higher-intensity calorie estimate.';
      case WorkoutMode.outdoorWalking:
        return 'Outdoor walk with live GPS route and speed.';
      case WorkoutMode.cycling:
        return 'Ride with GPS speed (km/h), distance, and calorie estimate.';
      case WorkoutMode.mountainBikeRide:
        return 'Off-road ride with GPS; calories tuned for higher MTB effort.';
      case WorkoutMode.eBikeRide:
        return 'Assisted ride with GPS; calories reflect lighter effort vs. standard cycling.';
      case WorkoutMode.swimming:
        return 'Open-water or pool-side GPS; distance in meters, swim pace (/100m), time-based calories.';
    }
  }

  Future<void> _openMode(WorkoutMode mode) async {
    _resetRoute();
    setState(() {
      _selectedMode = mode;
      _showMetricsFullscreen = false;
    });
    widget.onWorkoutModeChanged?.call(true);
    await _primeLiveLocation(
      loadingMessage: 'Getting your live location for ${_modeLabel(mode)}...',
    );
    unawaited(_loadWorkoutWeather());
  }

  void _backToModeSelection() {
    _forgetWorkoutMapController();
    _resetRoute();
    _previewPositionSubscription?.cancel();
    _previewPositionSubscription = null;
    setState(() {
      _selectedMode = null;
      _showMetricsFullscreen = false;
    });
    widget.onWorkoutModeChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale = mediaQuery.textScaler.scale(1.0).clamp(0.9, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final safePadding = mediaQuery.padding;
    final isNarrowLayout = mediaQuery.size.width < 390;
    final displayedDistance =
        formatWorkoutDistance(_selectedMode, _totalDistanceMeters);
    final displayedDuration = _formatDuration(_elapsed);
    final displayedCalories = _estimatedCalories;
    final initialTarget =
        _currentPosition ??
        (_routePoints.isNotEmpty ? _routePoints.last : _defaultStart);
    final mapMarkers = <Marker>{};
    if (_currentPosition != null) {
      mapMarkers.add(
        Marker(
          markerId: const MarkerId('workout_user'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          anchor: const Offset(0.5, 1),
        ),
      );
    }
    final mapPolylines = <Polyline>{};
    if (_routePoints.length >= 2) {
      mapPolylines.add(
        Polyline(
          polylineId: const PolylineId('workout_route'),
          points: List<LatLng>.from(_routePoints),
          width: 5,
          color: Colors.blueAccent,
        ),
      );
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(clampedTextScale.toDouble()),
      ),
      child: _selectedMode == null
          ? SingleChildScrollView(
              key: const ValueKey('workout_tab'),
              padding: EdgeInsets.only(
                top: safePadding.top + 24.0,
                bottom: safePadding.bottom + 120.0,
                left: isNarrowLayout ? 16.0 : 24.0,
                right: isNarrowLayout ? 16.0 : 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Workout',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: isNarrowLayout ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderCircleButton(
                        isDark: isDark,
                        isNarrowLayout: isNarrowLayout,
                        icon: Icons.history_rounded,
                        onTap: _openHistoryScreen,
                        tooltip: 'History',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose an activity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isNarrowLayout ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...WorkoutMode.values.map((mode) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openMode(mode),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _modeIcon(mode),
                                  color: Colors.blueAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _modeLabel(mode),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: isNarrowLayout ? 16 : 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _modeSubtitle(mode),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor.withValues(
                                          alpha: 0.65,
                                        ),
                                        fontSize: isNarrowLayout ? 12 : 13,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            )
          : Stack(
              key: const ValueKey('workout_tracking_fullscreen'),
              children: [
                Positioned.fill(
                  child: _showMetricsFullscreen
                      ? Container(
                          color: isDark
                              ? const Color(0xFF080808)
                              : Colors.white,
                          padding: EdgeInsets.only(
                            top: safePadding.top + 80,
                            left: isNarrowLayout ? 20 : 28,
                            right: isNarrowLayout ? 20 : 28,
                            bottom: safePadding.bottom + 140,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      _modeLabel(_selectedMode!),
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.8),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      displayedDistance,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: isNarrowLayout ? 46 : 56,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Helvetica',
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Distance',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      displayedDuration,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: isNarrowLayout ? 40 : 48,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Helvetica',
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Duration',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _paceOrSpeedValueText,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: isNarrowLayout ? 40 : 48,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Helvetica',
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      _paceOrSpeedLabel,
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '$displayedCalories kcal',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: isNarrowLayout ? 40 : 48,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Helvetica',
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Calories',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Helvetica',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : Colors.black.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: _isWeatherLoading
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                    color: textColor.withValues(alpha: 0.75),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Loading weather...',
                                                  style: TextStyle(
                                                    color: textColor.withValues(alpha: 0.75),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.cloud_outlined,
                                                      color: textColor.withValues(
                                                        alpha: 0.85,
                                                      ),
                                                      size: 17,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _weatherError ??
                                                            '${_weatherTempC?.toStringAsFixed(1) ?? '--'}°C • ${_weatherCondition ?? 'Unknown'}',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color:
                                                              _weatherError != null
                                                              ? (isDark
                                                                    ? Colors
                                                                          .orange
                                                                          .shade200
                                                                    : Colors
                                                                          .red
                                                                          .shade700)
                                                              : textColor,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: _loadWorkoutWeather,
                                                      child: Icon(
                                                        Icons.refresh_rounded,
                                                        size: 18,
                                                        color: textColor.withValues(
                                                          alpha: 0.75,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_weatherError == null) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _weatherLocationLabel ??
                                                        'Location unavailable',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: textColor.withValues(
                                                        alpha: 0.72,
                                                      ),
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Lat ${_currentPosition?.latitude.toStringAsFixed(6) ?? '--'} • Lng ${_currentPosition?.longitude.toStringAsFixed(6) ?? '--'}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: textColor.withValues(
                                                        alpha: 0.66,
                                                      ),
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Feels ${_weatherFeelsLikeC?.toStringAsFixed(1) ?? '--'}°C • Humidity ${_weatherHumidity ?? '--'}% • Wind ${_weatherWindKph?.toStringAsFixed(1) ?? '--'} kph',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: textColor.withValues(
                                                        alpha: 0.62,
                                                      ),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: initialTarget,
                            zoom: _currentPosition == null ? 13 : 17,
                          ),
                          markers: mapMarkers,
                          polylines: mapPolylines,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          onMapCreated: _onWorkoutMapCreated,
                          onCameraMoveStarted: _onWorkoutCameraMoveStarted,
                          onCameraMove: (position) {
                            _mapCameraZoom = position.zoom;
                          },
                        ),
                ),
                Positioned(
                  top: safePadding.top + 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _backToModeSelection,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _modeLabel(_selectedMode!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderCircleButton(
                        isDark: isDark,
                        isNarrowLayout: isNarrowLayout,
                        icon: Icons.history_rounded,
                        onTap: _openHistoryScreen,
                        tooltip: 'History',
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderCircleButton(
                        isDark: isDark,
                        isNarrowLayout: isNarrowLayout,
                        icon: _hideTrackingUi
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        onTap: () {
                          setState(() {
                            _hideTrackingUi = !_hideTrackingUi;
                          });
                        },
                        tooltip: _hideTrackingUi ? 'Show UI' : 'Hide UI',
                      ),
                      if (_showMetricsFullscreen) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _showMetricsFullscreen = false;
                            });
                          },
                          icon: const Icon(Icons.fullscreen_exit_rounded),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hideTrackingUi &&
                    _currentPosition != null &&
                    !_showMetricsFullscreen &&
                    !_isCountdownActive)
                  Positioned(
                    top: safePadding.top + 56,
                    right: isNarrowLayout ? 12 : 16,
                    child: _buildRecenterMapChip(
                      textColor: textColor,
                      cardColor: cardColor,
                    ),
                  ),
                if (!_isCountdownActive && !_hideTrackingUi)
                  Positioned(
                    left: isNarrowLayout ? 12 : 16,
                    right: isNarrowLayout ? 12 : 16,
                    bottom: safePadding.bottom + 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_showMetricsFullscreen) ...[
                        if (_currentPosition != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildRecenterMapChip(
                              textColor: textColor,
                              cardColor: cardColor,
                            ),
                          ),
                        if (_currentPosition != null)
                          const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 32),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Distance',
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            displayedDistance,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: isNarrowLayout
                                                  ? 19
                                                  : 21,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Duration',
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            displayedDuration,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: isNarrowLayout
                                                  ? 19
                                                  : 21,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _paceOrSpeedLabel,
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _paceOrSpeedValueText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: isNarrowLayout
                                                  ? 19
                                                  : 21,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'Helvetica',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -6,
                                child: IconButton(
                                  onPressed: () {
                                    _forgetWorkoutMapController();
                                    setState(() {
                                      _showMetricsFullscreen = true;
                                    });
                                  },
                                  icon: const Icon(Icons.fullscreen_rounded),
                                  visualDensity: VisualDensity.compact,
                                  color: textColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ],
                        Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_showMetricsFullscreen)
                              Text(
                                'Calories: $displayedCalories kcal',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                            if (!_showMetricsFullscreen) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isWeatherLoading
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: textColor.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Loading weather...',
                                            style: TextStyle(
                                              color: textColor.withValues(alpha: 0.7),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.cloud_outlined,
                                                size: 14,
                                                color: textColor.withValues(alpha: 0.8),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  _weatherError ??
                                                      '${_weatherTempC?.round() ?? '--'}°C • ${_weatherCondition ?? 'Unknown'}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: _weatherError != null
                                                        ? (isDark
                                                              ? Colors.orange.shade200
                                                              : Colors.red.shade700)
                                                        : textColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _loadWorkoutWeather,
                                                child: Icon(
                                                  Icons.refresh_rounded,
                                                  size: 15,
                                                  color: textColor.withValues(
                                                    alpha: 0.75,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_weatherError == null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _weatherLocationLabel ?? 'Location unavailable',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: textColor.withValues(alpha: 0.72),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Feels ${_weatherFeelsLikeC?.round() ?? '--'}° • Hum ${_weatherHumidity ?? '--'}% • Wind ${_weatherWindKph?.round() ?? '--'} kph',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: textColor.withValues(alpha: 0.6),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                height: 1.25,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                              ),
                            ],
                            if (_statusMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.orange.shade200
                                      : Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _isTracking
                                      ? _confirmStopRoute
                                      : (_isLocationReady && !_isCountdownActive
                                            ? _startRouteWithCountdown
                                            : null),
                                  icon: Icon(
                                    _isTracking ? Icons.stop : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    _isTracking
                                        ? 'Stop Route'
                                        : (_isPreparingLocation
                                              ? 'Preparing GPS...'
                                              : 'Start Route'),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _isTracking
                                      ? (_isPaused
                                            ? _resumeTracking
                                            : _pauseTracking)
                                      : null,
                                  icon: Icon(
                                    _isPaused ? Icons.play_arrow : Icons.pause,
                                  ),
                                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      _canResetRoute ? _resetRoute : null,
                                  icon: const Icon(Icons.replay),
                                  label: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                      ],
                    ),
                  ),
                if (_isCountdownActive)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: safePadding.bottom + (isNarrowLayout ? 154 : 170),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey<int>(_countdownValue),
                            tween: Tween<double>(
                              begin: (_countdownValue / 3).clamp(0.0, 1.0),
                              end: ((_countdownValue - 1) / 3).clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.linear,
                            builder: (context, progress, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    width: isNarrowLayout ? 126 : 138,
                                    height: isNarrowLayout ? 126 : 138,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _CountdownBorderPainter(
                                              progress: progress,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 280),
                                            transitionBuilder: (child, animation) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: ScaleTransition(
                                                  scale: Tween<double>(
                                                    begin: 0.92,
                                                    end: 1,
                                                  ).animate(animation),
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              _countdownValue == 0
                                                  ? 'Go'
                                                  : _countdownValue.toString(),
                                              key: ValueKey<int>(_countdownValue),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isNarrowLayout ? 50 : 56,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Helvetica',
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _cancelCountdown,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('MMM d, yyyy  h:mm a').format(value);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'running':
        return 'Running';
      case 'trailRun':
        return 'Trail Run';
      case 'cycling':
        return 'Cycling';
      case 'mountainBikeRide':
        return 'Mountain Bike Ride';
      case 'eBikeRide':
        return 'E-Bike Ride';
      case 'swimming':
        return 'Swimming';
      case 'outdoorWalking':
      default:
        return 'Outdoor Walking';
    }
  }

  bool _sessionMatchesSearch(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    final data = doc.data();
    final mode = (data['mode'] as String?) ?? 'outdoorWalking';
    final modeLc = mode.toLowerCase();
    if (modeLc.contains(q)) {
      return true;
    }
    final label = _modeLabel(mode).toLowerCase();
    if (label.contains(q)) {
      return true;
    }
    for (final word in label.split(RegExp(r'\s+'))) {
      if (word.isNotEmpty && word.contains(q)) {
        return true;
      }
    }

    final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
    final endedAt = (data['endedAt'] as Timestamp?)?.toDate();
    final calories = (data['calories'] as num?)?.toInt() ?? 0;
    final activeMinutes = (data['activeMinutes'] as num?)?.toInt() ?? 0;
    final distanceMeters = (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
    final modeEnum = _workoutModeFromName(mode);
    final distanceFormatted =
        formatWorkoutDistance(modeEnum, distanceMeters).toLowerCase();

    final buffer = StringBuffer()
      ..write(label)
      ..write(' ')
      ..write(calories)
      ..write(' ')
      ..write(activeMinutes)
      ..write(' ')
      ..write(distanceFormatted)
      ..write(' ')
      ..write(distanceMeters);
    if (startedAt != null) {
      buffer.write(' ${_formatDateTime(startedAt)}');
    }
    if (endedAt != null) {
      buffer.write(' ${_formatDateTime(endedAt)}');
    }
    return buffer.toString().toLowerCase().contains(q);
  }

  Widget _buildSearchBar({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search workouts...',
          hintStyle: TextStyle(color: subTextColor, fontSize: 16),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: subTextColor,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: subTextColor,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Delete workout?', style: TextStyle(color: textColor)),
        content: Text(
          'This workout session will be removed from your history.',
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _deleteWorkoutSession({
    required String uid,
    required String sessionId,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('workout_sessions')
        .doc(sessionId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    // Match finance page search field in light mode (finance.dart cardColor).
    final searchBarFillColor =
        isDark ? cardColor : const Color(0xFFE5E5E7);
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final safePadding = MediaQuery.of(context).padding;

    if (uid == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('Workout History')),
        body: const Center(child: Text('Please sign in to view history.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              safePadding.top + 12,
              16,
              0,
            ),
            child: _buildSearchBar(
              cardColor: searchBarFillColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('workout_sessions')
                  .orderBy('endedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: BouncingDotsLoader(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No workout history yet.',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final query = _searchController.text;
                final filteredDocs = docs
                    .where((d) => _sessionMatchesSearch(d, query))
                    .toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No workouts match your search.',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              safePadding.bottom + 24,
            ),
            itemCount: filteredDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sessionId = filteredDocs[index].id;
              final data = filteredDocs[index].data();
              final mode = (data['mode'] as String?) ?? 'outdoorWalking';
              final modeEnum = _workoutModeFromName(mode);
              final startedAt = (data['startedAt'] as Timestamp?)?.toDate();
              final endedAt = (data['endedAt'] as Timestamp?)?.toDate();
              final distanceMeters =
                  (data['distanceMeters'] as num?)?.toDouble() ?? 0.0;
              final calories = (data['calories'] as num?)?.toInt() ?? 0;
              final activeMinutes = (data['activeMinutes'] as num?)?.toInt() ?? 0;
              final routeRaw = (data['routePoints'] as List<dynamic>? ?? const []);
              final routePoints = routeRaw
                  .map((entry) => entry as Map<String, dynamic>)
                  .map(
                    (entry) => LatLng(
                      (entry['lat'] as num?)?.toDouble() ?? 0,
                      (entry['lng'] as num?)?.toDouble() ?? 0,
                    ),
                  )
                  .toList();

              final duration = startedAt != null && endedAt != null
                  ? endedAt.difference(startedAt)
                  : Duration(minutes: activeMinutes);
              final subtitle =
                  '${_formatDateTime(startedAt ?? DateTime.now())} - ${_formatDateTime(endedAt ?? DateTime.now())}';

              return Dismissible(
                key: Key(sessionId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                confirmDismiss: (_) => _showDeleteConfirmation(context),
                onDismissed: (_) {
                  _deleteWorkoutSession(uid: uid, sessionId: sessionId);
                  AppToast.info(context, 'Workout deleted', icon: Icons.delete_outline_rounded);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(18),
                      child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      title: Text(
                        _modeLabel(mode),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _HistoryMetricChip(
                                label: 'Distance',
                                value: formatWorkoutDistance(
                                  modeEnum,
                                  distanceMeters,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HistoryMetricChip(
                                label: 'Duration',
                                value: _formatDuration(duration),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _HistoryMetricChip(
                                label: 'Calories',
                                value: '$calories kcal',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _HistoryMetricChip(
                                label: 'Active',
                                value: '$activeMinutes min',
                              ),
                            ),
                          ],
                        ),
                        if (routePoints.length >= 2) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 220,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: routePoints.first,
                                  zoom: 14,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('history_start'),
                                    position: routePoints.first,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueGreen,
                                    ),
                                    anchor: const Offset(0.5, 1),
                                  ),
                                  Marker(
                                    markerId: const MarkerId('history_end'),
                                    position: routePoints.last,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                    anchor: const Offset(0.5, 1),
                                  ),
                                },
                                polylines: {
                                  Polyline(
                                    polylineId: const PolylineId('history_route'),
                                    points: routePoints,
                                    width: 4,
                                    color: Colors.blueAccent,
                                  ),
                                },
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                                zoomControlsEnabled: false,
                                onMapCreated: (controller) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) async {
                                    try {
                                      await controller.animateCamera(
                                        CameraUpdate.newLatLngBounds(
                                          _boundsForRoutePoints(routePoints),
                                          36,
                                        ),
                                      );
                                    } catch (_) {
                                      // Ignore invalid bounds (e.g. degenerate route).
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              );
            },
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMetricChip extends StatelessWidget {
  const _HistoryMetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBorderPainter extends CustomPainter {
  const _CountdownBorderPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    const radius = 14.0;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      const Radius.circular(radius),
    );
    final path = ui.Path()..addRRect(rrect);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.22);
    canvas.drawPath(path, basePaint);

    final metrics = path.computeMetrics();
    if (metrics.isEmpty) {
      return;
    }
    final metric = metrics.first;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final progressPath = metric.extractPath(0, metric.length * clampedProgress);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF31D0AA);
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CountdownBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
