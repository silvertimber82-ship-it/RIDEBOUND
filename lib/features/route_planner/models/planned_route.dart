
import 'package:latlong2/latlong.dart';

import '../../navigation/models/navigation_instruction.dart';

class PlannedRoute {
  final List<LatLng> routePoints;
  final List<NavigationInstruction> instructions;
  final double distanceMiles;
  final double durationSeconds;

  const PlannedRoute({
    required this.routePoints,
    required this.instructions,
    required this.distanceMiles,
    required this.durationSeconds,
  });

  String get formattedDistance {
    return '${distanceMiles.toStringAsFixed(1)} miles';
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }
}
