import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExplorationPage extends StatefulWidget {
  const ExplorationPage({super.key});

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  final Dio _dio = Dio();
  List<dynamic> _items = [];
  bool _isLoading = false;
  
  // Breadcrumbs: [ {id, name}, ... ]
  final List<Map<String, String>> _breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _fetchHierarchy(); // Load root (Regions)
  }

  Future<void> _fetchHierarchy([String? parentId, String? parentName]) async {
    setState(() => _isLoading = true);
    try {
      final url = 'http://localhost:8080/v1/places/hierarchy${parentId != null ? "?parent_id=$parentId" : ""}';
      final response = await _dio.get(url);
      
      setState(() {
        _items = response.data;
        if (parentId != null && parentName != null) {
          _breadcrumbs.add({'id': parentId, 'name': parentName});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetToRoot() {
    setState(() {
      _breadcrumbs.clear();
      _items = [];
    });
    _fetchHierarchy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exploration Mode (Maze)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Complete & Optimize",
            onPressed: () => Navigator.pushNamed(context, '/optimizer'),
          ),
        ],
      ),
      body: Row(
        children: [
          // LEFT: Drill-down Panel
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Breadcrumbs
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: _resetToRoot,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _breadcrumbs.isEmpty 
                            ? "Select Region" 
                            : _breadcrumbs.map((e) => e['name']).join(" > "),
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // List Items
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                item['type'] == 'REGION' ? Icons.public : 
                                item['type'] == 'COUNTRY' ? Icons.flag : 
                                item['type'] == 'CITY' ? Icons.location_city : Icons.camera_alt
                              ),
                              title: Text(item['name']),
                              trailing: item['has_children'] 
                                ? const Icon(Icons.arrow_forward_ios, size: 16) 
                                : const Icon(Icons.add_circle_outline, color: Colors.green),
                              onTap: () {
                                if (item['has_children']) {
                                  _fetchHierarchy(item['id'], item['name']);
                                } else {
                                  // It's a key leaf node (City or POI without further drill-down in this demo)
                                  if (item['type'] == 'POI') {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Added to itinerary: ${item['name']}"),
                                        backgroundColor: Colors.teal,
                                      )
                                    );
                                  } else {
                                    // Should not happen given new logic, but fallback
                                     ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Selected: ${item['name']}"))
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          
          // RIGHT: Map View (Placeholder but stylized)
          Expanded(
            flex: 7,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(45.9432, 24.9668), // Romania center (example)
                zoom: 7,
              ),
              onMapCreated: (GoogleMapController controller) {
                // Future integration
              },
            ),
          ),
        ],
      ),
    );
  }
}
