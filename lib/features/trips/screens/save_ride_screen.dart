import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../models/ride_route_point.dart';

enum SaveRideAction {
  discarded,
}

class SaveRideScreen extends StatefulWidget {
  final List<RideRoutePoint> routePoints;
  final double distanceMiles;
  final int durationSeconds;

  const SaveRideScreen({
    super.key,
    required this.routePoints,
    required this.distanceMiles,
    required this.durationSeconds,
  });

  @override
  State<SaveRideScreen> createState() => _SaveRideScreenState();
}

class _SaveRideScreenState extends State<SaveRideScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _notesController = TextEditingController();

  String get _formattedDistance =>
      '${widget.distanceMiles.toStringAsFixed(2)} miles';

  String get _formattedDuration {
    final hours = widget.durationSeconds ~/ 3600;
    final minutes = (widget.durationSeconds % 3600) ~/ 60;
    final seconds = widget.durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m ${seconds}s';
  }

  void _saveRide() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    final trip = Trip(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      startLocation: _startController.text.trim(),
      endLocation: _endController.text.trim(),
      notes: _notesController.text.trim(),
      createdDate: now,
      startDate: widget.routePoints.isNotEmpty
          ? widget.routePoints.first.timestamp
          : now,
      endDate: widget.routePoints.isNotEmpty
          ? widget.routePoints.last.timestamp
          : now,
      manualDistanceMiles: widget.distanceMiles,
      routePoints: List<RideRoutePoint>.unmodifiable(
        widget.routePoints,
      ),
      recordedDistanceMiles: widget.distanceMiles,
      durationSeconds: widget.durationSeconds,
      trackingCompleted: true,
    );

    Navigator.of(context).pop(trip);
  }
  Future<void> _discardRide() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Discard Ride?'),
          content: const Text(
            'This will permanently discard this unfinished ride. '
                'You will not be able to recover it.\n\n'
                'Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Keep Ride'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Discard Ride'),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop(SaveRideAction.discarded);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Ride'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.two_wheeler,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formattedDistance,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text('Distance traveled'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem(
                            'Duration',
                            _formattedDuration,
                            Icons.timer_outlined,
                          ),
                          _summaryItem(
                            'GPS Points',
                            widget.routePoints.length.toString(),
                            Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Ride Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ride Name',
                  hintText: 'Example: Sunday Country Ride',
                  prefixIcon: Icon(Icons.edit_road),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a ride name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _startController,
                decoration: const InputDecoration(
                  labelText: 'Starting Location',
                  hintText: 'Where did your ride begin?',
                  prefixIcon: Icon(Icons.trip_origin),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: 'Ending Location',
                  hintText: 'Where did your ride end?',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ride Notes',
                  hintText: 'Add details about your ride...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saveRide,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Ride'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: _discardRide,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Discard Ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(
      String label,
      String value,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 5),
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
