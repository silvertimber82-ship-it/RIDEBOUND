
import 'package:flutter/material.dart';

import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? trip;
  final DateTime? initialStartDate;

  const AddTripScreen({
    super.key,
    this.trip,
    this.initialStartDate,
  });

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _notesController = TextEditingController();

  final _manualDistanceController = TextEditingController();
  final _startOdometerController = TextEditingController();
  final _endOdometerController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _status = Trip.statusPlanned;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;

    if (trip != null) {
      _nameController.text = trip.name;
      _startController.text = trip.startLocation;
      _endController.text = trip.endLocation;
      _notesController.text = trip.notes;

      _startDate = trip.startDate;
      _endDate = trip.endDate;
      _status = trip.status;

      _manualDistanceController.text =
          trip.manualDistanceMiles.toString();

      _startOdometerController.text =
          trip.startOdometer?.toString() ?? '';

      _endOdometerController.text =
          trip.endOdometer?.toString() ?? '';
    } else {
      _startDate = widget.initialStartDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    _manualDistanceController.dispose();
    _startOdometerController.dispose();
    _endOdometerController.dispose();
    super.dispose();
  }

  void _saveTrip() {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before the start date.'),
        ),
      );
      return;
    }

    final existingTrip = widget.trip;

    final manualDistance =
        double.tryParse(_manualDistanceController.text.trim()) ?? 0.0;

    final startOdometer =
    double.tryParse(_startOdometerController.text.trim());

    final endOdometer =
    double.tryParse(_endOdometerController.text.trim());

    final trip = Trip(
      id: existingTrip?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      startLocation: _startController.text.trim(),
      endLocation: _endController.text.trim(),
      notes: _notesController.text.trim(),
      createdDate: existingTrip?.createdDate ?? DateTime.now(),
      isFavorite: existingTrip?.isFavorite ?? false,

      startDate: _startDate,
      endDate: _endDate,

      manualDistanceMiles: manualDistance,
      startOdometer: startOdometer,
      endOdometer: endOdometer,

      photoPaths: existingTrip?.photoPaths ?? [],
      journalEntries: existingTrip?.journalEntries ?? [],
      routePoints: existingTrip?.routePoints ?? [],
      recordedDistanceMiles:
      existingTrip?.recordedDistanceMiles ?? 0.0,
      durationSeconds: existingTrip?.durationSeconds ?? 0,
      trackingCompleted: existingTrip?.trackingCompleted ?? false,
      status: _status,
    );

    Navigator.pop(context, trip);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Trip' : 'Add Trip'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a trip name'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a start location'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Enter a destination'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),

                const SizedBox(height: 24),


                const Text(
                  'Trip Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: Trip.statusPlanned,
                      child: Text('Planned'),
                    ),
                    DropdownMenuItem(
                      value: Trip.statusInProgress,
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: Trip.statusCompleted,
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _status = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Trip Dates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    _startDate == null
                        ? 'Not selected'
                        : MaterialLocalizations.of(context).formatMediumDate(_startDate!),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: _endDate ?? DateTime(2100),
                    );

                    if (selectedDate != null) {
                      setState(() {
                        _startDate = selectedDate;
                        if (_endDate != null &&
                            _endDate!.isBefore(selectedDate)) {
                          _endDate = null;
                        }
                      });
                    }
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text(
                    _endDate == null
                        ? 'Not selected'
                        : MaterialLocalizations.of(context).formatMediumDate(_endDate!),
                  ),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (selectedDate != null) {
                      setState(() {
                        _endDate = selectedDate;
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Trip Mileage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _manualDistanceController,
                  decoration: const InputDecoration(
                    labelText: 'Manual Distance (miles)',
                    border: OutlineInputBorder(),
                    hintText: 'Example: 125.5',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final distance = double.tryParse(value.trim());

                    if (distance == null || distance < 0) {
                      return 'Enter a valid non-negative distance';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _startOdometerController,
                  decoration: const InputDecoration(
                    labelText: 'Starting Odometer (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Example: 24500',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final reading = double.tryParse(value.trim());

                    if (reading == null || reading < 0) {
                      return 'Enter a valid non-negative reading';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _endOdometerController,
                  decoration: const InputDecoration(
                    labelText: 'Ending Odometer (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Example: 24625',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;

                    final reading = double.tryParse(value.trim());

                    if (reading == null || reading < 0) {
                      return 'Enter a valid non-negative reading';
                    }

                    final startReading =
                    double.tryParse(_startOdometerController.text.trim());

                    if (startReading != null && reading < startReading) {
                      return 'Ending reading cannot be lower than starting reading';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTrip,
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Save Trip',
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

