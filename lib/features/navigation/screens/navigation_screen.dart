
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../route_planner/models/planned_route.dart';

class NavigationScreen extends StatefulWidget {
  final PlannedRoute route;

  const NavigationScreen({
    super.key,
    required this.route,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;
  bool _mapReady = false;
  bool _isLoading = true;
  String? _locationError;
  double _speedMph = 0;
  int _nearestRouteIndex = 0;

  List<LatLng> get _routePoints => widget.route.routePoints;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please turn on your phone GPS.');
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'RideBound needs location permission for navigation.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );

      if (!mounted) return;

      _updatePosition(position);

      final settings = defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
      )
          : const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _updatePosition,
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _locationError = 'GPS error: $error';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _locationError = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updatePosition(Position position) {
    final location = LatLng(
      position.latitude,
      position.longitude,
    );

    _nearestRouteIndex = _findNearestRouteIndex(location);

    if (!mounted) return;

    setState(() {
      _currentLocation = location;
      _speedMph = position.speed * 2.23694;
    });

    if (_mapReady) {
      _mapController.move(location, 16);
    }
  }

  int _findNearestRouteIndex(LatLng location) {
    if (_routePoints.isEmpty) return 0;

    int nearestIndex = 0;
    double shortestDistance = double.infinity;

    for (int i = 0; i < _routePoints.length; i++) {
      final point = _routePoints[i];

      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  int? get _nextInstructionIndex {
    for (int i = 0; i < widget.route.instructions.length; i++) {
      final instruction = widget.route.instructions[i];

      if (instruction.beginShapeIndex > _nearestRouteIndex) {
        return i;
      }
    }

    return null;
  }

  double? get _distanceToNextInstruction {
    final instructionIndex = _nextInstructionIndex;

    if (instructionIndex == null || _routePoints.isEmpty) {
      return null;
    }

    final targetIndex = widget.route.instructions[instructionIndex]
        .beginShapeIndex
        .clamp(0, _routePoints.length - 1)
        .toInt();

    double distance = 0;

    for (int i = _nearestRouteIndex; i < targetIndex; i++) {
      final start = _routePoints[i];
      final end = _routePoints[i + 1];

      distance += Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
    }

    return distance;
  }

  String _formatTurnDistance(double? meters) {
    if (meters == null) return 'Destination ahead';

    if (meters >= 1609.344) {
      return '${(meters / 1609.344).toStringAsFixed(1)} mi';
    }

    return '${meters.round()} m';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instructionIndex = _nextInstructionIndex;

    final instruction = instructionIndex == null
        ? null
        : widget.route.instructions[instructionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('RideBound Navigation'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty
                  ? _routePoints.first
                  : const LatLng(39.8283, -98.5795),
              initialZoom: 14,
              maxZoom: 18,
              onMapReady: () {
                _mapReady = true;

                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ridebound',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6,
                      color: Colors.orange,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.blue,
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

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.turn_right,
                          size: 34,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            instruction?.instruction ??
                                'Continue to destination',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTurnDistance(
                        _distanceToNextInstruction,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavigationStat(
                      label: 'SPEED',
                      value: '${_speedMph.round()} mph',
                    ),
                    _NavigationStat(
                      label: 'ROUTE',
                      value: widget.route.formattedDistance,
                    ),
                    _NavigationStat(
                      label: 'EST. TIME',
                      value: widget.route.formattedDuration,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          if (_locationError != null)
            Positioned(
              left: 12,
              right: 12,
              top: 100,
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_locationError!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationStat extends StatelessWidget {
  final String label;
  final String value;

  const _NavigationStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
