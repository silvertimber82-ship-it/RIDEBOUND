
import 'package:hive/hive.dart';

part 'gear_item.g.dart';

@HiveType(typeId: 3)
class GearItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  // Keep this flexible so you can create your own categories.
  @HiveField(2)
  final String category;

  // Store weight in grams. Null means no weight has been entered.
  @HiveField(3)
  final int? weightGrams;

  @HiveField(4)
  final String? defaultPackingLocation;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final DateTime createdAt;

  const GearItem({
    required this.id,
    required this.name,
    required this.category,
    this.weightGrams,
    this.defaultPackingLocation,
    this.notes = '',
    required this.createdAt,
  });

  static const String categoryRiding = 'Riding Gear';
  static const String categoryMotorcycle = 'Motorcycle';
  static const String categoryCamping = 'Camping Gear';
  static const String categoryPersonal = 'Personal Gear';

  static const String locationSaddlebags = 'Saddlebags';
  static const String locationTourPack = 'Tour Pack';
  static const String locationBackpack = 'Backpack';
  static const String locationTankBag = 'Tank Bag';
  static const String locationWorn = 'Worn';
  static const String locationOther = 'Other';
}
