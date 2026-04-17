import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum WorkoutMode { running, outdoorWalking, cycling }

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key, this.onMetricsChanged});

  final void Function(int calories, int activeMinutes)? onMetricsChanged;

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
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTicker;
  Timer? _countdownTimer;

  bool _isTracking = false;
  bool _isAutoPaused = false;
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

  final List<LatLng> _routePoints = <LatLng>[];
  LatLng? _currentPosition;

  Duration get _elapsed {
    if (_trackingStartAt == null) {
      return _elapsedBeforeCurrentRun;
    }
    return _elapsedBeforeCurrentRun +
        DateTime.now().difference(_trackingStartAt!);
  }

  bool get _isPaused => _isAutoPaused || _isManuallyPaused;
  bool get _isLocationReady =>
      _currentPosition != null && !_isPreparingLocation;

  double get _currentMetValue {
    switch (_selectedMode) {
      case WorkoutMode.running:
        return 8.0;
      case WorkoutMode.cycling:
        return 7.5;
      case WorkoutMode.outdoorWalking:
      case null:
        return 3.5;
    }
  }

  double get _autoPauseSpeedThreshold {
    switch (_selectedMode) {
      case WorkoutMode.cycling:
        return 1.0;
      case WorkoutMode.running:
      case WorkoutMode.outdoorWalking:
      case null:
        return 0.2;
    }
  }

  int get _activeMinutes => _elapsed.inMinutes;

  int get _estimatedCalories {
    if (_routePoints.length < 2 || _totalDistanceMeters < 1) {
      return 0;
    }
    final hours = _elapsed.inSeconds / 3600.0;
    return (_currentMetValue * _userWeightKg * hours).round();
  }

  String get _speedText {
    if (_totalDistanceMeters <= 0) {
      return '-- km/h';
    }

    final distanceKm = _totalDistanceMeters / 1000.0;
    final totalHours = _elapsed.inSeconds / 3600.0;
    if (!totalHours.isFinite || totalHours <= 0) {
      return '-- km/h';
    }

    final speedKmPerHour = distanceKm / totalHours;
    if (!speedKmPerHour.isFinite || speedKmPerHour <= 0) {
      return '-- km/h';
    }

    return '${speedKmPerHour.toStringAsFixed(2)} km/h';
  }

  @override
  void initState() {
    super.initState();
    _loadUserWeight();
  }

  @override
  void dispose() {
    _durationTicker?.cancel();
    _positionSubscription?.cancel();
    _countdownTimer?.cancel();
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
        '${_formatDistanceMeters(_totalDistanceMeters)} | ${_formatDuration(_elapsed)} | $_estimatedCalories kcal | $_speedText';

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

  void _notifyMetricsChangedIfNeeded() {
    final calories = _estimatedCalories;
    final activeMinutes = _activeMinutes;
    if (_lastReportedCalories == calories &&
        _lastReportedActiveMinutes == activeMinutes) {
      return;
    }
    _lastReportedCalories = calories;
    _lastReportedActiveMinutes = activeMinutes;
    widget.onMetricsChanged?.call(calories, activeMinutes);
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
    _mapController.move(point, 17);
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
              distanceFilter: 5,
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
              distanceFilter: 5,
              activityType: ActivityType.fitness,
              pauseLocationUpdatesAutomatically: false,
              showBackgroundLocationIndicator: true,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            );

      if (_currentPosition == null) {
        await _primeLiveLocation();
        if (_currentPosition == null) {
          return;
        }
      }

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

      setState(() {
        _isTracking = true;
        _isAutoPaused = false;
        _isManuallyPaused = false;
        _statusMessage =
            'Tracking started. Move at least 5 meters to record route.';
        _trackingStartAt = DateTime.now();
      });
      _notifyMetricsChangedIfNeeded();
      unawaited(_updateTrackingNotification());

      _durationTicker?.cancel();
      _durationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isTracking) {
          return;
        }
        setState(() {});
        _notifyMetricsChangedIfNeeded();
        unawaited(_updateTrackingNotification());
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

  void _stopTracking() {
    _cancelCountdown();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _durationTicker?.cancel();
    _durationTicker = null;

    setState(() {
      _isTracking = false;
      _isAutoPaused = false;
      _isManuallyPaused = false;
      if (_trackingStartAt != null) {
        _elapsedBeforeCurrentRun += DateTime.now().difference(
          _trackingStartAt!,
        );
        _trackingStartAt = null;
      }
    });
    _notifyMetricsChangedIfNeeded();
    unawaited(_cancelTrackingNotification());
  }

  void _resetRoute() {
    _stopTracking();
    setState(() {
      _routePoints.clear();
      _currentPosition = null;
      _trackingStartAt = null;
      _elapsedBeforeCurrentRun = Duration.zero;
      _totalDistanceMeters = 0;
      _isAutoPaused = false;
      _isManuallyPaused = false;
      _statusMessage = null;
    });
    _notifyMetricsChangedIfNeeded();
    unawaited(_updateTrackingNotification());
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
      _isAutoPaused = false;
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
    final shouldAutoPause =
        previousPoint != null &&
        !_isManuallyPaused &&
        position.speed < _autoPauseSpeedThreshold &&
        distanceToAdd < 1.5;
    final shouldAutoResume =
        previousPoint != null &&
        _isAutoPaused &&
        !_isManuallyPaused &&
        (position.speed >= _autoPauseSpeedThreshold || distanceToAdd >= 3.0);

    if (!mounted) {
      return;
    }

    setState(() {
      if (shouldAutoPause && _trackingStartAt != null) {
        _elapsedBeforeCurrentRun += DateTime.now().difference(
          _trackingStartAt!,
        );
        _trackingStartAt = null;
        _isAutoPaused = true;
      } else if (shouldAutoResume &&
          _trackingStartAt == null &&
          _isAutoPaused) {
        _trackingStartAt = DateTime.now();
        _isAutoPaused = false;
      }

      if (!_isManuallyPaused && !_isAutoPaused) {
        _routePoints.add(nextPoint);
        _currentPosition = nextPoint;
        _totalDistanceMeters += distanceToAdd;
      } else {
        _currentPosition = nextPoint;
      }

      if (_isManuallyPaused) {
        _statusMessage = 'Paused. Tap Resume to continue.';
      } else if (_isAutoPaused) {
        _statusMessage =
            'Auto-paused (speed under ${_autoPauseSpeedThreshold.toStringAsFixed(1)} m/s).';
      } else if (clearStatus) {
        _statusMessage = null;
      }
    });

    _mapController.move(nextPoint, 17);
    _notifyMetricsChangedIfNeeded();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDistanceMeters(double meters) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(2)} km';
  }

  String _modeLabel(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
        return 'Running';
      case WorkoutMode.outdoorWalking:
        return 'Outdoor Walking';
      case WorkoutMode.cycling:
        return 'Cycling';
    }
  }

  IconData _modeIcon(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
        return Icons.directions_run_rounded;
      case WorkoutMode.outdoorWalking:
        return Icons.directions_walk_rounded;
      case WorkoutMode.cycling:
        return Icons.directions_bike_rounded;
    }
  }

  String _modeSubtitle(WorkoutMode mode) {
    switch (mode) {
      case WorkoutMode.running:
        return 'Track route, speed, calories, and active time for your run.';
      case WorkoutMode.outdoorWalking:
        return 'Track your outdoor walk with live GPS route and pace stats.';
      case WorkoutMode.cycling:
        return 'Track your cycling route with live GPS speed and calorie stats.';
    }
  }

  Future<void> _openMode(WorkoutMode mode) async {
    _resetRoute();
    setState(() {
      _selectedMode = mode;
      _showMetricsFullscreen = false;
    });
    await _primeLiveLocation(
      loadingMessage: 'Getting your live location for ${_modeLabel(mode)}...',
    );
  }

  void _backToModeSelection() {
    _resetRoute();
    setState(() {
      _selectedMode = null;
      _showMetricsFullscreen = false;
    });
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
    final displayedDistance = _formatDistanceMeters(_totalDistanceMeters);
    final displayedDuration = _formatDuration(_elapsed);
    final displayedCalories = _estimatedCalories;
    final initialTarget =
        _currentPosition ??
        (_routePoints.isNotEmpty ? _routePoints.last : _defaultStart);
    final mapMarkers = _currentPosition == null
        ? const <Marker>[]
        : <Marker>[
            Marker(
              point: _currentPosition!,
              width: 44,
              height: 44,
              child: Icon(
                Icons.my_location,
                color: isDark ? Colors.lightBlueAccent : Colors.blueAccent,
                size: 30,
              ),
            ),
          ];
    final mapPolylines = _routePoints.length < 2
        ? const <Polyline>[]
        : <Polyline>[
            Polyline(
              points: List<LatLng>.from(_routePoints),
              strokeWidth: 5,
              color: Colors.blueAccent,
            ),
          ];

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
                  Text(
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
                            bottom: safePadding.bottom + 180,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(height: 24),
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
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 20),
                              Text(
                                _speedText,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: isNarrowLayout ? 40 : 48,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Helvetica',
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'Speed',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                              const SizedBox(height: 20),
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
                            ],
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialTarget,
                            initialZoom: _currentPosition == null ? 13 : 17,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.synthese',
                            ),
                            PolylineLayer(polylines: mapPolylines),
                            MarkerLayer(markers: mapMarkers),
                          ],
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
                      IconButton.filledTonal(
                        onPressed: () {
                          setState(() {
                            _hideTrackingUi = !_hideTrackingUi;
                          });
                        },
                        icon: Icon(
                          _hideTrackingUi
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
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
                if (!_isCountdownActive && !_hideTrackingUi)
                  Positioned(
                    left: isNarrowLayout ? 12 : 16,
                    right: isNarrowLayout ? 12 : 16,
                    bottom: safePadding.bottom + 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_showMetricsFullscreen) ...[
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
                                            'Speed',
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
                                            _speedText,
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
                                      _routePoints.isEmpty && !_isTracking
                                      ? null
                                      : _resetRoute,
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
