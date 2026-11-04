import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:google_service_app/features/smart_itinerary/data/repositories/directions_repository.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/waypoint.dart';
import 'package:google_service_app/features/smart_itinerary/presentation/providers/itinerary_provider.dart';
import 'package:google_service_app/features/smart_itinerary/presentation/widgets/waypoint_list_view.dart';

import 'smart_itinerary_test.mocks.dart';

@GenerateMocks([http.Client, DirectionsRepository])
void main() {
  group('Smart Itinerary Tests', () {
    late MockClient mockHttpClient;
    late DirectionsRepository repository;
    
    setUp(() {
      mockHttpClient = MockClient();
      repository = DirectionsRepository(httpClient: mockHttpClient);
    });

    final tWaypoints = [
      const Waypoint(id: '1', name: 'Start', latitude: 10.0, longitude: 10.0),
      const Waypoint(id: '2', name: 'End', latitude: 20.0, longitude: 20.0),
    ];

    test('DirectionsRepository returns correct data from Backend', () async {
      // Arrange
      const mockBackendResponse = {
        'segments': [],
        'total_duration_seconds': 3600,
        'total_distance_meters': 5000,
        'combined_polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        'warnings': ['Suggestion 1']
      };
      
      when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
        (_) async => http.Response(jsonEncode(mockBackendResponse), 200),
      );

      // Act
      final result = await repository.getDirections(waypoints: tWaypoints);

      // Assert
      expect(result['totalDuration'], '1h 0m');
      expect(result['totalDistance'], '5.0 km');
      expect(result['polylineCoordinates'], isA<List<LatLng>>());
      expect(result['warnings'], contains('Suggestion 1'));
    });
    
    testWidgets('WaypointListView renders waypoints', (tester) async {
       await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override with a notifier that has data
            itineraryProvider.overrideWith(() => MockItineraryNotifier()),
          ],
          child: const MaterialApp(home: Scaffold(body: WaypointListView())),
        ),
      );
      
      // Allow implicit async (Future.microtask in build) to settle if any
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });
  });
}

// Mock Notifier for Widget Test
class MockItineraryNotifier extends ItineraryNotifier {
  @override
  ItineraryState build() {
    // Return a static state without calling API
    return ItineraryState(
      waypoints: [
        const Waypoint(id: '1', name: 'Start', latitude: 10.0, longitude: 10.0),
        const Waypoint(id: '2', name: 'End', latitude: 20.0, longitude: 20.0),
      ],
      isLoading: false,
    );
  }
}
