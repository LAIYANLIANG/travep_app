import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SmartTripService {
  final Dio _dio;
  final String baseUrl;

  SmartTripService(this._dio, {this.baseUrl = 'http://127.0.0.1:8080'});

  Future<Map<String, dynamic>?> searchSmartFlights({
    required String departureCity,
    required String destination,
    required String startDate, // YYYY-MM-DD
    required String endDate,
    required String departureTimeInfo, // e.g. "Morning"
    required String returnTimeInfo,
    int? budget, // 10k unit
    int peopleAdults = 1,
    int peopleChildren = 0,
    String? returnOrigin,
    String? returnDest,
    String? userQuery,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/v1/smart/flights',
        data: {
          "departure_city": departureCity,
          "destination": destination,
          "start_date": startDate,
          "end_date": endDate,
          "departure_time_preference": departureTimeInfo,
          "return_time_preference": returnTimeInfo,
          "budget": budget,
          "people_adults": peopleAdults,
          "people_children": peopleChildren,
          "return_origin_city": returnOrigin,
          "return_destination_city": returnDest,
          "userQuery": userQuery,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("SmartTripService Error: $e");
      rethrow; // Re-throw to let UI handle/show error
    }
    return null;
  }
}
