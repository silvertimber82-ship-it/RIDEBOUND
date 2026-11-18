
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/gear_item.dart';
import '../models/trip_gear.dart';

class GearRepository extends ChangeNotifier {
  GearRepository._(this._gearBox, this._tripGearBox);

  static late final GearRepository instance;

  final Box<GearItem> _gearBox;
  final Box<TripGearItem> _tripGearBox;

  static Future<void> initialize() async {
    final gearBox = await Hive.openBox<GearItem>('gear_items');
    final tripGearBox =
    await Hive.openBox<TripGearItem>('trip_gear_items');

    instance = GearRepository._(gearBox, tripGearBox);
  }

  // Creates a unique ID for new gear entries.
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // MASTER GEAR INVENTORY

  List<GearItem> get gearItems =>
      List.unmodifiable(_gearBox.values);

  int get gearCount => _gearBox.length;

  List<GearItem> getGearByCategory(String category) {
    return _gearBox.values
        .where((item) => item.category == category)
        .toList();
  }

  Future<void> addGearItem(GearItem item) async {
    await _gearBox.put(item.id, item);
    notifyListeners();
  }

  Future<void> updateGearItem(GearItem item) async {
    if (_gearBox.containsKey(item.id)) {
      await _gearBox.put(item.id, item);
      notifyListeners();
    }
  }

  Future<void> deleteGearItem(String gearId) async {
    await _gearBox.delete(gearId);
    notifyListeners();
  }

  // INDIVIDUAL TRIP CHECKLISTS

  List<TripGearItem> getTripGear(String tripId) {
    final items = _tripGearBox.values
        .where((item) => item.tripId == tripId)
        .toList();

    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return items;
  }

  int getPackedCount(String tripId) {
    return getTripGear(tripId)
        .where((item) => item.isPacked)
        .length;
  }

  int getTripGearCount(String tripId) {
    return getTripGear(tripId).length;
  }

  double getPackingProgress(String tripId) {
    final items = getTripGear(tripId);

    if (items.isEmpty) return 0;

    final packedCount = items.where((item) => item.isPacked).length;

    return packedCount / items.length;
  }

  Future<void> addTripGearItem(TripGearItem item) async {
    await _tripGearBox.put(item.id, item);
    notifyListeners();
  }

  // Copies a master inventory item into a trip checklist.
  // Changes to the trip copy will not affect the master item.
  Future<void> addMasterItemToTrip(
      GearItem gearItem,
      String tripId,
      ) async {
    final existingItems = getTripGear(tripId);

    // Prevent adding the same master item twice to one trip.
    final alreadyAdded = existingItems.any(
          (item) => item.sourceGearItemId == gearItem.id,
    );

    if (alreadyAdded) return;

    final tripItem = TripGearItem(
      id: generateId(),
      tripId: tripId,
      sourceGearItemId: gearItem.id,
      name: gearItem.name,
      category: gearItem.category,
      weightGrams: gearItem.weightGrams,
      packingLocation: gearItem.defaultPackingLocation,
      notes: gearItem.notes,
      sortOrder: existingItems.length,
    );

    await _tripGearBox.put(tripItem.id, tripItem);
    notifyListeners();
  }

  Future<void> updateTripGearItem(TripGearItem item) async {
    if (_tripGearBox.containsKey(item.id)) {
      await _tripGearBox.put(item.id, item);
      notifyListeners();
    }
  }

  Future<void> togglePacked(String itemId) async {
    final item = _tripGearBox.get(itemId);

    if (item == null) return;

    final updatedItem = item.copyWith(
      isPacked: !item.isPacked,
    );

    await _tripGearBox.put(itemId, updatedItem);
    notifyListeners();
  }

  Future<void> deleteTripGearItem(String itemId) async {
    await _tripGearBox.delete(itemId);
    notifyListeners();
  }

  // Removes only the checklist for the selected trip.
  // The master inventory remains untouched.
  Future<void> clearTripChecklist(String tripId) async {
    final keysToDelete = _tripGearBox.keys.where((key) {
      return _tripGearBox.get(key)?.tripId == tripId;
    }).toList();

    await _tripGearBox.deleteAll(keysToDelete);
    notifyListeners();
  }
}
