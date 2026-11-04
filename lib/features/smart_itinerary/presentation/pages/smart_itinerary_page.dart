import 'package:flutter/material.dart';
import '../widgets/waypoint_list_view.dart';
import '../widgets/itinerary_map_view.dart';

class SmartItineraryPage extends StatelessWidget {
  const SmartItineraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Itinerary Rehearsal'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Tablet / Desktop: Split View
            return Row(
              children: const [
                Expanded(flex: 1, child: WaypointListView()),
                VerticalDivider(width: 1),
                Expanded(flex: 2, child: ItineraryMapView()),
              ],
            );
          } else {
            // Mobile: Vertical Split (Map on top or bottom? usually Map on top is nice, but list is more interactive)
            // Let's do Map on top (small) and List below, or Map as a heavy header.
            // For rehearsal, maybe List is primary. Let's do 50/50 for MVP.
            return Column(
              children: const [
                Expanded(flex: 1, child: ItineraryMapView()),
                Divider(height: 1),
                Expanded(flex: 1, child: WaypointListView()),
              ],
            );
          }
        },
      ),
    );
  }
}
