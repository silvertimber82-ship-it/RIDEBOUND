import 'package:flutter/material.dart';
import '../models/trip.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveTrip() {
    if (!_formKey.currentState!.validate()) return;

    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      startLocation: _startController.text.trim(),
      endLocation: _endController.text.trim(),
      notes: _notesController.text.trim(),
      createdDate: DateTime.now(),
    );

    Navigator.pop(context, trip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip'),
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

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTrip,
                    child: const Text('Save Trip'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}