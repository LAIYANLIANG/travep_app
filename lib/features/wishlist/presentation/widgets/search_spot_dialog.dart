import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';
import '../../../smart_planning/data/datasources/places_service.dart';
import 'package:dio/dio.dart';

// Simple provider for PlacesService (Mock for now)
final placesServiceProvider = Provider((ref) => PlacesService(Dio()));

class SearchSpotDialog extends ConsumerStatefulWidget {
  final Function(Spot) onSpotSelected;

  const SearchSpotDialog({super.key, required this.onSpotSelected});

  @override
  ConsumerState<SearchSpotDialog> createState() => _SearchSpotDialogState();
}

class _SearchSpotDialogState extends ConsumerState<SearchSpotDialog> {
  final _searchController = TextEditingController();
  List<Spot> _results = [];
  bool _isLoading = false;

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    // Call Service
    try {
      final service = ref.read(placesServiceProvider);
      // Simulate network delay for realism
      await Future.delayed(const Duration(milliseconds: 800)); 
      
      // If mock returns empty for generic terms in PlacesService, let's inject some here
      // if the service is still basic.
      // But we'll try the service first.
      var results = await service.searchPlaces(query);
      
      // Fallback Mock Data if service returns empty (for demo purposes)
      if (results.isEmpty) {
        results = _generateMockResults(query);
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Search failed: $e")));
      }
    }
  }
  
  // Robust Mock Generator for Demo
  List<Spot> _generateMockResults(String query) {
    final service = ref.read(placesServiceProvider);
    return [
      Spot(
        id: 'mock_${query}_1',
        name: '$query Hotel & Spa',
        latitude: 35.0,
        longitude: 139.0,
        address: '1-1-1 Demo Street, Tokyo',
        category: service.mapGoogleTypeToCategory(['lodging', 'hotel']), // Auto-categorize
        status: SpotStatus.pending,
        creatorId: 'client_1',
        metadata: {'rating': 4.2, 'img': 'https://picsum.photos/200?random=${query.length}'},
      ),
      Spot(
        id: 'mock_${query}_2',
        name: '$query Cafe',
        latitude: 35.01,
        longitude: 139.01,
        address: '2-2-2 Coffee Lane, Shibuya',
        category: service.mapGoogleTypeToCategory(['cafe', 'food']),
        status: SpotStatus.pending,
        creatorId: 'client_1',
        metadata: {'rating': 4.8, 'img': 'https://picsum.photos/200?random=${query.length+1}'},
      ),
      Spot(
        id: 'mock_${query}_3',
        name: '$query Park',
        latitude: 35.02,
        longitude: 139.02,
        address: '3-3-3 Green Way, Shinjuku',
        category: service.mapGoogleTypeToCategory(['park', 'point_of_interest']),
        status: SpotStatus.pending,
        creatorId: 'client_1',
        metadata: {'rating': 4.5, 'img': 'https://picsum.photos/200?random=${query.length+2}'},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Make a Wish", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search places (e.g., 'Ramen', 'Disneyland')...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 24),
            const Text("Results", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            const Text("Search to find places", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final spot = _results[index];
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: spot.metadata['img'] != null 
                                  ? DecorationImage(image: NetworkImage(spot.metadata['img']), fit: BoxFit.cover)
                                  : null,
                                color: Colors.grey[200],
                              ),
                              child: spot.metadata['img'] == null ? const Icon(Icons.place) : null,
                            ),
                            title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(spot.address ?? 'No address'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => widget.onSpotSelected(spot),
                              child: const Text("Add"),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
