import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_service_app/features/route_engine/data/datasources/route_api_client.dart';
import 'package:google_service_app/features/route_engine/data/models/route_request.dart';
import 'package:google_service_app/features/route_engine/data/models/route_response.dart';

void main() {
  group('Integration Test - Backend Connection', () {
    late RouteApiClient client;

    setUp(() {
      final dio = Dio();
      // Use localhost for this script since it runs on the host machine, not emulator
      dio.options.baseUrl = 'http://localhost:8080/v1'; 
      client = RouteApiClient(dio: dio, organizationId: 'integration-test');
    });

    test('calculateRoute returns valid response from local backend', () async {
      // 1. Prepare Request
      final request = RouteRequest(
        mode: 'MAZE',
        waypoints: [
          const Waypoint(id: 'test-wp1', location: Location(lat: 25.033, lng: 121.565)),
          const Waypoint(id: 'test-wp2', location: Location(lat: 25.040, lng: 121.570)),
        ],
      );

      // 2. Call API
      try {
        final response = await client.calculateRoute(request);

        // 3. Verify Response
        print('✅ Received Response: ${response.routeId}');
        print('   Duration: ${response.totalDurationSeconds}s');
        print('   Distance: ${response.totalDistanceMeters}m');
        print('   Segments: ${response.segments.length}');

        if (response.warnings.isNotEmpty) {
          print('⚠️ Warnings: ${response.warnings}');
        }

        expect(response, isA<RouteResponse>());
        expect(response.segments.length, 1);
        expect(response.segments.first.fromId, 'test-wp1');
        
      } catch (e) {
        print('❌ Connection Failed: $e');
        if (e is DioException) {
          print('   Response: ${e.response?.data}');
        }
        fail('Failed to connect to backend. Is uvicorn running on port 8080?');
      }
    });
  });
}
