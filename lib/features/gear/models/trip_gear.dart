
import 'package:hive/hive.dart';

part 'trip_gear.g.dart';

@HiveType(typeId: 4)
class TripGearItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tripId;

  // Links back to the master inventory item, if applicable.
  @HiveField(2)
  final String? sourceGearItemId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final int? weightGrams;

  @HiveField(6)
  final String? packingLocation;

  @HiveField(7)
  final String notes;

  @HiveField(8)
  final bool isPacked;

  @HiveField(9)
  final int sortOrder;

  const TripGearItem({
    required this.id,
    required this.tripId,
    this.sourceGearItemId,
    required this.name,
    required this.category,
    this.weightGrams,
    this.packingLocation,
    this.notes = '',
    this.isPacked = false,
    this.sortOrder = 0,
  });

  TripGearItem copyWith({
    String? name,
    String? category,
    int? weightGrams,
    String? packingLocation,
    String? notes,
    bool? isPacked,
    int? sortOrder,
  }) {
    return TripGearItem(
      id: id,
      tripId: tripId,
      sourceGearItemId: sourceGearItemId,
      name: name ?? this.name,
      category: category ?? this.category,
      weightGrams: weightGrams ?? this.weightGrams,
      packingLocation: packingLocation ?? this.packingLocation,
      notes: notes ?? this.notes,
      isPacked: isPacked ?? this.isPacked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
