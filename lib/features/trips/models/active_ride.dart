
import 'package:hive/hive.dart';

import 'ride_route_point.dart';

part 'active_ride.g.dart';

@HiveType(typeId: 5)
class ActiveRide {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<RideRoutePoint> routePoints;

  @HiveField(2)
  final double distanceMeters;

  @HiveField(3)
  final int elapsedSeconds;

  @HiveField(4)
  final bool isPaused;

  @HiveField(5)
  final DateTime startedAt;

  @HiveField(6)
  final DateTime lastUpdated;

  const ActiveRide({
    required this.id,
    required this.routePoints,
    required this.distanceMeters,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.startedAt,
    required this.lastUpdated,
  });
}
