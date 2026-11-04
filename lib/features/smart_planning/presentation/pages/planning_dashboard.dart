import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui; // For marker generation
import 'package:flutter/services.dart'; // For rootBundle/images
import '../../domain/services/smart_trip_service.dart';
import '../../../upload/domain/services/spot_registry_service.dart';
import '../widgets/planning_layout.dart';
import 'package:dio/dio.dart';

// Date: 2025-12-25
// Purpose: Main state container for the 3-pane planning interface.
// Handles: Favorites (Pane 1), Itinerary Editor (Pane 2), Map (Pane 3).
// Modes: MAZE, MANUAL, AI.

enum PlanningMode { maze, manual, ai }

class PlanningDashboard extends StatefulWidget {
  final PlanningMode mode;
  // Controlled visibility props
  final bool showLeftPane;
  final bool showMiddlePane;
  final List<Map<String, dynamic>> favorites;
  final bool mazeShowSpots;
  final bool mazeShowTrips;
  final SpotRegistryService registryService;
  final Map<String, dynamic>? initialProject;

  const PlanningDashboard({
    super.key, 
    required this.mode,
    required this.favorites,
    required this.registryService,
    this.initialProject,
    this.showLeftPane = true,
    this.showMiddlePane = true,
    this.mazeShowSpots = true,
    this.mazeShowTrips = true,
  });

  @override
  State<PlanningDashboard> createState() => _PlanningDashboardState();
}

class _PlanningDashboardState extends State<PlanningDashboard> {
  // --- Data State ---
  // Favorites Pane (Mock)
  // Tab Index: 0 = Spots, 1 = Trips
  int _favTabIndex = 0;

  // Favorites Pane (Mock Data Removed - Passed from Parent)


  // Editor Pane (Structured by Days for display, but flat list for reordering logic could be simpler)
  // Using a flat list of items where some are headers might be easier for ReorderableListView,
  // but to strictly follow the User's "Day" structure, let's keep a List of Objects.
  // Actually, ReorderableListView works best with a single list.
  // Let's use a List<PlannerItem> where PlannerItem can be a DayHeader or a Waypoint.
  
  List<PlannerItem> _plannerItems = [];
  
  // Safe Deletion Mode State
  bool _isDeleteMode = false;
  final Set<String> _selectedItemIds = {};

  // Map State
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // New State for Route Lines
  GoogleMapController? _mapController;

  // --- Maze State ---
  final Dio _dio = Dio();
  List<dynamic> _mazeItems = [];
  bool _isMazeLoading = false;
  final List<Map<String, String>> _breadcrumbs = [];
  
  
  // State for Multi-Color Routes
  final Map<int, List<LatLng>> _dailyRoutes = {};
  int _nextDisplayIndex = 1; // Static counter for POI numbering

  // Smart Trip State
  late SmartTripService _smartTripService;
  Map<String, dynamic>? _flightResult;
  bool _isFlightLoading = false;
  
  // UI Visibility State REMOVED (Controlled by Parent)

  @override
  void initState() {
    super.initState();
    _smartTripService = SmartTripService(_dio, baseUrl: 'http://127.0.0.1:8080');

    // Auto-load project if passed, or auto-load newest project if in Manual/AI mode
    if (widget.initialProject != null) {
      _loadProjectIntoEditor(widget.initialProject!);
    } else if (widget.mode != PlanningMode.maze) {
      final projects = widget.favorites.where((e) => e['type'] == 'PROJECT').toList();
      if (projects.isNotEmpty) {
        _loadProjectIntoEditor(projects.first);
      }
    }

    _updateMapVisuals();
    if (widget.mode == PlanningMode.maze) {
      _fetchHierarchy();
    }
  }

  @override
  void didUpdateWidget(covariant PlanningDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProject != null && widget.initialProject != oldWidget.initialProject) {
      setState(() {
        _loadProjectIntoEditor(widget.initialProject!);
      });
      _updateMapVisuals();
    }
  }

  void _loadProjectIntoEditor(Map<String, dynamic> project) {
    _dailyRoutes.clear();
    _plannerItems.clear();
    List<dynamic> projItems = project['items'] ?? [];
    int maxDisplayIndex = 0;
    for (var pItem in projItems) {
      if (pItem['type'].toString().contains('waypoint')) {
        int? currentDisplayIndex = pItem['displayIndex'];
        if (currentDisplayIndex != null && currentDisplayIndex > maxDisplayIndex) {
          maxDisplayIndex = currentDisplayIndex;
        }
        _plannerItems.add(PlannerItem(
          type: PlannerItemType.waypoint,
          id: pItem['id'] ?? 'uniq_${DateTime.now().microsecondsSinceEpoch}',
          name: pItem['name'],
          showName: pItem['showName'] ?? pItem['name'],
          lat: pItem['lat'] != null ? (pItem['lat'] as num).toDouble() : null,
          lng: pItem['lng'] != null ? (pItem['lng'] as num).toDouble() : null,
          displayIndex: currentDisplayIndex,
        ));
      } else if (pItem['type'].toString().contains('dayHeader')) {
        _plannerItems.add(PlannerItem(
          type: PlannerItemType.dayHeader,
          label: pItem['label'],
          id: pItem['id'] ?? 'hdr_${DateTime.now().microsecondsSinceEpoch}',
        ));
      }
    }
    _nextDisplayIndex = maxDisplayIndex + 1;
    _centerMapOnWaypoints();
  }

  void _centerMapOnWaypoints() {
    try {
      final firstWp = _plannerItems.firstWhere(
        (item) => item.type == PlannerItemType.waypoint && item.lat != null && item.lng != null && item.lat != 0.0,
        orElse: () => PlannerItem(type: PlannerItemType.waypoint),
      );
      if (firstWp.lat != null && firstWp.lng != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(firstWp.lat!, firstWp.lng!), 12.0),
        );
      }
    } catch (_) {}
  }

  Future<void> _fetchHierarchy([String? parentId, String? parentName, bool addBreadcrumb = true]) async {
    setState(() => _isMazeLoading = true);
    try {
      final url = 'http://127.0.0.1:8080/v1/places/hierarchy${parentId != null ? "?parent_id=$parentId" : ""}';
      final response = await _dio.get(url);
      
      setState(() {
        _mazeItems = response.data;
        if (addBreadcrumb && parentId != null && parentName != null) {
          _breadcrumbs.add({'id': parentId, 'name': parentName});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isMazeLoading = false);
    }
  }

  void _resetToRoot() {
    setState(() {
      _breadcrumbs.clear();
      _mazeItems = [];
    });
    _fetchHierarchy();
  }

  // --- Logic ---

  void _addToEditor(Map<String, dynamic> favItem) {
    setState(() {
      _dailyRoutes.clear(); // Invalidate real route on modification
      _plannerItems.add(PlannerItem(
        type: PlannerItemType.waypoint,
        id: favItem['id'] ?? 'loc_${DateTime.now().microsecondsSinceEpoch}',
        name: favItem['name'],
        lat: favItem['lat'],
        lng: favItem['lng'],
        displayIndex: _nextDisplayIndex++,
      ));
    });
    _updateMapVisuals();
  }



  // Helper for generating Numbered Markers
  Future<BitmapDescriptor> _createCustomMarkerBitmap(int number, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // MARKER SIZE SETTING (Adjust size here)
    const size = 36.0; // Reduced from 60 (User request: smaller)
    final paint = Paint()..color = color;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // Draw Circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw Border (White)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Slightly thinner border
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, borderPaint);
    
    // Draw Number
    textPainter.text = TextSpan(
      text: number.toString(),
      style: const TextStyle(
        fontSize: 16.0, // Reduced font size
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(
        (size - textPainter.width) / 2, 
        (size - textPainter.height) / 2
      )
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  // --- Building Panes ---

  Widget _buildFavoritesPane() {
    // Maze Mode Custom UI
    if (widget.mode == PlanningMode.maze) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs Header
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.home, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _resetToRoot,
                  ),
                  const SizedBox(width: 4),
                  ..._breadcrumbs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final crumb = entry.value;
                    final isLast = index == _breadcrumbs.length - 1;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        InkWell(
                          onTap: isLast ? null : () {
                             // Jump back: Remove breadcrumbs AFTER this index and fetch children of this node WITHOUT re-adding it.
                             setState(() {
                               _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
                             });
                             _fetchHierarchy(crumb['id'], crumb['name'], false); 
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              crumb['name']!,
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                color: isLast ? Colors.black : Colors.blue
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isMazeLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _mazeItems.length,
                    itemBuilder: (context, index) {
                      final item = _mazeItems[index];
                      final type = item['type'];
                      
                      IconData icon;
                      Color iconColor = Colors.grey;
                      
                      switch (type) {
                        case 'CONTINENT': icon = Icons.public; iconColor = Colors.green; break;
                        case 'REGION': icon = Icons.map; iconColor = Colors.teal; break;
                        case 'COUNTRY': icon = Icons.flag; iconColor = Colors.indigo; break;
                        case 'CITY': icon = Icons.location_city; iconColor = Colors.deepOrange; break;
                        case 'DISTRICT': icon = Icons. holiday_village; iconColor = Colors.brown; break;
                        case 'CATEGORY': icon = Icons.category; iconColor = Colors.purple; break;
                        case 'POI': icon = Icons.place; iconColor = Colors.red; break;
                        default: icon = Icons.help_outline;
                      }

                      return ListTile(
                        dense: true,
                        leading: Icon(icon, size: 20, color: iconColor),
                        title: Text(item['name'], style: const TextStyle(fontSize: 13)),
                        trailing: item['has_children'] 
                          ? const Icon(Icons.arrow_forward_ios, size: 12) 
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onPressed: () async {
                                double? lat = item['lat'];
                                double? lng = item['lng'];
                                
                                if (lat == null || lng == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("正在尋找座標...")));
                                  final coords = await widget.registryService.lookup(item['name']);
                                  if (coords != null) {
                                    lat = coords['lat'];
                                    lng = coords['lng'];
                                  }
                                }

                                _addToEditor({
                                  'id': item['id'],
                                  'name': item['name'],
                                  'lat': lat, 
                                  'lng': lng
                                });
                              },
                            ),
                        onTap: () {
                          if (item['has_children']) {
                            _fetchHierarchy(item['id'], item['name']);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Tab Bar
        Container(
          color: Colors.blue[100],
          child: Row(
            children: [
               Expanded(
                 child: InkWell(
                   onTap: () => setState(() => _favTabIndex = 0), // Spots
                   child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     color: _favTabIndex == 0 ? Colors.white : Colors.blue[100],
                     alignment: Alignment.center,
                     child: const Text("Spots", style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                 ),
               ),
               Expanded(
                 child: InkWell(
                   onTap: () => setState(() => _favTabIndex = 1), // Trips
                   child: Container(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     color: _favTabIndex == 1 ? Colors.white : Colors.blue[100],
                     alignment: Alignment.center,
                     child: const Text("Trips", style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                 ),
               ),
            ],
          ),
        ),
        
        // Content
        Expanded(
           child: _favTabIndex == 0 ? _buildSpotsList() : _buildTripsList(),
        ),
      ],
    );
  }

  Widget _buildSpotsList() {
    final spots = widget.favorites.where((item) => item['type'] != 'PROJECT').toList();
    if (spots.isEmpty) return const Center(child: Text("No Spots"));

    return ListView.builder(
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final item = spots[index];
        return ListTile(
          leading: const Icon(Icons.place, color: Colors.blue),
          title: Text(item['name']),
          subtitle: Text("Lat: ${item['lat']}, Lng: ${item['lng']}"),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: () => _addToEditor(item),
          ),
        );
      },
    );
  }

  Widget _buildTripsList() {
    final trips = widget.favorites.where((item) => item['type'] == 'PROJECT').toList();
    if (trips.isEmpty) return const Center(child: Text("No Projects"));

    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final project = trips[index];
        return Card(
           margin: const EdgeInsets.all(8),
           child: ListTile(
              leading: const Icon(Icons.map, color: Colors.orange),
              title: Text(project['name']),
              subtitle: Text("Items: ${(project['items'] as List).length}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                   _loadProjectIntoEditor(project);
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已載入行程: ${project['name']}")));
                });
                _updateMapVisuals();
              },
           ),
        );
      },
    );
  }

  Widget _buildEditorPane() {
    return Column(
      children: [
        // --- HEADER ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
             color: _isDeleteMode ? Colors.red[50] : Colors.white,
             border: Border(bottom: BorderSide(color: Colors.grey[200]!))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

               Expanded(
                 flex: 4,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        _isDeleteMode ? "Select Items" : "Itinerary Editor", 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: _isDeleteMode ? Colors.red[700] : Colors.black87
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_isDeleteMode)
                         Text(
                           "${_plannerItems.length} items", 
                           style: const TextStyle(fontSize: 11, color: Colors.grey),
                           overflow: TextOverflow.ellipsis,
                         ),
                   ],
                 ),
               ),
               const SizedBox(width: 8),
               // WRAPPED IN EXPANDED + SCROLLVIEW TO PREVENT OVERFLOW
               Expanded(
                 flex: 6,
                 child: SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   reverse: true, // Align to right by default
                   child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDeleteMode) ...[
                         TextButton(
                           onPressed: () { 
                              setState(() { 
                                 _isDeleteMode = false;
                                 _selectedItemIds.clear();
                              });
                           },
                           child: const Text("Cancel"),
                         ),
                         const SizedBox(width: 8),
                         ElevatedButton.icon(
                           onPressed: _selectedItemIds.isEmpty ? null : _deleteSelectedItems,
                           icon: const Icon(Icons.delete_outline, size: 18),
                           label: Text("Delete (${_selectedItemIds.length})"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.red,
                             foregroundColor: Colors.white,
                             disabledBackgroundColor: Colors.red[100],
                             disabledForegroundColor: Colors.white70,
                             elevation: 0,
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                           )
                         ),
                      ] else ...[
                         // EDIT TOGGLE
                         IconButton(
                           icon: const Icon(Icons.edit_outlined, color: Colors.black54),
                           tooltip: "Enter Delete Mode",
                           onPressed: () => setState(() => _isDeleteMode = true),
                         ),
                         // ADD DAY
                         IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                            tooltip: "Add New Day",
                            onPressed: () {
                               setState(() {
                                 _plannerItems.add(PlannerItem(
                                    type: PlannerItemType.dayHeader, 
                                    label: "New Day",
                                    id: 'hdr_${DateTime.now().microsecondsSinceEpoch}'
                                 ));
                               });
                            },
                         ),
                         // SAVE
                         IconButton(
                            icon: const Icon(Icons.save_outlined, color: Colors.teal),
                            tooltip: "Save Project",
                            onPressed: _showSaveDialog,
                         ),
                         // SETTINGS
                         IconButton(
                            icon: const Icon(Icons.settings, color: Colors.purple),
                            tooltip: "Trip Settings",
                            onPressed: _showTripSettingsDialog,
                         ),
                      ]
                   ],
                 ),
               )
             )
            ],
          ),
        ),

        // --- FLIGHT RESULT CARD ---
        if (_isFlightLoading)
          const LinearProgressIndicator(),
        if (_flightResult != null)
           Container(
             margin: const EdgeInsets.all(8),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.blue[50],
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.blue[200]!)
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Row(children: [Icon(Icons.flight_takeoff, size: 16), SizedBox(width:8), Text("Recommended Flight", style: TextStyle(fontWeight: FontWeight.bold))]),
                 const SizedBox(height: 4),
                 if ((_flightResult!['flights'] as List).isNotEmpty)
                    Text("Total Price: TWD ${_flightResult!['flights'][0]['price']['total']}")
                 else
                    const Text("No matching flights found within budget."),
                 
                 TextButton(onPressed: (){}, child: const Text("View All Options"))
               ],
             ),
           ),

        // --- LIST ---
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles: !_isDeleteMode,
            onReorder: (oldIndex, newIndex) {
              if (_isDeleteMode) return;
              setState(() {
                _dailyRoutes.clear(); 
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _plannerItems.removeAt(oldIndex);
                _plannerItems.insert(newIndex, item);
              });
              _updateMapVisuals();
            },
            children: _plannerItems.asMap().map((index, item) {
               // Ensure ID Stability for logic (assignments here persist)
               item.id ??= "gen_${DateTime.now().microsecondsSinceEpoch}_$index";
               
               Widget content;
               
               if (item.type == PlannerItemType.dayHeader) {
                 // Counter logic
                 int dayIndex = 0;
                 for (var i = 0; i <= index; i++) {
                   if (_plannerItems[i].type == PlannerItemType.dayHeader) dayIndex++;
                 }
                 String displayLabel = item.label ?? "New Day";
                 if (displayLabel == "New Day") displayLabel = "Day $dayIndex";

                 content = Container(
                   color: _selectedItemIds.contains(item.id) 
                      ? Colors.red[50] 
                      : (_isDeleteMode ? Colors.grey[50] : Colors.blue[50]),
                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                   child: Row(
                     children: [
                        if (_isDeleteMode)
                          Checkbox(
                            value: _selectedItemIds.contains(item.id),
                            activeColor: Colors.red,
                            onChanged: (val) {
                               setState(() {
                                  if (val == true) {
                                    _selectedItemIds.add(item.id!);
                                  } else {
                                    _selectedItemIds.remove(item.id!);
                                  }
                               });
                            },
                          )
                        else
                          // MOVED EYE TO LEFT
                          InkWell(
                            onTap: () async {
                               item.isVisible = !item.isVisible;
                               setState(() {});
                               await _updateMapVisuals();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                item.isVisible ? Icons.visibility : Icons.visibility_off,
                                size: 18, 
                                color: item.isVisible ? Colors.blue : Colors.grey
                              ),
                            ),
                          ),

                        Expanded(
                          child: TextFormField(
                            key: ValueKey("header_field_${item.id}"), // Stable Key
                            enabled: !_isDeleteMode,
                            initialValue: displayLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: const InputDecoration.collapsed(hintText: "Day Name"),
                            onChanged: (val) => item.label = val,
                          ),
                        ),
                     ],
                   ),
                 );
               } else {
                 // WAYPOINT
                  // Calculate Continuous Index
                 int waypointCount = 0;
                 for (var i = 0; i < index; i++) {
                   if (_plannerItems[i].type == PlannerItemType.waypoint) waypointCount++;
                 }
                 final currentDisplayIndex = waypointCount + 1;

                 content = Container(
                   color: _selectedItemIds.contains(item.id) ? Colors.red[50] : Colors.white,
                   child: ListTile(
                     dense: true,
                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                     leading: _isDeleteMode 
                       ? Checkbox(
                           value: _selectedItemIds.contains(item.id),
                           activeColor: Colors.red,
                           onChanged: (val) {
                               setState(() {
                                  if (val == true) {
                                    _selectedItemIds.add(item.id!);
                                  } else {
                                    _selectedItemIds.remove(item.id!);
                                  }
                               });
                           },
                         )
                       : CircleAvatar(
                           radius: 10, 
                           backgroundColor: Colors.blue[100], 
                           child: Text("$currentDisplayIndex", style: const TextStyle(fontSize: 9, color: Colors.blue))
                         ),
                     title: Text(
                       item.showName ?? item.name ?? "Unknown", 
                       style: const TextStyle(fontSize: 13),
                       overflow: TextOverflow.ellipsis
                     ),
                     trailing: _isDeleteMode ? null : const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
                   ),
                 );
               }

               return MapEntry(index, KeyedSubtree(
                  key: ObjectKey(item), // CRITICAL: Use ObjectKey for ReorderableListView
                  child: content
               ));

            }).values.toList(),
          ),
        ),
        // Action Button Config based on Mode
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
               if (widget.mode == PlanningMode.ai) ...[
                 ElevatedButton.icon(
                   icon: const Icon(Icons.auto_awesome),
                   label: const Text("AI Optimize"),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[100]),
                   onPressed: () => _handleRouteAction(isOptimize: true),
                 ),
               ] else ...[
                 ElevatedButton.icon(
                   icon: const Icon(Icons.check),
                   label: const Text("Confirm Route"),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
                   onPressed: () => _handleRouteAction(isOptimize: false),
                 ),
               ]
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItemIds.isEmpty) return;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
         title: const Text("Confirm Deletion"),
         content: Text("Are you sure you want to delete ${_selectedItemIds.length} items?"),
         actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.white
              ), 
              child: const Text("Delete")
            ),
         ],
      )
    );
    
    if (confirm == true) {
      setState(() {
        _plannerItems.removeWhere((item) => _selectedItemIds.contains(item.id));
        _selectedItemIds.clear();
        _isDeleteMode = false;
        
        // Invalidate routes if we deleted something
        _dailyRoutes.clear();
      });
      _updateMapVisuals();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected items deleted."))
        );
      }
    }
  }

  Future<void> _showSaveDialog() async {
    final TextEditingController nameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Project"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Save your current itinerary to Favorites."),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: "Project Name",
                    border: OutlineInputBorder(),
                    hintText: "e.g., Tokyo Spring Trip",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Name cannot be empty";
                    }
                    if (value.length > 150) {
                      return "Name too long (max 150)";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final String projectName = nameController.text.trim();
                  
                  // Serialize Project Data
                  final newProject = {
                    "id": "proj_${DateTime.now().millisecondsSinceEpoch}",
                    "name": projectName,
                    "type": "PROJECT",
                    "lat": 0.0, // Projects don't have single loc
                    "lng": 0.0,
                    "items": _plannerItems.map((e) => {
                      "type": e.type.toString(),
                      "id": e.id,
                      "name": e.name,
                      "showName": e.showName,
                      "lat": e.lat,
                      "lng": e.lng,
                      "displayIndex": e.displayIndex // SAVE Numbering
                    }).toList(),
                  };
                  
                  // Check for duplicates
                  final int existingIndex = widget.favorites.indexWhere((item) => item['type'] == 'PROJECT' && item['name'] == projectName);
                  
                  if (existingIndex != -1) {
                      // Ask for confirmation
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                           title: const Text("Project Exists"),
                           content: Text("A project named '$projectName' already exists. Overwrite it?"),
                           actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), child: const Text("Overwrite")),
                           ],
                        )
                      );
                      
                      if (confirm != true) return; // User cancelled
                      
                      // Overwrite
                      setState(() {
                         widget.favorites[existingIndex] = newProject;
                         _favTabIndex = 1;
                      });
                  } else {
                      // New Save
                      setState(() {
                        widget.favorites.insert(0, newProject); // Add to top of Favorites
                        _favTabIndex = 1; // Auto-switch to Trips tab
                      });
                  }
                  
                  Navigator.pop(context); // Close Save Dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Project '$projectName' saved!"),
                      backgroundColor: Colors.teal,
                    )
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // --- Smart Trip Dialog ---
  Future<void> _showTripSettingsDialog() async {
    final formKey = GlobalKey<FormState>();
    
    // Default Values
    String departureCity = "Taipei";
    String returnAirport = "TPE";
    String destCity = "Tokyo";
    if (_plannerItems.isNotEmpty && _plannerItems.first.name != null) {
       destCity = _plannerItems.first.name!;
    }
    
    DateTime startDate = DateTime.now().add(const Duration(days: 30));
    DateTime endDate = DateTime.now().add(const Duration(days: 35));
    String deptTime = "Morning";
    String retTime = "Afternoon";
    int budget = 5; // 50k

    await showDialog(
      context: context, 
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateSB) {
           return AlertDialog(
             title: const Text("Smart Trip Settings"),
             content: SingleChildScrollView(
               child: Form(
                 key: formKey,
                 child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Text("Configure flight & budget preferences.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                       const SizedBox(height: 16),
                       // Cities
                       TextFormField(
                         initialValue: departureCity,
                         decoration: const InputDecoration(labelText: "Departure City", hintText: "e.g. Taipei"),
                         onChanged: (v) => departureCity = v,
                       ),
                       TextFormField(
                         initialValue: destCity,
                         decoration: const InputDecoration(labelText: "Destination", hintText: "e.g. Tokyo"),
                         onChanged: (v) => destCity = v,
                       ),
                       TextFormField(
                         initialValue: returnAirport,
                         decoration: const InputDecoration(labelText: "Return Airport", hintText: "e.g. TPE"),
                         onChanged: (v) => returnAirport = v,
                       ),
                       const SizedBox(height: 16),
                       // Dates
                       Row(children: [
                          Expanded(child: InkWell(
                            onTap: () async {
                               final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: startDate);
                               if (d != null) setStateSB(() => startDate = d);
                            },
                            child: InputDecorator(decoration: const InputDecoration(labelText: "Start Date"), child: Text("${startDate.year}/${startDate.month}/${startDate.day}")),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(
                            initialValue: deptTime,
                            items: ["Morning", "Afternoon", "Evening", "Night"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => deptTime = v!,
                            decoration: const InputDecoration(labelText: "Time"),
                          ))
                       ]),
                       const SizedBox(height: 8),
                       Row(children: [
                          Expanded(child: InkWell(
                            onTap: () async {
                               final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: endDate);
                               if (d != null) setStateSB(() => endDate = d);
                            },
                            child: InputDecorator(decoration: const InputDecoration(labelText: "End Date"), child: Text("${endDate.year}/${endDate.month}/${endDate.day}")),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<String>(
                            initialValue: retTime,
                            items: ["Morning", "Afternoon", "Evening", "Night"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => retTime = v!,
                            decoration: const InputDecoration(labelText: "Time"),
                          ))
                       ]),
                       const SizedBox(height: 16),
                       // Budget
                       TextFormField(
                         initialValue: "5",
                         keyboardType: TextInputType.number,
                         decoration: const InputDecoration(labelText: "Budget (10k TWD)", suffixText: "萬"),
                         onChanged: (v) => budget = int.tryParse(v) ?? 0,
                       ),
                    ],
                 ),
               ),
             ),
             actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                      Navigator.pop(context); // Close
                      setState(() => _isFlightLoading = true);
                      
                      final result = await _smartTripService.searchSmartFlights(
                        departureCity: departureCity,
                        destination: destCity,
                        startDate: startDate.toIso8601String().split('T')[0],
                        endDate: endDate.toIso8601String().split('T')[0],
                        departureTimeInfo: deptTime,
                        returnTimeInfo: retTime,
                        budget: budget,
                        returnOrigin: destCity, 
                        returnDest: returnAirport
                      );

                      setState(() {
                        _flightResult = result;
                        _isFlightLoading = false;
                        
                        if (result != null && result['itinerary_outline'] != null) {
                           List<dynamic> outline = result['itinerary_outline'];
                           if (_plannerItems.isEmpty) {
                              for(var day in outline) {
                                 _plannerItems.add(PlannerItem(
                                   type: PlannerItemType.dayHeader,
                                   id: 'day_${day['day']}',
                                   label: day['title'] ?? "Day ${day['day']}"
                                 ));
                              }
                           }
                        }
                      });
                  },
                  child: const Text("Plan Trip")
                )
             ],
           );
        });
      }
    );
  }

  Future<void> _handleRouteAction({required bool isOptimize}) async {
    // 1. Resolve Missing Coordinates
    bool showBusy = false;
    for (var item in _plannerItems) {
      if (item.type == PlannerItemType.waypoint && (item.lat == null || item.lng == null)) {
        if (!showBusy) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("正在解析地點座標...")));
          showBusy = true;
        }
        final coords = await widget.registryService.lookup(item.name!);
        if (coords != null) {
          setState(() {
            item.lat = coords['lat'];
            item.lng = coords['lng'];
          });
        }
      }
    }

    // 2. Serialize Current Items (Strict Filtering)
    List<Map<String, dynamic>> waypointsPayload = [];
    
    // Filter only waypoints that have BOTH lat and lng
    int payloadIndex = 0;
    for (var item in _plannerItems) {
      if (item.type == PlannerItemType.waypoint) {
        if (item.lat != null && item.lng != null) {
          waypointsPayload.add({
            "id": item.id,
            "original_index": payloadIndex++, // Continuous index for backend
            "name": item.showName ?? item.name,
            "location": {"lat": item.lat, "lng": item.lng}
          });
        } else {
          debugPrint('⚠️ Fully excluding "${item.name}" from API payload - Missing Coords.');
        }
      }
    }

    if (waypointsPayload.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請至少加入 2 個有定位座標的景點才能計算路徑！"))
      );
      return;
    }

    try {
      debugPrint('🚀 Sending Validated Payload:');
      debugPrint('Mode: ${isOptimize ? "OPTIMIZED" : "MANUAL"}');
      debugPrint('Waypoints count: ${waypointsPayload.length}');
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing with backend...")));
      
      final response = await _dio.post(
        'http://127.0.0.1:8080/api/calculate_itinerary',
        data: {
          "session_id": "manual_opt",
          "waypoints": waypointsPayload,
          "optimize_for": "time"
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500, // Handle 400s manually
        ),
      );

      final data = response.data;
      
      // Update Planner Items (if optimized)
      if (isOptimize && data['optimized_waypoints'] != null) {
          final optimizedList = data['optimized_waypoints'] as List;
          
          List<PlannerItem> newItems = [];
          newItems.add(PlannerItem(type: PlannerItemType.dayHeader, label: "Day 1 (Optimized)"));
          
          for (var w in optimizedList) {
             final loc = w['location'] ?? {};
             
             // Try to find original item to preserve displayIndex
             int? originalDispIdx;
             try {
                originalDispIdx = _plannerItems.firstWhere((existing) => existing.id == w['id']).displayIndex;
             } catch (_) {}

             newItems.add(PlannerItem(
               type: PlannerItemType.waypoint,
               id: w['id'],
               name: w['name'],
               showName: w['name'],
               lat: loc['lat'],
               lng: loc['lng'],
               displayIndex: originalDispIdx ?? 0,
             ));
          }
          
          setState(() {
            _plannerItems = newItems;
          });
          _updateMapVisuals();
      }
      
      // Handle Route Polylines (Multi-Day or Single Optimized)
      // Logic: If optimized, we get one result, so Day 0.
      // If manual, we invoked this fn for the whole list? 
      // Wait, we need to rewrite _handleRouteAction to support splitting calls for Manual Mode.
      // But for now, let's keep it simple: If backend returns one list, we treat it as Day 0.
      // TO SUPPORT MULTI-DAY, we need to Change how we call the API.
      // The user wants colors PER DAY.
      // So... if !isOptimize (Manual), we should parse `_plannerItems` locally, identify Days, 
      // and call API N times.
      
      if (!isOptimize) {
         // Manual Mode: Split by Day and call API for each day
         _dailyRoutes.clear();
         List<List<Map<String, dynamic>>> dayBatches = [];
         
         // Build batches
         int currentBatchIdx = -1;
         for (var item in _plannerItems) {
            if (item.type == PlannerItemType.dayHeader) {
               currentBatchIdx++;
               dayBatches.add([]);
            } else if (item.type == PlannerItemType.waypoint && currentBatchIdx >= 0) {
               dayBatches[currentBatchIdx].add({
                 "id": item.id,
                 "name": item.showName ?? item.name,
                 "location": {"lat": item.lat, "lng": item.lng}
               });
            }
         }
         
         // Call API in parallel
         List<Future> futures = [];
         for (int i=0; i<dayBatches.length; i++) {
             if (dayBatches[i].length < 2) continue; // Skip single points
             
             futures.add(_dio.post(
                'http://127.0.0.1:8080/api/calculate_itinerary',
                options: Options(
                  headers: {'Content-Type': 'application/json'},
                  validateStatus: (status) => status! < 500
                ),
                data: { 
                  "session_id": "manual_batch", 
                  "waypoints": dayBatches[i],
                  "optimize_for": "time"
                }
             ).then((res) {
                 if (res.data['route_polyline'] != null) {
                    final polyList = res.data['route_polyline'] as List;
                    _dailyRoutes[i] = polyList.map((p) => LatLng(p['lat'], p['lng'])).toList();
                 }
             }));
         }
         await Future.wait(futures);
         await _updateMapVisuals(); 
         return; // Exit here for Manual Mode
      }

      // If Optimized, standard logic (Single Day/Global)
      if (data['route_polyline'] != null) {
          final polyList = data['route_polyline'] as List;
          setState(() {
             _dailyRoutes[0] = polyList.map((p) => LatLng(p['lat'], p['lng'])).toList();
          });
          _updateMapVisuals();
      }

      // --- Show AI Notices / Warnings ---
      List<dynamic>? notices = data['ai_notices'];
      if (notices != null && notices.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning_amber, color: Colors.orange), SizedBox(width: 8), Text("AI Travel Advisory")]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notices.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("• $n", style: const TextStyle(fontSize: 14)),
              )).toList(),
            ),
            actions: [
              TextButton(child: const Text("Understood"), onPressed: () => Navigator.pop(ctx))
            ],
          )
        );
      } else {
        // Only show simplesnackbar if no warnings
        if (isOptimize) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Route Optimized! No issues found.")));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Route Confirmed! Duration: ${data['total_duration']} min")));
        }
      }

    } catch (e) {
      debugPrint('❌ API Error Detail:');
      if (e is DioException) {
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("API 錯誤 (422): ${e.response?.data['detail'] ?? e.message}"))
        );
      } else {
        debugPrint('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("發生未知錯誤: $e")));
      }
      }
    }

  Future<void> _updateMapVisuals() async {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};
    
    // Continuous numbering for map markers
    int waypointCounter = 0;
    // Track current day (for coloring) and visibility
    int currentDayIndex = 0;
    bool currentDayVisible = true;

    for (var item in _plannerItems) {
      if (item.type == PlannerItemType.dayHeader) {
        currentDayVisible = item.isVisible;
        currentDayIndex++;
        continue;
      }
      
      if (item.lat != null && item.lng != null) {
        waypointCounter++; // Always increment counter to match Editor
        
        if (currentDayVisible) {
           final color = Colors.primaries[currentDayIndex % Colors.primaries.length];
           final markerBitmap = await _createCustomMarkerBitmap(waypointCounter, color);
           
           newMarkers.add(Marker(
             markerId: MarkerId(item.id ?? "marker_${item.name}"),
             position: LatLng(item.lat!, item.lng!),
             icon: markerBitmap,
             infoWindow: InfoWindow(title: item.showName ?? item.name),
           ));
        }
      }
    }

    // Add Polylines (Daily Routes)
    int dayCounter = 0;
    for (var item in _plannerItems) {
      if (item.type == PlannerItemType.dayHeader) {
         if (_dailyRoutes.containsKey(dayCounter)) {
            if (item.isVisible) {
              newPolylines.add(Polyline(
                polylineId: PolylineId("route_day_$dayCounter"),
                points: _dailyRoutes[dayCounter]!,
                color: Colors.primaries[dayCounter % Colors.primaries.length],
                width: 5,
              ));
            }
         }
         dayCounter++;
      }
    }
    
    // Special Case: If no headers exist but we have routes (e.g. single day implies index 0)
    if (_plannerItems.isEmpty || !_plannerItems.any((i) => i.type == PlannerItemType.dayHeader)) {
       if (_dailyRoutes.containsKey(0)) {
         newPolylines.add(Polyline(
           polylineId: const PolylineId("route_day_0"),
           points: _dailyRoutes[0]!,
           color: Colors.blue,
           width: 5,
         ));
       }
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  @override
  Widget build(BuildContext context) {
      // Buttons handled by Parent (HomePage)
      return PlanningLayout(
        leftPane: widget.mode == PlanningMode.maze 
          ? (widget.mazeShowSpots ? _buildSimplePane("Spots", Colors.blue[50]!, _buildSpotsList()) : null)
          : (widget.showLeftPane ? _buildFavoritesPane() : null),
        middlePane: widget.mode == PlanningMode.maze
          ? (widget.mazeShowTrips ? _buildSimplePane("Trips", Colors.orange[50]!, _buildTripsList()) : null)
          : (widget.showMiddlePane ? _buildEditorPane() : null),
        extraPanes: widget.mode == PlanningMode.maze 
          ? [
              if (widget.showLeftPane) _buildFavoritesPane(),
              if (widget.showMiddlePane) _buildEditorPane(),
            ]
          : [],
        rightPane: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(35.6895, 139.6917), // Default to Tokyo
            zoom: 10,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            _centerMapOnWaypoints();
          },
        ),
      );
  }

  Widget _buildSimplePane(String title, Color bg, Widget child) {
      return Column(
          children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: bg,
                  alignment: Alignment.center,
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(child: child),
          ],
      );
  }
}

// --- Data Models ---
enum PlannerItemType { dayHeader, waypoint }

class PlannerItem {
  final PlannerItemType type;
  String? id;
  String? name; // originalName
  String? showName;
  String? label; // For headers
  double? lat;
  double? lng;
  int? displayIndex; // Static number assigned on creation
  bool isVisible; // Controls map visibility (for dayHeader)

  PlannerItem({
    required this.type, 
    this.id, 
    this.name, 
    this.showName, 
    this.label, 
    this.lat, 
    this.lng, 
    this.displayIndex,
    this.isVisible = true,
  });
}
