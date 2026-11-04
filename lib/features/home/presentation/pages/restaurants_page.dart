import 'package:flutter/material.dart';
import '../../data/restaurant_service.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final RestaurantService _service = RestaurantService();
  final TextEditingController _searchController = TextEditingController(text: "Korean");
  
  // Hardcoded location for demo (Dongdaemun, Seoul) as per user request
  // In a real app, this would come from Geolocation or Gemini parsing
  final double _demoLat = 37.5714;
  final double _demoLng = 127.0097;

  List<dynamic> _restaurants = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-search on load for demo
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.searchRestaurants(
        latitude: _demoLat,
        longitude: _demoLng,
        keyword: _searchController.text,
        radius: 5
      );
      
      setState(() {
        _restaurants = result['data'] ?? [];
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant Finder"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Finding restaurants near: Dongdaemun (Demo)", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Keyword (e.g., Korean, BBQ)",
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16)
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _performSearch, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Icon(Icons.search)
                    )
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null 
                  ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
                  : _restaurants.isEmpty
                      ? const Center(child: Text("No restaurants found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                            final rest = _restaurants[index];
                            final name = rest['name'] ?? "Unknown";
                            final tags = (rest['tags'] as List?)?.join(", ") ?? "Restaurant";
                            final cat = rest['category'] ?? "POI";
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: const Icon(Icons.restaurant, color: Colors.orange),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("$cat • $tags"),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ),
                            );
                          },
                        ),
          )
        ],
      ),
    );
  }
}
