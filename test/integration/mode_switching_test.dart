import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_service_app/features/route_engine/data/datasources/route_api_client.dart';
import 'package:google_service_app/features/route_engine/data/models/route_request.dart';

void main() {
  group('Integration Test - Mode Switching (Exploration vs Planning)', () {
    late RouteApiClient client;

    // Define 3 points: A, B, C
    // A (Start): 0,0
    // B (Close): 0,1
    // C (Far): 0,10
    //
    // Input Order: A -> C -> B
    // Maze Mode Expectation: A -> C -> B (Respects input)
    // Optimized Mode Expectation: A -> B -> C (Sorts by distance)
    
    final wpA = const Waypoint(id: 'A', location: Location(lat: 0, lng: 0));
    final wpB = const Waypoint(id: 'B', location: Location(lat: 0, lng: 1));
    final wpC = const Waypoint(id: 'C', location: Location(lat: 0, lng: 10));

    setUp(() {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8080/v1'; 
      client = RouteApiClient(dio: dio, organizationId: 'mode-test');
    });

    test('MAZE mode respects user input order (Exploration)', () async {
      final request = RouteRequest(
        mode: 'MAZE',
        waypoints: [wpA, wpC, wpB], // Intentional jagged order
      );

      final response = await client.calculateRoute(request);
      
      expect(response.segments.length, 2);
      // Segment 1: A -> C
      expect(response.segments[0].fromId, 'A');
      expect(response.segments[0].toId, 'C');
      // Segment 2: C -> B
      expect(response.segments[1].fromId, 'C');
      expect(response.segments[1].toId, 'B'); // User forced this long jump back
    });

    test('OPTIMIZED mode reorders for efficiency (Route Planning)', () async {
      final request = RouteRequest(
        mode: 'OPTIMIZED',
        waypoints: [wpA, wpC, wpB], // Same jagged input
      );

      final response = await client.calculateRoute(request);

      expect(response.segments.length, 2);
      // Segment 1: A -> B (B is closer to A than C is)
      expect(response.segments[0].fromId, 'A');
      expect(response.segments[0].toId, 'B'); 
      // Segment 2: B -> C
      expect(response.segments[1].fromId, 'B');
      expect(response.segments[1].toId, 'C');
    });
  });
}
