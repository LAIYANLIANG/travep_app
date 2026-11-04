import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/itinerary_provider.dart';

class ItineraryMapView extends ConsumerWidget {
  const ItineraryMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryProvider);
    final polylines = itineraryState.polylines;
    final waypoints = itineraryState.waypoints;

    Set<Marker> markers = {};
    if (waypoints.isNotEmpty) {
      markers = waypoints.asMap().entries.map((entry) {
        final index = entry.key;
        final w = entry.value;
        return Marker(
          markerId: MarkerId(w.id),
          position: LatLng(w.latitude, w.longitude),
          infoWindow: InfoWindow(title: "${index + 1}. ${w.name}"),
        );
      }).toSet();
    }

    final initialCameraPosition = waypoints.isNotEmpty
        ? CameraPosition(target: LatLng(waypoints.first.latitude, waypoints.first.longitude), zoom: 12)
        : const CameraPosition(target: LatLng(25.0330, 121.5654), zoom: 10); // Default to Taipei

    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        // Optional: Fit bounds
      },
    );
  }
}
