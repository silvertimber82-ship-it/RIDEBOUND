import 'package:hive/hive.dart';

part 'ride_route_point.g.dart';

@HiveType(typeId: 2)
class RideRoutePoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  const RideRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}