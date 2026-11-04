import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../domain/entities/waypoint.dart';

/// Repository responsible for fetching direction data.
/// 
/// In Phase 3, this has been updated to point to the local Python Backend
/// instead of calling Google Maps API directly.
class DirectionsRepository {
  // Python Backend URL (Phase 3)
  static const String _backendUrl = 'http://127.0.0.1:8080/api/calculate_itinerary';

  final http.Client _httpClient;

  DirectionsRepository({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Fetches the optimized itinerary from the backend.
  /// 
  /// Sends the list of [waypoints] to the Python engine, which returns:
  /// - Adjusted segments
  /// - Total time/distance
  /// - AI Smart Suggestions (warnings)
  Future<Map<String, dynamic>> getDirections({
    required List<Waypoint> waypoints,
  }) async {
    // If fewer than 2 waypoints, return empty/zero state
    if (waypoints.length < 2) {
      return {
        'polylineCoordinates': <LatLng>[], 
        'totalDuration': '0 sec', 
        'totalDistance': '0 m', 
        'warnings': <String>[]
      };
    }

    // Construct Backend Request (JSON)
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      "session_id": "app_session_mvp",
      "waypoints": waypoints.map((w) => {
        "id": w.id,
        "name": w.name,
        "latitude": w.latitude,
        "longitude": w.longitude,
        "mode": w.mode
      }).toList(),
      "optimize_for": "time"
    });

    try {
      final response = await _httpClient.post(Uri.parse(_backendUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final String encodedPolyline = data['combined_polyline'] ?? "";
        final int totalDuration = data['total_duration_seconds'] ?? 0;
        final int totalDistance = data['total_distance_meters'] ?? 0;
        
        // Parse warnings safely
        final List<dynamic> warningsRaw = data['warnings'] ?? [];
        final List<String> warnings = warningsRaw.map((e) => e.toString()).toList();

        // Decode polyline strictly using the static method
        List<PointLatLng> points = [];
        if (encodedPolyline.isNotEmpty) {
           points = PolylinePoints.decodePolyline(encodedPolyline);
        }
        
        final polylineCoordinates = points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        return {
          'polylineCoordinates': polylineCoordinates,
          'totalDuration': _formatDuration(totalDuration),
          'totalDistance': _formatDistance(totalDistance),
          'warnings': warnings
        };
      } else {
        throw Exception('Backend Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Graceful fallback or rethrow
      // print('Error fetching directions: $e'); // removed for clean test output
      throw Exception('Failed to fetch directions: $e');
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds sec';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
