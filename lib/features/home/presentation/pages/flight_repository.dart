
import 'package:flutter/foundation.dart';
import '../../data/flight_service.dart';

class FlightRepository {
  // Singleton pattern
  static final FlightRepository _instance = FlightRepository._internal();
  factory FlightRepository() => _instance;
  FlightRepository._internal();

  final FlightService _api = FlightService();

  Map<String, dynamic>? _lastSearchResult;
  DateTime? _lastSearchTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  final ValueNotifier<Map<String, dynamic>?> currentFlightsNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  Future<void> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    required Map<String, int> travelerCounts,
    String cabinClass = 'ECONOMY',
  }) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;
    
    try {
      final result = await _api.searchFlights(
        origin: origin, 
        destination: destination, 
        departureDate: departureDate, 
        returnDate: returnDate,
        travelerCounts: travelerCounts,
        cabinClass: cabinClass,
      );
      
      // Inject Metadata for UI display
      result['metadata'] = {
        'origin': origin,
        'destination': destination,
        'departureDate': departureDate,
        'returnDate': returnDate,
        'travelerCounts': travelerCounts,
        'cabinClass': cabinClass,
      };

      saveFlights(result);
    } catch (e) {
      errorNotifier.value = e.toString();
      debugPrint("Repo Error: $e");
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  void saveFlights(Map<String, dynamic> result) {
    _lastSearchResult = result;
    _lastSearchTime = DateTime.now();
    currentFlightsNotifier.value = result;
  }

  Map<String, dynamic>? getFlights() {
    if (_lastSearchTime == null || _lastSearchResult == null) return null;
    
    if (DateTime.now().difference(_lastSearchTime!) > _cacheDuration) {
      clear();
      return null;
    }
    return _lastSearchResult;
  }

  void clear() {
    _lastSearchResult = null;
    _lastSearchTime = null;
    currentFlightsNotifier.value = null;
    errorNotifier.value = null;
  }
}
