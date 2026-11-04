import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';
import 'package:google_service_app/core/config/env.dart';

class PlacesService {
  final Dio _dio;
  // ignore: unused_field
  final String _apiKey; // Kept for legacy compatibility if needed, but using Env directly

  PlacesService(this._dio, {String apiKey = "ENV_MANAGED"}) : _apiKey = apiKey;

  /// Real Search using Google Places API (New)
  Future<List<Spot>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    // Note: Ensure 'Places API (New)' is enabled in Google Cloud Console
    const String baseUrl = 'https://places.googleapis.com/v1/places:searchText';
    final String apiKey = Env.placesApiKey;

    try {
      final response = await _dio.post(
        baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            // FieldMask is critical for V1 API to actually return data and manage costs
            'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.photos',
          },
        ),
        data: {
          'textQuery': query,
          'maxResultCount': 10,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> places = data['places'] ?? [];

        return places.map((place) => _mapPlaceToSpot(place)).toList();
      } else {
        debugPrint('Places API Error: ${response.statusCode} - ${response.statusMessage}');
        debugPrint('Response Data: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      debugPrint('Places API Exception: ${e.message}');
      debugPrint('Response Data: ${e.response?.data}');
      return [];
    } catch (e) {
      debugPrint('Places API Unexpected Exception: $e');
      return [];
    }
  }

  Spot _mapPlaceToSpot(Map<String, dynamic> place) {
    final String name = place['displayName']?['text'] ?? 'Unknown Place';
    final String address = place['formattedAddress'] ?? '';
    final double lat = place['location']?['latitude'] ?? 0.0;
    final double lng = place['location']?['longitude'] ?? 0.0;
    final List<dynamic> types = place['types'] ?? [];
    final double rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    
    // Photo Logic (New API)
    // We construct a proxy URL or use the name directly if we had a backend.
    // For direct frontend display, we need to append the key, so we assume client-side usage.
    // Resource Name: places/PLACE_ID/photos/PHOTO_ID
    final List<dynamic> photos = place['photos'] ?? [];
    String? photoUrl;
    if (photos.isNotEmpty) {
      final String photoResourceName = photos.first['name'];
      // Max size 400px for thumbnail
      photoUrl = 'https://places.googleapis.com/v1/$photoResourceName/media?maxHeightPx=400&maxWidthPx=400&key=${Env.placesApiKey}';
    }

    return Spot(
      id: place['id'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      latitude: lat,
      longitude: lng,
      address: address,
      googlePlaceId: place['id'],
      status: SpotStatus.pending,
      category: mapGoogleTypeToCategory(types.cast<String>()),
      creatorId: 'current_user', 
      metadata: {
        'rating': rating,
        'img': photoUrl,
      },
    );
  }

  // --- Classification Logic ---
  SpotCategory mapGoogleTypeToCategory(List<String> types) {
    if (types.any((t) => ['lodging', 'hotel', 'resort', 'guest_house'].contains(t))) {
      return SpotCategory.accommodation;
    }
    if (types.any((t) => ['restaurant', 'food', 'cafe', 'bakery', 'bar', 'meal_takeaway'].contains(t))) {
      return SpotCategory.restaurant;
    }
    if (types.any((t) => ['airport', 'transit_station'].contains(t))) {
      return SpotCategory.flight; 
    }
    if (types.any((t) => ['tourist_attraction', 'point_of_interest', 'museum', 'park', 'amusement_park'].contains(t))) {
      return SpotCategory.spot;
    }
    return SpotCategory.other;
  }
}
