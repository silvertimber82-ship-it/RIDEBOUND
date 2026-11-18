
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/route_planning_service.dart';
import '../models/planned_route.dart';
import 'route_preview_screen.dart';

class RouteTestScreen extends StatefulWidget {
  const RouteTestScreen({super.key});

  @override
  State<RouteTestScreen> createState() => _RouteTestScreenState();
}

class _RouteTestScreenState extends State<RouteTestScreen> {
  final _originLatController =
  TextEditingController(text: '41.4048');
  final _originLonController =
  TextEditingController(text: '-81.7229');

  final _destinationLatController =
  TextEditingController(text: '41.4993');
  final _destinationLonController =
  TextEditingController(text: '-81.6944');

  final RoutePlanningService _routeService =
  RoutePlanningService();

  PlannedRoute? _route;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _calculateRoute() async {
    final originLat =
    double.tryParse(_originLatController.text.trim());
    final originLon =
    double.tryParse(_originLonController.text.trim());

    final destinationLat =
    double.tryParse(_destinationLatController.text.trim());
    final destinationLon =
    double.tryParse(_destinationLonController.text.trim());

    if (originLat == null ||
        originLon == null ||
        destinationLat == null ||
        destinationLon == null) {
      setState(() {
        _errorMessage = 'Please enter valid coordinates.';
        _route = null;
      });
      return;
    }

    if (originLat < -90 ||
        originLat > 90 ||
        destinationLat < -90 ||
        destinationLat > 90 ||
        originLon < -180 ||
        originLon > 180 ||
        destinationLon < -180 ||
        destinationLon > 180) {
      setState(() {
        _errorMessage = 'Coordinates are outside valid ranges.';
        _route = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _route = null;
    });

    try {
      final calculatedRoute =
      await _routeService.calculateRoute(
        origin: LatLng(originLat, originLon),
        destination: LatLng(destinationLat, destinationLon),
      );

      if (!mounted) return;

      setState(() {
        _route = calculatedRoute;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }
  void _openRoutePreview() {
    final route = _route;
    if (route == null) return;

    final origin = LatLng(
      double.parse(_originLatController.text.trim()),
      double.parse(_originLonController.text.trim()),
    );

    final destination = LatLng(
      double.parse(_destinationLatController.text.trim()),
      double.parse(_destinationLonController.text.trim()),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutePreviewScreen(
          route: route,
          origin: origin,
          destination: destination,
        ),
      ),
    );
  }
  Widget _buildCoordinateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRouteResults() {
    final route = _route!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          'Route Results',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance'),
                    Text(
                      route.formattedDistance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated travel time'),
                    Text(
                      route.formattedDuration,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Route points'),
                    Text('${route.routePoints.length}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Maneuvers'),
                    Text('${route.instructions.length}'),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Turn-by-turn Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (route.instructions.isEmpty)
          const Text('No maneuver instructions returned.'),

        ...route.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(
                instruction.instruction.isEmpty
                    ? 'Continue'
                    : instruction.instruction,
              ),
              subtitle: Text(
                '${(instruction.distanceMeters / 1609.344).toStringAsFixed(2)} miles',
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openRoutePreview,
            icon: const Icon(Icons.map),
            label: const Text('View Route on Map'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _originLatController.dispose();
    _originLonController.dispose();
    _destinationLatController.dispose();
    _destinationLonController.dispose();
    _routeService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Testing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Starting Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildCoordinateField(
                  label: 'Latitude',
                  controller: _originLatController,
                ),
                const SizedBox(width: 10),
                _buildCoordinateField(
                  label: 'Longitude',
                  controller: _originLonController,
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Destination',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildCoordinateField(
                  label: 'Latitude',
                  controller: _destinationLatController,
                ),
                const SizedBox(width: 10),
                _buildCoordinateField(
                  label: 'Longitude',
                  controller: _destinationLonController,
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _calculateRoute,
                icon: const Icon(Icons.motorcycle),
                label: const Text('Calculate Motorcycle Route'),
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const Center(
                child: Text('Calculating route...'),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],

            if (_route != null) _buildRouteResults(),
          ],
        ),
      ),
    );
  }
}
