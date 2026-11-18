
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/trip.dart';
import '../models/active_ride.dart';

class TripRepository extends ChangeNotifier {
  TripRepository._(this._box);

  static late final TripRepository instance;

  final Box<Trip> _box;

  static late Box<ActiveRide> _activeRideBox;

  static const String _activeRideKey = 'current';

  static Future<void> initialize() async {
    final box = await Hive.openBox<Trip>('trips');

    _activeRideBox =
    await Hive.openBox<ActiveRide>('activeRide');

    instance = TripRepository._(box);
  }

  List<Trip> get trips => List.unmodifiable(_box.values);

  int get tripCount => _box.length;

  int get favoriteCount =>
      _box.values.where((trip) => trip.isFavorite).length;

  ActiveRide? get activeRide =>
      _activeRideBox.get(_activeRideKey);

  Future<void> saveActiveRide(ActiveRide ride) async {
    await _activeRideBox.put(_activeRideKey, ride);
  }

  Future<void> clearActiveRide() async {
    await _activeRideBox.delete(_activeRideKey);
  }

  Future<void> addTrip(Trip trip) async {
    await _box.put(trip.id, trip);
    notifyListeners();
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    if (_box.containsKey(updatedTrip.id)) {
      await _box.put(updatedTrip.id, updatedTrip);
      notifyListeners();
    }
  }

  Future<void> deleteTrip(String tripId) async {
    await _box.delete(tripId);
    notifyListeners();
  }

  Future<void> clearTrips() async {
    await _box.clear();
    notifyListeners();
  }
}
