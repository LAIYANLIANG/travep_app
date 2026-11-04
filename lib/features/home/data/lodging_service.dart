import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LodgingService {
  String get _baseUrl => 'http://127.0.0.1:8080/api'; 

  // Step 1: Find Hotels by Geocode
  Future<List<dynamic>> searchHotelsByLocation({
    required double latitude,
    required double longitude,
    int radius = 5,
  }) async {
    final uri = Uri.parse('$_baseUrl/lodging/hotels-by-geocode').replace(queryParameters: {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
      "radius": radius.toString(),
    });

    try {
      debugPrint("🏨 Sending Hotel Location Search Request: $uri");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception("Failed to find hotels: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Hotel Location Search Error: $e");
      throw Exception("Error connecting to server: $e");
    }
  }

  // Step 2: Get Offers for specific hotels
  Future<List<dynamic>> getHotelOffers({
    required List<String> hotelIds,
    required String checkInDate,
    required String checkOutDate,
    int adults = 1,
  }) async {
    if (hotelIds.isEmpty) return [];

    // Amadeus usually allows ~50 IDs. We take first 50 for demo simplicity.
    final idsStr = hotelIds.take(50).join(",");
    
    final uri = Uri.parse('$_baseUrl/lodging/hotel-offers').replace(queryParameters: {
      "hotelIds": idsStr,
      "checkInDate": checkInDate,
      "checkOutDate": checkOutDate,
      "adults": adults.toString(),
      "currency": "TWD",
    });

    try {
       debugPrint("🏨 Sending Hotel Offers Request: $uri");
       final response = await http.get(uri);

       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         return data['data'] ?? [];
       } else {
          // 404 here just means no offers for these specific hotels on these dates
          if (response.statusCode == 404) return [];
          throw Exception("Failed to get hotel offers: ${response.statusCode} ${response.body}");
       }
    } catch (e) {
      debugPrint("❌ Hotel Offers Error: $e");
      throw Exception("Error connecting to server: $e");
    }
  }
}
