
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/planned_route.dart';
import '../../navigation/models/navigation_instruction.dart';

class RoutePlanningService {
  static const String _baseUrl =
      'https://valhalla1.openstreetmap.de';

  final http.Client _client;

  RoutePlanningService({http.Client? client})
      : _client = client ?? http.Client();

  Future<PlannedRoute> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    double useHighways = 0.35,
    double useTrails = 0.0,
  }) async {
    final uri = Uri.parse('$_baseUrl/route');

    final requestBody = {
      'locations': [
        {
          'lat': origin.latitude,
          'lon': origin.longitude,
          'type': 'break',
        },
        {
          'lat': destination.latitude,
          'lon': destination.longitude,
          'type': 'break',
        },
      ],
      'costing': 'motorcycle',
      'costing_options': {
        'motorcycle': {
          'use_highways': useHighways,
          'use_trails': useTrails,
        },
      },
      'units': 'miles',
      'language': 'en-US',
      'directions_type': 'instructions',
      'shape_format': 'polyline6',
    };

    try {
      final response = await _client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Valhalla request failed (${response.statusCode}): '
              '${response.body}',
        );
      }

      final Map<String, dynamic> responseData =
      jsonDecode(response.body) as Map<String, dynamic>;

      final trip = responseData['trip'] as Map<String, dynamic>?;

      if (trip == null) {
        throw Exception('Valhalla returned no trip data.');
      }

      final summary =
      trip['summary'] as Map<String, dynamic>?;

      if (summary == null) {
        throw Exception('Valhalla returned no route summary.');
      }

      final legs = trip['legs'] as List<dynamic>?;

      if (legs == null || legs.isEmpty) {
        throw Exception('Valhalla returned no route legs.');
      }

      final List<LatLng> routePoints = [];
      final List<NavigationInstruction> instructions = [];

      for (final legData in legs) {
        final leg = legData as Map<String, dynamic>;

        final encodedShape = leg['shape'] as String?;

        if (encodedShape == null || encodedShape.isEmpty) {
          throw Exception('Route leg is missing its shape.');
        }

        routePoints.addAll(_decodePolyline6(encodedShape));

        final maneuvers =
            leg['maneuvers'] as List<dynamic>? ?? [];

        for (final maneuverData in maneuvers) {
          final maneuver =
          maneuverData as Map<String, dynamic>;

          final instruction =
              maneuver['instruction'] as String? ?? '';

          final verbalInstruction =
              maneuver['verbal_pre_transition_instruction']
              as String? ??
                  maneuver['verbal_transition_alert_instruction']
                  as String? ??
                  instruction;

          instructions.add(
            NavigationInstruction(
              type: (maneuver['type'] as num?)?.toInt() ?? 0,
              instruction: instruction,
              verbalInstruction: verbalInstruction,
              distanceMeters:
              ((maneuver['length'] as num?)?.toDouble() ?? 0) *
                  1609.344,
              durationSeconds:
              (maneuver['time'] as num?)?.toDouble() ?? 0,
              beginShapeIndex:
              (maneuver['begin_shape_index'] as num?)
                  ?.toInt() ??
                  0,
              endShapeIndex:
              (maneuver['end_shape_index'] as num?)
                  ?.toInt() ??
                  0,
            ),
          );
        }
      }

      if (routePoints.isEmpty) {
        throw Exception('Valhalla returned an empty route.');
      }

      return PlannedRoute(
        routePoints: routePoints,
        instructions: instructions,
        distanceMiles:
        (summary['length'] as num).toDouble(),
        durationSeconds:
        (summary['time'] as num).toDouble(),
      );
    } catch (error) {
      debugPrint('Route calculation error: $error');
      rethrow;
    }
  }

  List<LatLng> _decodePolyline6(String encoded) {
    final points = <LatLng>[];

    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;

      do {
        if (index >= encoded.length) {
          throw const FormatException(
            'Invalid encoded route geometry.',
          );
        }

        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLatitude = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);

      latitude += deltaLatitude;

      result = 0;
      shift = 0;

      do {
        if (index >= encoded.length) {
          throw const FormatException(
            'Invalid encoded route geometry.',
          );
        }

        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLongitude = (result & 1) != 0
          ? ~(result >> 1)
          : (result >> 1);

      longitude += deltaLongitude;

      points.add(
        LatLng(
          latitude / 1000000.0,
          longitude / 1000000.0,
        ),
      );
    }

    return points;
  }

  void dispose() {
    _client.close();
  }
}
