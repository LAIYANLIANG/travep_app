import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/route_api_client.dart';
import '../../data/models/route_request.dart';
import '../../data/models/route_response.dart';

// --- Providers ---

/// Global Dio instance
final dioProvider = Provider<Dio>((ref) => Dio());

/// API Client Provider
final routeApiClientProvider = Provider<RouteApiClient>((ref) {
  return RouteApiClient(dio: ref.watch(dioProvider));
});

/// State Provider for current Route Response
final routeStateProvider = AsyncNotifierProvider<RouteStateNotifier, RouteResponse?>(RouteStateNotifier.new);

/// State Provider for current Waypoints List
final waypointsProvider = NotifierProvider<WaypointsNotifier, List<Waypoint>>(WaypointsNotifier.new);

// --- Notifiers ---

class WaypointsNotifier extends Notifier<List<Waypoint>> {
  @override
  List<Waypoint> build() {
    return [];
  }

  void setWaypoints(List<Waypoint> points) {
    state = points;
  }

  /// Reorder supports the flutter ReorderableListView
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final currentList = List<Waypoint>.from(state);
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);
    state = currentList;
  }
}

class RouteStateNotifier extends AsyncNotifier<RouteResponse?> {
  
  @override
  Future<RouteResponse?> build() async {
    return null;
  }

  Future<void> calculate({
    required List<Waypoint> waypoints,
    required String mode,
  }) async {
    if (waypoints.length < 2) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();

    try {
      final client = ref.read(routeApiClientProvider);
      final request = RouteRequest(
        mode: mode,
        waypoints: waypoints,
      );
      final response = await client.calculateRoute(request);
      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
