import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/trips/models/trip.dart';
import 'features/trips/models/journal_entry.dart';
import 'features/trips/repositories/trip_repository.dart';
import 'features/trips/models/ride_route_point.dart';
import 'features/trips/models/active_ride.dart';
import 'features/gear/models/gear_item.dart';
import 'features/gear/models/trip_gear.dart';
import 'features/gear/repositories/gear_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();

  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(RideRoutePointAdapter());
  Hive.registerAdapter(TripAdapter());
  Hive.registerAdapter(GearItemAdapter());
  Hive.registerAdapter(TripGearItemAdapter());
  Hive.registerAdapter(ActiveRideAdapter());
  await TripRepository.initialize();
  await GearRepository.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TripRepository>.value(
          value: TripRepository.instance,
        ),
        ChangeNotifierProvider<GearRepository>.value(
          value: GearRepository.instance,
        ),
      ],
      child: const RideBoundApp(),
    ),
  );
}