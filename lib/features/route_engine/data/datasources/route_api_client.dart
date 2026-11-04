import 'package:dio/dio.dart';
import '../../data/models/route_request.dart';
import '../../data/models/route_response.dart';

class RouteApiClient {
  /// Base URL for the Route Engine Service.
  /// For Android Emulator: Use 10.0.2.2
  /// For iOS Simulator: Use localhost
  // TODO: Move to environment configuration
  static const String _baseUrl = 'http://localhost:8080/v1'; 

  final Dio _dio;
  final String organizationId;

  RouteApiClient({
    required Dio dio,
    this.organizationId = 'test-org', // Default for dev
  }) : _dio = dio {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'X-Organization-ID': organizationId,
    };
  }

  /// Post to /routes/calculate
  Future<RouteResponse> calculateRoute(RouteRequest request) async {
    try {
      final response = await _dio.post(
        '/routes/calculate',
        data: request.toJson(),
      );

      return RouteResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Handle Dio errors (network, 4xx, 5xx)
      throw Exception('Failed to calculate route: ${e.message} ${e.response?.data}');
    }
  }
}
