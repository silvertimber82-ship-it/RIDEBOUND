
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../gear/screens/trip_gear_screen.dart';

import '../models/trip.dart';
import '../repositories/trip_repository.dart';
import 'add_trip_screen.dart';
import 'trip_journal_screen.dart';



class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  Future<void> _editTrip() async {
    final updatedTrip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTripScreen(trip: _trip),
      ),
    );

    if (updatedTrip == null || !mounted) return;

    await context.read<TripRepository>().updateTrip(updatedTrip);

    if (!mounted) return;

    setState(() {
      _trip = updatedTrip;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip updated successfully')),
    );
  }
  Future<void> _openJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripJournalScreen(trip: _trip),
      ),
    );

    if (!mounted) return;

    final repository = context.read<TripRepository>();

    final updatedTrip = repository.trips.firstWhere(
          (trip) => trip.id == _trip.id,
    );

    setState(() {
      _trip = updatedTrip;
    });
  }

  Future<void> _toggleFavorite() async {
    final updatedTrip = _trip.copyWith(
      isFavorite: !_trip.isFavorite,
    );

    await context.read<TripRepository>().updateTrip(updatedTrip);

    if (!mounted) return;

    setState(() {
      _trip = updatedTrip;
    });
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: Text(
          'Are you sure you want to delete "${_trip.name}"? '
              'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<TripRepository>().deleteTrip(_trip.id);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(
            tooltip: 'Trip Gear Checklist',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripGearScreen(trip: _trip),
                ),
              );
            },
            icon: const Icon(Icons.backpack_outlined),
          ),
          IconButton(
            tooltip: 'Trip Journal',
            onPressed: _openJournal,
            icon: const Icon(Icons.menu_book),
          ),
          IconButton(
            tooltip: _trip.isFavorite
                ? 'Remove Favorite'
                : 'Add Favorite',
            onPressed: _toggleFavorite,
            icon: Icon(
              _trip.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _trip.isFavorite ? Colors.red : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit Trip',
            onPressed: _editTrip,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Delete Trip',
            onPressed: _deleteTrip,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _trip.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Created ${_trip.createdDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 28),

// Recorded GPS route
            _TripRouteMap(trip: _trip),

            const SizedBox(height: 28),

// Trip dates
            _DetailCard(
              icon: Icons.calendar_month,
              title: 'Trip Dates',
              value: _trip.startDate == null && _trip.endDate == null
                  ? 'Not recorded'
                  : '${_trip.startDate == null ? 'Not set' : MaterialLocalizations.of(context).formatMediumDate(_trip.startDate!)}'
                  ' - '
                  '${_trip.endDate == null ? 'Not set' : MaterialLocalizations.of(context).formatMediumDate(_trip.endDate!)}',
            ),

            const SizedBox(height: 14),

// Total trip distance
            _DetailCard(
              icon: Icons.speed,
              title: 'Distance Traveled',
              value: '${_trip.distanceMiles.toStringAsFixed(1)} miles',
            ),

            const SizedBox(height: 14),

// Odometer readings
            if (_trip.startOdometer != null)
              _DetailCard(
                icon: Icons.directions_bike,
                title: 'Starting Odometer',
                value: '${_trip.startOdometer!.toStringAsFixed(1)} miles',
              ),

            if (_trip.startOdometer != null && _trip.endOdometer != null)
              const SizedBox(height: 14),

            if (_trip.endOdometer != null)
              _DetailCard(
                icon: Icons.speed,
                title: 'Ending Odometer',
                value: '${_trip.endOdometer!.toStringAsFixed(1)} miles',
              ),


            const SizedBox(height: 14),

            _DetailCard(
              icon: Icons.trip_origin,
              title: 'Starting Location',
              value: _trip.startLocation,
            ),

            const SizedBox(height: 14),

            _DetailCard(
              icon: Icons.location_on,
              title: 'Destination',
              value: _trip.endLocation,
            ),

            const SizedBox(height: 14),

            _DetailCard(
              icon: Icons.favorite,
              title: 'Favorite',
              value: _trip.isFavorite ? 'Yes' : 'No',
            ),

            const SizedBox(height: 24),

            Text(
              'Trip Notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                _trip.notes.isEmpty
                    ? 'No notes added for this trip.'
                    : _trip.notes,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRouteMap extends StatefulWidget {
  final Trip trip;

  const _TripRouteMap({required this.trip});

  @override
  State<_TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<_TripRouteMap> {
  final MapController _mapController = MapController();

  List<LatLng> get _points => widget.trip.routePoints
      .map((point) => LatLng(point.latitude, point.longitude))
      .toList();

  void _fitRoute() {
    if (_points.isEmpty) return;

    if (_points.length == 1) {
      _mapController.move(_points.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(_points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;

    if (points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.map_outlined, size: 42),
              const SizedBox(height: 10),
              const Text('No GPS route recorded'),
              const SizedBox(height: 4),
              Text(
                'This trip does not contain a recorded GPS route.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recorded Route',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 13,
                onMapReady: _fitRoute,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ridebound',
                ),
                if (points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 5,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 38,
                      ),
                    ),
                    if (points.length > 1)
                      Marker(
                        point: points.last,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 34,
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${points.length} GPS points recorded',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
