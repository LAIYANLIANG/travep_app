import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class OptimizerPage extends StatefulWidget {
  const OptimizerPage({super.key});

  @override
  State<OptimizerPage> createState() => _OptimizerPageState();
}

class _OptimizerPageState extends State<OptimizerPage> {
  final Dio _dio = Dio();
  bool _isLoading = false;
  Map<String, dynamic>? _routeResult;
  Set<Marker> _markers = {};

  // Mock Data
  List<Map<String, dynamic>> _waypoints = [
    {'id': 'wp1', 'original_index': 0, 'name': '布加勒斯特 (Bucharest)', 'lat': 44.4268, 'lng': 26.1025},
    {'id': 'wp2', 'original_index': 1, 'name': '布拉索夫 (Brasov)', 'lat': 45.6427, 'lng': 25.5887},
    {'id': 'wp3', 'original_index': 2, 'name': '錫比烏 (Sibiu)', 'lat': 45.7983, 'lng': 24.1256},
    {'id': 'wp4', 'original_index': 3, 'name': '克盧日-納波卡 (Cluj-Napoca)', 'lat': 46.7712, 'lng': 23.6236},
    {'id': 'wp5', 'original_index': 4, 'name': '蒂米什瓦拉 (Timisoara)', 'lat': 45.7489, 'lng': 21.2087},
    {'id': 'wp6', 'original_index': 5, 'name': '康斯坦察 (Constanta)', 'lat': 44.1598, 'lng': 28.6348},
    {'id': 'wp7', 'original_index': 6, 'name': '雅西 (Iasi)', 'lat': 47.1585, 'lng': 27.6014},
    {'id': 'wp8', 'original_index': 7, 'name': '錫吉什瓦拉 (Sighisoara)', 'lat': 46.2197, 'lng': 24.7964},
    {'id': 'wp9', 'original_index': 8, 'name': '布朗城堡 (Bran Castle)', 'lat': 45.5149, 'lng': 25.3672},
    {'id': 'wp10', 'original_index': 9, 'name': '派勒斯城堡 (Peles Castle)', 'lat': 45.3599, 'lng': 25.5426},
  ];

  // Helper to create numbered markers
  Future<BitmapDescriptor> _createCustomMarkerBitmap(int number, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    const double radius = 30.0;
    
    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    
    textPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final img = await pictureRecorder.endRecording().toImage(
      (radius * 2).toInt(),
      (radius * 2).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _updateMarkers() async {
     Set<Marker> newMarkers = {};
     for (int i = 0; i < _waypoints.length; i++) {
        final wp = _waypoints[i];
        // Use fixed original_index for the number
        final int fixedNumber = (wp['original_index'] as int? ?? 0) + 1;
        
        final icon = await _createCustomMarkerBitmap(
          fixedNumber, 
          i == 0 ? Colors.green : (i == _waypoints.length - 1 ? Colors.red : Colors.orange)
        );
        
        final double lat = (wp['lat'] as num?)?.toDouble() ?? 0.0;
        final double lng = (wp['lng'] as num?)?.toDouble() ?? 0.0;
        
        newMarkers.add(Marker(
          markerId: MarkerId(wp['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: wp['name']),
          icon: icon,
        ));
     }
     setState(() {
       _markers = newMarkers;
     });
  }

  Future<void> _calculateRoute() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.post(
        'http://localhost:8080/v1/routes/calculate',
        options: Options(headers: {'X-Organization-ID': 'test-org'}),
        data: {
          "mode": "OPTIMIZED",
          "waypoints": _waypoints.map((e) => {
            "id": e['id'],
            "original_index": e['original_index'], // Pass this to backend just in case
            "name": e['name'],
            "location": {"lat": e['lat'], "lng": e['lng']}
          }).toList()
        },
      );
      
      final data = response.data;
      
      setState(() {
        _routeResult = data;
        // Update the list order based on backend optimization
        if (data['optimized_waypoints'] != null) {
          // Normalize backend structure (which has 'location': {'lat':...}) to frontend flat structure
           _waypoints = (data['optimized_waypoints'] as List).map((e) {
             final loc = e['location'] ?? {};
             return {
               'id': e['id'],
               'original_index': e['original_index'],
               'name': e['name'],
               'lat': loc['lat'],
               'lng': loc['lng'],
             };
           }).toList().cast<Map<String, dynamic>>();
        }
      });
      
      await _updateMarkers();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Optimizer'),
      ),
      body: Row(
        children: [
          // LEFT: Reorderable List
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.auto_awesome),
                    label: Text(_isLoading ? "Optimizing..." : "AI Suggest Optimization"),
                    onPressed: _isLoading ? null : _calculateRoute,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    header: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Drag to Reorder", style: Theme.of(context).textTheme.labelLarge),
                    ),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _waypoints.removeAt(oldIndex);
                        _waypoints.insert(newIndex, item);
                      });
                      _calculateRoute();
                    },
                    children: _waypoints.map((item) => ListTile(
                      key: ValueKey(item['id']),
                      leading: CircleAvatar(child: Text("${(item['original_index'] as int? ?? 0) + 1}")),
                      title: Text(item['name'] ?? ''),
                      subtitle: Text("${(item['lat'] as num?)?.toDouble() ?? 0.0}, ${(item['lng'] as num?)?.toDouble() ?? 0.0}"),
                      trailing: const Icon(Icons.drag_handle),
                    )).toList(),
                  ),
                ),
                if (_routeResult != null)


                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green[50],
                    child: Column(
                      children: [
                        Text("Optimization Result", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Duration: ${_routeResult!['total_duration']} min"),
                            const Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // RIGHT: Route Map (Visual Representation)
          Expanded(
            flex: 7,
              child:GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(45.9432, 24.9668),
                  zoom: 7,
                ),
                markers: _markers,
                polylines: _routeResult != null ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: _waypoints.map((e) => LatLng(
                      (e['lat'] as num?)?.toDouble() ?? 0.0, 
                      (e['lng'] as num?)?.toDouble() ?? 0.0
                    )).toList(),
                    color: Colors.blue,
                    width: 5,
                  ),
                } : {},
              ),
          ),
        ],
      ),
    );
  }
}
