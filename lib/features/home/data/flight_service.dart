import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FlightService {
  String get _baseUrl => 'http://127.0.0.1:8080/api'; 

  Future<Map<String, dynamic>> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    required Map<String, int> travelerCounts,
    String cabinClass = 'ECONOMY',
    String currency = 'TWD',
  }) async {
    final url = Uri.parse('$_baseUrl/shopping/flight-offers');
    
    // Build travelers list
    final List<Map<String, String>> travelers = [];
    int travelerId = 1;
    
    travelerCounts.forEach((type, count) {
      for (int i = 0; i < count; i++) {
        travelers.add({
          "id": "${travelerId++}",
          "travelerType": type.toUpperCase() // ADULT, CHILD, HELD_INFANT
        });
      }
    });

    final originDestinations = [
      {
        "id": "1",
        "originLocationCode": origin,
        "destinationLocationCode": destination,
        "departureDateTimeRange": {
          "date": departureDate
        }
      }
    ];

    if (returnDate != null && returnDate.isNotEmpty) {
      originDestinations.add({
        "id": "2",
        "originLocationCode": destination,
        "destinationLocationCode": origin,
        "departureDateTimeRange": {
          "date": returnDate
        }
      });
    }

    final payload = {
      "currencyCode": currency,
      "originDestinations": originDestinations,
      "travelers": travelers,
      "sources": ["GDS"],
      "searchCriteria": {
        "maxFlightOffers": 50,
        "flightFilters": {
          "cabinRestrictions": [
            {
              "cabin": cabinClass,
              "coverage": "MOST_SEGMENTS",
              "originDestinationIds": originDestinations.map((od) => od["id"]).toList()
            }
          ]
        }
      }
    };

    try {
      debugPrint("✈️ Sending Flight Search Request: $payload");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"payload": payload}), // Wrapping in 'payload' as per Python Pydantic model
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Flight Search Successful. Found ${data['data']?.length ?? 0} offers.");
        return data;
      } else {
        throw Exception("Failed to load flights: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Flight Search Error: $e");
      throw Exception("Error connecting to server: $e");
    }
  }
}
