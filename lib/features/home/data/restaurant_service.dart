import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RestaurantService {
  String get _baseUrl => 'http://127.0.0.1:8080/api'; 

  Future<Map<String, dynamic>> searchRestaurants({
    required double latitude,
    required double longitude,
    String? keyword,
    int radius = 2,
  }) async {
    final uri = Uri.parse('$_baseUrl/restaurants/search').replace(queryParameters: {
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
      "radius": radius.toString(),
      if (keyword != null && keyword.isNotEmpty) "keyword": keyword,
    });

    try {
      debugPrint("🍽️ Sending Restaurant Search Request: $uri");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Expecting {"data": [...]}
      } else {
        throw Exception("Failed to load restaurants: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Restaurant Search Error: $e");
      throw Exception("Error connecting to server: $e");
    }
  }
}
