
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/planned_route.dart';
import '../../navigation/screens/navigation_screen.dart';

class RoutePreviewScreen extends StatefulWidget {
  final PlannedRoute route;
  final LatLng origin;
  final LatLng destination;

  const RoutePreviewScreen({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
  });

  @override
  State<RoutePreviewScreen> createState() =>
      _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  final MapController _mapController = MapController();

  bool _mapReady = false;

  void _fitRoute() {
    if (!_mapReady || widget.route.routePoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(
      widget.route.routePoints,
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
        actions: [
          IconButton(
            onPressed: _fitRoute,
            tooltip: 'Fit entire route',
            icon: const Icon(Icons.zoom_out_map),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.origin,
              initialZoom: 12,
              onMapReady: () {
                _mapReady = true;
                _fitRoute();
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
                  Polyline(
                    points: route.routePoints,
                    strokeWidth: 6,
                    color: Colors.orange,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.origin,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.trip_origin,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  Marker(
                    point: widget.destination,
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
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'DISTANCE',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              route.formattedDistance,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ESTIMATED TIME',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              route.formattedDuration,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NavigationScreen(
                                route: route,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Start Navigation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
