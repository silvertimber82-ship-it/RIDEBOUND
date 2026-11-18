

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../trips/models/trip.dart';
import '../../trips/models/ride_route_point.dart';
import '../../trips/models/active_ride.dart';
import '../../trips/repositories/trip_repository.dart';
import '../../trips/screens/save_ride_screen.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver {

  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _elapsedTimer;
  Timer? _activeRideSaveTimer;

  DateTime? _rideStartedAt;


  LatLng? _currentLocation;
  final List<RideRoutePoint> _routePoints = [];

  bool _isLoadingLocation = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _mapReady = false;

  int _elapsedSeconds = 0;
  double _distanceMeters = 0;
  String? _locationMessage;

  static const LatLng _defaultCenter = LatLng(39.8283, -98.5795);

  double get _distanceMiles => _distanceMeters / 1609.344;
  Future<void> _saveActiveRide() async {
    if (!_isRecording || _routePoints.isEmpty) return;

    final ride = ActiveRide(
      id: 'active_ride',
      routePoints: List<RideRoutePoint>.from(_routePoints),
      distanceMeters: _distanceMeters,
      elapsedSeconds: _elapsedSeconds,
      isPaused: _isPaused,
      startedAt: _rideStartedAt ?? DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await context.read<TripRepository>().saveActiveRide(ride);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (_isRecording) {
        unawaited(_saveActiveRide());
      }
    }
  }

  void _startActiveRideSaveTimer() {
    _activeRideSaveTimer?.cancel();

    _activeRideSaveTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        _saveActiveRide();
      },
    );
  }

  Future<void> _stopActiveRideSaveTimer() async {
    _activeRideSaveTimer?.cancel();
    _activeRideSaveTimer = null;

    await _saveActiveRide();
  }

  String get _formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  Future<void> _checkForActiveRide() async {
    final repository = context.read<TripRepository>();
    final savedRide = repository.activeRide;

    if (savedRide == null || !mounted) return;

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unfinished Ride Found'),
          content: Text(
            'RideBound found an unfinished ride.\n\n'
                'Distance: '
                '${(savedRide.distanceMeters / 1609.344).toStringAsFixed(2)} miles\n'
                'GPS points: ${savedRide.routePoints.length}\n\n'
                'Would you like to resume this ride or discard it?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, null);
              },
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Resume Ride'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (choice == false) {
      await repository.clearActiveRide();
      return;
    }

    if (choice == true) {
      setState(() {
        _routePoints
          ..clear()
          ..addAll(savedRide.routePoints);

        _distanceMeters = savedRide.distanceMeters;
        _elapsedSeconds = savedRide.elapsedSeconds;
        _rideStartedAt = savedRide.startedAt;

        _isRecording = true;
        _isPaused = true;

        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;

          _currentLocation = LatLng(
            lastPoint.latitude,
            lastPoint.longitude,
          );
        }
      });

      if (_mapReady && _currentLocation != null) {
        _mapController.move(_currentLocation!, 16);
      }
    }
  }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _locateUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForActiveRide();
    });
  }


  Future<bool> _checkLocationPermission() async {
    final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are turned off. Please enable GPS.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'RideBound needs precise location permission to record your ride.',
      );
    }

    if (permission != LocationPermission.always) {
      throw Exception(
        'To record rides while your screen is locked, '
            'open Android Settings > Apps > RideBound > Permissions > Location '
            'and select Allow all the time. Also enable Use precise location.',
      );
    }

    return true;
  }


  Future<void> _locateUser() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
      _locationMessage = null;
    });

    try {
      await _checkLocationPermission();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentLocation = location;
      });

      if (_mapReady) {
        _mapController.move(location, 15);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _startRide() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
      _locationMessage = null;
    });

    try {
      await _checkLocationPermission();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final startingPoint = LatLng(
        position.latitude,
        position.longitude,
      );

      final startingRoutePoint = RideRoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
      );

      setState(() {
        _currentLocation = startingPoint;
        _routePoints
          ..clear()
          ..add(startingRoutePoint);
        _distanceMeters = 0;
        _elapsedSeconds = 0;
        _rideStartedAt = DateTime.now();
        _isRecording = true;
        _isPaused = false;
      });

      if (_mapReady) {
        _mapController.move(startingPoint, 16);
      }

      _startElapsedTimer();
      _subscribeToLocation();

      await _saveActiveRide();
      _startActiveRideSaveTimer();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationMessage = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }


  void _subscribeToLocation() {
    _positionSubscription?.cancel();

    final LocationSettings locationSettings =
    defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig:
      const ForegroundNotificationConfig(
        notificationTitle: 'RideBound',
        notificationText: 'Your ride is being recorded.',
        notificationChannelName: 'Ride Tracking',
        setOngoing: true,
        enableWakeLock: false,
      ),
    )
        : const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (position) {
        if (!mounted || !_isRecording || _isPaused) return;

        final newPoint = LatLng(
          position.latitude,
          position.longitude,
        );

        final newRoutePoint = RideRoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        );

        setState(() {
          if (_routePoints.isNotEmpty) {
            final previousPoint = _routePoints.last;

            final segmentDistance = Geolocator.distanceBetween(
              previousPoint.latitude,
              previousPoint.longitude,
              newRoutePoint.latitude,
              newRoutePoint.longitude,
            );

            // Ignore GPS jumps that are likely inaccurate.
            if (segmentDistance > 0 && segmentDistance < 500) {
              _distanceMeters += segmentDistance;
              _routePoints.add(newRoutePoint);
            }
          } else {
            _routePoints.add(newRoutePoint);
          }

          _currentLocation = newPoint;
        });

        if (_mapReady) {
          _mapController.move(newPoint, 16);
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _locationMessage = 'GPS tracking error: $error';
        });
      },
    );
  }


  void _startElapsedTimer() {
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted || !_isRecording || _isPaused) return;

        setState(() {
          _elapsedSeconds++;
        });
      },
    );
  }

  Future<void> _pauseRide() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    if (!mounted) return;

    setState(() {
      _isPaused = true;
    });

    await _stopActiveRideSaveTimer();

  }

  void _resumeRide() {
    setState(() {
      _isPaused = false;
    });

    _startElapsedTimer();
    _subscribeToLocation();

    _saveActiveRide();
    _startActiveRideSaveTimer();
  }


  Future<void> _stopRide() async {
    await _stopActiveRideSaveTimer();

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    debugPrint('RIDEBOUND: Opening Save Ride screen');

    try {
      final result = await Navigator.of(context).push<Object>(
        MaterialPageRoute(
          builder: (_) => SaveRideScreen(
            routePoints: List<RideRoutePoint>.unmodifiable(_routePoints),
            distanceMiles: _distanceMiles,
            durationSeconds: _elapsedSeconds,
          ),
        ),
      );

      debugPrint('RIDEBOUND: Save screen returned: $result');

      if (!mounted) return;

      // OPTION 1: Cancel - preserve the unfinished ride for later.
      if (result == null) {
        setState(() {
          _isRecording = true;
          _isPaused = true;
        });

        await _saveActiveRide();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ride is saved temporarily and available to resume.',
            ),
          ),
        );

        return;
      }

      // OPTION 2: Discard - clear the persisted active ride and route data.
      if (result == SaveRideAction.discarded) {
        await context.read<TripRepository>().clearActiveRide();

        if (!mounted) return;

        setState(() {
          _routePoints.clear();
          _distanceMeters = 0;
          _elapsedSeconds = 0;
          _rideStartedAt = null;
          _isRecording = false;
          _isPaused = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride discarded successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      // OPTION 3: Save - add the completed ride to the repository.
      if (result is Trip) {
        final repository = context.read<TripRepository>();

        await repository.addTrip(result);

        await repository.clearActiveRide();

        if (!mounted) return;

        setState(() {
          _routePoints.clear();
          _distanceMeters = 0;
          _elapsedSeconds = 0;
          _rideStartedAt = null;
          _isRecording = false;
          _isPaused = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('RIDEBOUND SAVE ERROR: $error');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving ride: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }


  Future<void> _openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _positionSubscription?.cancel();
    _elapsedTimer?.cancel();
    _activeRideSaveTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RideBound Maps'),
        actions: [
          IconButton(
            onPressed: _isLoadingLocation ? null : _locateUser,
            tooltip: 'Find my location',
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultCenter,
              initialZoom: 5,
              maxZoom: 18,
              onMapReady: () {
                _mapReady = true;

                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 15);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ridebound',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints
                          .map((point) => LatLng(point.latitude, point.longitude))
                          .toList(),
                      strokeWidth: 5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),

          if (_isLoadingLocation)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Finding your location...'),
                    ],
                  ),
                ),
              ),
            ),

          if (_locationMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_locationMessage!),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _locateUser,
                            child: const Text('Try again'),
                          ),
                          if (_locationMessage!.contains('blocked'))
                            TextButton(
                              onPressed: _openLocationSettings,
                              child: const Text('App settings'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildRideControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildRideControls() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isPaused ? Icons.pause_circle : Icons.circle,
                        color: _isPaused ? Colors.orange : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPaused ? 'RIDE PAUSED' : 'RECORDING RIDE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formattedTime,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      'Distance',
                      '${_distanceMiles.toStringAsFixed(2)} mi',
                      Icons.route,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      'GPS points',
                      _routePoints.length.toString(),
                      Icons.location_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPaused ? _resumeRide : _pauseRide,
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                      ),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _stopRide,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Ride'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to ride?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Start GPS ride tracking'),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isLoadingLocation ? null : _startRide,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Ride'),
                  ),
                ],
              ),
              if (_routePoints.length > 1) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last recorded route',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${_distanceMiles.toStringAsFixed(2)} mi • $_formattedTime',
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
