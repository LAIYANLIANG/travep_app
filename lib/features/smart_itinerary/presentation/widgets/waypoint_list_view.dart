import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/itinerary_provider.dart';

class WaypointListView extends ConsumerWidget {
  const WaypointListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryProvider);
    final waypoints = itineraryState.waypoints;

    if (waypoints.isEmpty) {
      return const Center(child: Text("No stops added"));
    }

    return Column(
      children: [
        if (itineraryState.isLoading)
          const LinearProgressIndicator(),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: waypoints.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(itineraryProvider.notifier).reorderWaypoints(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final waypoint = waypoints[index];
              return ListTile(
                key: ValueKey(waypoint.id),
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(waypoint.name),
                subtitle: Text("Stay tuned for AI suggestions..."), 
                trailing: const Icon(Icons.drag_handle),
              );
            },
          ),
        ),
        if (itineraryState.totalDuration.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                       children: [
                         const Icon(Icons.timer),
                         Text(itineraryState.totalDuration, style: const TextStyle(fontWeight: FontWeight.bold)),
                       ],
                    ),
                    Column(
                       children: [
                         const Icon(Icons.directions_car),
                         Text(itineraryState.totalDistance, style: const TextStyle(fontWeight: FontWeight.bold)),
                       ],
                    ),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }
}
