
import 'package:hive/hive.dart';
import 'ride_route_point.dart';
import 'journal_entry.dart';

part 'trip.g.dart';

@HiveType(typeId: 0)
class Trip {
    @HiveField(0)
    final String id;

    @HiveField(1)
    final String name;

    @HiveField(2)
    final String startLocation;

    @HiveField(3)
    final String endLocation;

    @HiveField(4)
    final String notes;

    @HiveField(5)
    final DateTime createdDate;

    @HiveField(6)
    final bool isFavorite;

    // New trip journal fields
    @HiveField(7)
    final DateTime? startDate;

    @HiveField(8)
    final DateTime? endDate;

    @HiveField(9)
    final double manualDistanceMiles;

    @HiveField(10)
    final double? startOdometer;

    @HiveField(11)
    final double? endOdometer;

    @HiveField(12)
    final List<String> photoPaths;

    @HiveField(13)
    final List<JournalEntry> journalEntries;

    @HiveField(14)
    final List<RideRoutePoint> routePoints;

    @HiveField(15)
    final double recordedDistanceMiles;

    @HiveField(16)
    final int durationSeconds;

    @HiveField(17)
    final bool trackingCompleted;

    @HiveField(18)
    final String status;

    static const String statusPlanned = 'planned';
    static const String statusInProgress = 'inProgress';
    static const String statusCompleted = 'completed';

    const Trip({
        required this.id,
        required this.name,
        required this.startLocation,
        required this.endLocation,
        required this.notes,
        required this.createdDate,
        this.isFavorite = false,
        this.startDate,
        this.endDate,
        this.manualDistanceMiles = 0.0,
        this.startOdometer,
        this.endOdometer,
        this.photoPaths = const [],
        this.journalEntries = const [],
        this.routePoints = const [],
        this.recordedDistanceMiles = 0.0,
        this.durationSeconds = 0,
        this.trackingCompleted = false,
        this.status = statusPlanned,
    });

    // Prefer odometer mileage when both readings are available.
    // Otherwise, use manually entered mileage.
    double get distanceMiles {
        if (startOdometer != null &&
            endOdometer != null &&
            endOdometer! >= startOdometer!) {
            return endOdometer! - startOdometer!;
        }

        return manualDistanceMiles;
    }

    Trip copyWith({
        String? id,
        String? name,
        String? startLocation,
        String? endLocation,
        String? notes,
        DateTime? createdDate,
        bool? isFavorite,
        DateTime? startDate,
        DateTime? endDate,
        double? manualDistanceMiles,
        double? startOdometer,
        double? endOdometer,
        List<String>? photoPaths,
        List<JournalEntry>? journalEntries,
        List<RideRoutePoint>? routePoints,
        double? recordedDistanceMiles,
        int? durationSeconds,
        bool? trackingCompleted,
        String? status,
    }) {
        return Trip(
            id: id ?? this.id,
            name: name ?? this.name,
            startLocation: startLocation ?? this.startLocation,
            endLocation: endLocation ?? this.endLocation,
            notes: notes ?? this.notes,
            createdDate: createdDate ?? this.createdDate,
            isFavorite: isFavorite ?? this.isFavorite,
            startDate: startDate ?? this.startDate,
            endDate: endDate ?? this.endDate,
            manualDistanceMiles:
            manualDistanceMiles ?? this.manualDistanceMiles,
            startOdometer: startOdometer ?? this.startOdometer,
            endOdometer: endOdometer ?? this.endOdometer,
            photoPaths: photoPaths ?? this.photoPaths,
            journalEntries: journalEntries ?? this.journalEntries,
            routePoints: routePoints ?? this.routePoints,
            recordedDistanceMiles:
            recordedDistanceMiles ?? this.recordedDistanceMiles,
            durationSeconds: durationSeconds ?? this.durationSeconds,
            trackingCompleted: trackingCompleted ?? this.trackingCompleted,
            status: status ?? this.status,
        );
    }
}
