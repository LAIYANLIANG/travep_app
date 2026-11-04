
import 'package:flutter/material.dart';
import 'flight_repository.dart';

class FlightsPage extends StatefulWidget {
  const FlightsPage({super.key});

  @override
  State<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends State<FlightsPage> {
  final FlightRepository _repo = FlightRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Flight Search"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Results",
            onPressed: () {
               _repo.clear();
            }
          )
        ],
      ),
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _repo.currentFlightsNotifier,
        builder: (context, flightData, child) {
          if (flightData == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("目前查無航班資料", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("請前往 'Smart Trip Planner' 進行搜尋。", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final flights = flightData['data'] as List? ?? [];
          final meta = flightData['metadata'] ?? {};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                       Text("${meta['origin'] ?? 'Origin'} ➔ ${meta['destination'] ?? 'Dest'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       Text("Date: ${meta['date'] ?? ''} • ${meta['adults'] ?? 1} Adults", style: const TextStyle(fontSize: 14)),
                       const SizedBox(height: 4),
                       const Text("Search Results (Live from Amadeus)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (flights.isEmpty)
                 const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("目前查無符合條件的航班資料。"))),

              ...flights.map((flight) {
                 final price = flight['price']['total'];
                 final currency = flight['price']['currency'] ?? "TWD";
                 final itinerary = flight['itineraries'] as List;
                 
                 return Card(
                   margin: const EdgeInsets.only(bottom: 16),
                   elevation: 3,
                   child: Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               const Row(children: [Icon(Icons.airplane_ticket, color: Colors.blue), SizedBox(width: 8), Text("Flight Offer", style: TextStyle(fontWeight: FontWeight.bold))]),
                               Text("$currency $price", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Divider(),
                          ...itinerary.asMap().map((idx, leg) {
                             final List segments = leg['segments'];
                             final first = segments.first;
                             final last = segments.last;
                             
                             // Extract HH:mm from "2026-02-01T10:15:00"
                             String formatTime(String at) => at.contains('T') ? at.split('T')[1].substring(0, 5) : at;

                             return MapEntry(idx, Padding(
                               padding: const EdgeInsets.symmetric(vertical: 8),
                               child: Column(
                                 children: [
                                   Row(
                                     children: [
                                       Icon(idx == 0 ? Icons.flight_takeoff : Icons.flight_land, size: 20, color: Colors.blue),
                                       const SizedBox(width: 8),
                                       Text(idx == 0 ? "Outbound" : "Return", style: const TextStyle(fontWeight: FontWeight.bold)),
                                       const Spacer(),
                                       Text("Duration: ${leg['duration'].replaceAll('PT', '').toLowerCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                     ],
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       _buildTimeCell("Departure", first['departure']['iataCode'], formatTime(first['departure']['at'])),
                                       const Icon(Icons.arrow_forward_outlined, color: Colors.grey, size: 16),
                                       _buildTimeCell("Arrival", last['arrival']['iataCode'], formatTime(last['arrival']['at'])),
                                     ],
                                   ),
                                   if (segments.length > 1) 
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text("${segments.length - 1} stops", style: const TextStyle(color: Colors.orange, fontSize: 11)),
                                      ),
                                 ],
                               ),
                             ));
                          }).values
                       ],
                     ),
                   ),
                 );
              })
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeCell(String label, String code, String time) {
    return Column(
      crossAxisAlignment: label == "Arrival" ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(time, style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
