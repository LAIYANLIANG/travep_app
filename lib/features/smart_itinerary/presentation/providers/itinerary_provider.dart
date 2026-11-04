import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/waypoint.dart';
import '../../data/repositories/directions_repository.dart';

// Directions Repository Provider
final directionsRepositoryProvider = Provider<DirectionsRepository>((ref) {
  return DirectionsRepository();
});

// State
class ItineraryState {
  final List<Waypoint> waypoints;
  final Set<Polyline> polylines;
  final String totalDuration;
  final String totalDistance;
  final bool isLoading;

  final List<String> warnings;

  ItineraryState({
    this.waypoints = const [],
    this.polylines = const {},
    this.totalDuration = '',
    this.totalDistance = '',
    this.warnings = const [],
    this.isLoading = false,
  });

  ItineraryState copyWith({
    List<Waypoint>? waypoints,
    Set<Polyline>? polylines,
    String? totalDuration,
    String? totalDistance,
    List<String>? warnings,
    bool? isLoading,
  }) {
    return ItineraryState(
      waypoints: waypoints ?? this.waypoints,
      polylines: polylines ?? this.polylines,
      totalDuration: totalDuration ?? this.totalDuration,
      totalDistance: totalDistance ?? this.totalDistance,
      warnings: warnings ?? this.warnings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages the state of the Smart Itinerary feature.
/// 
/// Responsibilities:
/// 1. Holds the list of [Waypoint]s.
/// 2. Handles reordering logic.
/// 3. Debounces API calls to the backend to prevent excessive load.
class ItineraryNotifier extends Notifier<ItineraryState> {
  Timer? _debounceTimer;

  @override
  ItineraryState build() {
    // Initial state
    final initialState = ItineraryState(
       waypoints: [
        const Waypoint(id: '1', name: 'Taipei Main Station', latitude: 25.0478, longitude: 121.5170),
        const Waypoint(id: '2', name: 'Taipei 101', latitude: 25.0339, longitude: 121.5645),
        const Waypoint(id: '3', name: 'Ximending', latitude: 25.0422, longitude: 121.5080),
      ]
    );
    // Determine if we should fetch routes immediately
    // We cannot call async _fetchRoutes directly in build safely without potential issues, 
    // but we can schedule it.
    Future.microtask(() => _fetchRoutes());
    return initialState;
  }

  /// Reorders waypoints in the list and triggers a route update.
  /// 
  /// [oldIndex] and [newIndex] are provided by the ReorderableListView.
  void reorderWaypoints(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<Waypoint> newWaypoints = List.from(state.waypoints);
    final Waypoint item = newWaypoints.removeAt(oldIndex);
    newWaypoints.insert(newIndex, item);

    state = state.copyWith(waypoints: newWaypoints);
    
    // Debounce API call
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _fetchRoutes);
  }

  Future<void> _fetchRoutes() async {
    final repository = ref.read(directionsRepositoryProvider);
    if (state.waypoints.length < 2) {
      state = state.copyWith(polylines: {}, totalDuration: '', totalDistance: '');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await repository.getDirections(waypoints: state.waypoints);
      
      if (result.isNotEmpty && result.containsKey('polylineCoordinates')) {
        final List<LatLng> coordinates = result['polylineCoordinates'];
        
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: coordinates,
          color: Colors.blue,
          width: 5,
        );

        state = state.copyWith(
          polylines: {polyline},
          totalDuration: result['totalDuration'],
          totalDistance: result['totalDistance'],
          warnings: result['warnings'] ?? [],
          isLoading: false,
        );
      } else {
         state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      state = state.copyWith(isLoading: false);
    }
  }
  
  void addWaypoint(Waypoint waypoint) {
    state = state.copyWith(waypoints: [...state.waypoints, waypoint]);
    _fetchRoutes();
  }

  void removeWaypoint(String id) {
    final newWaypoints = state.waypoints.where((w) => w.id != id).toList();
    state = state.copyWith(waypoints: newWaypoints);
    _fetchRoutes();
  }
}

final itineraryProvider = NotifierProvider<ItineraryNotifier, ItineraryState>(() {
  return ItineraryNotifier();
});
