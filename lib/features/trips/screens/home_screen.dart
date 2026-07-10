import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'add_trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Trip> trips = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RideBound'),
      ),
      body: trips.isEmpty
          ? const Center(child: Text('No trips yet. Tap + to add one.'))
          : ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                trip.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${trip.startLocation} → ${trip.endLocation}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final newTrip = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddTripScreen(),
              ),
            );

            if (newTrip != null) {
              setState(() {
                trips.add(newTrip);
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Trip'),
        ),


        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );


  }
}