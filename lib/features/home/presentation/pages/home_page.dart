import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/smart_planning/presentation/pages/planning_dashboard.dart';
import '../../../../features/smart_planning/presentation/pages/smart_planner_page.dart';
import '../../../../features/favorites/presentation/pages/favorites_page.dart';
import '../../../../features/wishlist/presentation/pages/wishlist_page.dart';
import '../../../upload/domain/services/spot_registry_service.dart';
import '../../../upload/presentation/pages/upload_page.dart';
import '../../../admin/presentation/pages/admin_page.dart';
import '../../../../features/social/presentation/pages/feed_page.dart';
import 'flights_search_page.dart';
import 'restaurants_page.dart';
import 'lodging_page.dart';
import '../../../../injection_container.dart';
import '../../../../features/payment/presentation/pages/billing_page.dart';
import '../../../../core/utils/web_navigation_listener.dart';

// Date: 2025-12-25
// Purpose: Main entry point ensuring Sidebar navigation and content switching.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Current selected index for the sidebar
  int _selectedIndex = 0;
  final bool _isSidebarVisible = true; // State for sidebar visibility
  
  // Dashboard Visibility State (Lifted Up)
  bool _dashShowLeft = true;
  bool _dashShowMiddle = true;
  
  // Maze Mode Specific Visibility
  bool _mazeShowSpots = true;
  bool _mazeShowTrips = true;

  // Favorites Page Specific Visibility
  bool _favShowAllSpots = true;
  bool _favShowByRegion = true;
  bool _favShowSavedProjects = true;
  
  bool _areTogglesExpanded = false; // State for expanding floating buttons
  bool _isMenuCollapsed = false;   // State for sidebar "Rail" mode

  late final SpotRegistryService _registryService;
  Map<String, dynamic>? _activeProject; // Currently focused/applied project for Optimizer

  @override
  void initState() {
    super.initState();
    // 1. Resolve initial page directly from URL (?page=11 or #page=11)
    final initialPage = _resolveInitialPageIndex();
    if (initialPage != null) {
      _selectedIndex = initialPage;
      updateWebUrl(initialPage);
    }

    _registryService = sl<SpotRegistryService>();
    _loadFavorites();
    
    // 2. Listen for cross-frame navigation messages from Astro / Qiankun & dynamic URL changes
    listenToWebNavigation((targetIndex) {
      if (mounted && targetIndex >= 0 && targetIndex < _menuItems.length) {
        setState(() {
          _selectedIndex = targetIndex;
        });
      }
    });
  }

  void _navigateToPage(int index) {
    if (index >= 0 && index < _menuItems.length) {
      setState(() {
        _selectedIndex = index;
      });
      updateWebUrl(index);
    }
  }

  int? _resolveInitialPageIndex() {
    try {
      final uri = Uri.base;
      final pageParam = uri.queryParameters['page'] ?? uri.queryParameters['p'];
      if (pageParam != null) {
        final idx = int.tryParse(pageParam);
        if (idx != null && idx >= 0 && idx < _menuItems.length) return idx;
      }
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        String cleanFrag = fragment;
        if (cleanFrag.startsWith('/')) cleanFrag = cleanFrag.substring(1);
        if (cleanFrag.startsWith('page=')) cleanFrag = cleanFrag.substring(5);
        final idx = int.tryParse(cleanFrag);
        if (idx != null && idx >= 0 && idx < _menuItems.length) return idx;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString('user_favorites');
    if (favsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(favsJson);
        setState(() {
          _favorites.clear();
          _favorites.addAll(decoded.cast<Map<String, dynamic>>());
        });
      } catch (e) {
        debugPrint("Error loading favorites: $e");
      }
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String favsJson = jsonEncode(_favorites);
    await prefs.setString('user_favorites', favsJson);
  }

  // LIFTED STATE: Favorites Data (Shared between Favorites Page & Planner)
  final List<Map<String, dynamic>> _favorites = [
    {'id': 'fav1', 'name': '上野三井花園飯店', 'lat': 35.7115, 'lng': 139.7780},
    {'id': 'fav2', 'name': '明治神宮', 'lat': 35.6764, 'lng': 139.6993},
    {'id': 'fav3', 'name': '東京鐵塔', 'lat': 35.6586, 'lng': 139.7454},
    {'id': 'fav4', 'name': '東京哈利利波特影城', 'lat': 35.7488, 'lng': 139.5218},
    {'id': 'fav5', 'name': '東京車站', 'lat': 35.6812, 'lng': 139.7671},
    {'id': 'fav6', 'name': '山下公園', 'lat': 35.4455, 'lng': 139.6506},
    {'id': 'fav7', 'name': '橫濱紅磚倉庫', 'lat': 35.4526, 'lng': 139.6429},
    {'id': 'fav8', 'name': '羽田機場', 'lat': 35.5494, 'lng': 139.7798},
    // Mock Project
    {
      "id": "proj_demo_1",
      "name": "東京五日遊 (Demo)",
      "type": "PROJECT",
      "lat": 0.0,
      "lng": 0.0,
      "isWatched": false, // Current user is MASTER
      "proposals": [], // Suggested spots from others
      "items": [
         {"type": "PlannerItemType.dayHeader", "label": "Day 1: Arrival"},
         {"type": "PlannerItemType.waypoint", "id": "fav8", "name": "羽田機場", "lat": 35.5494, "lng": 139.7798},
         {"type": "PlannerItemType.waypoint", "id": "fav1", "name": "上野三井花園飯店", "lat": 35.7115, "lng": 139.7780},
         {"type": "PlannerItemType.dayHeader", "label": "Day 2: City Tour"},
         {"type": "PlannerItemType.waypoint", "id": "fav3", "name": "東京鐵塔", "lat": 35.6586, "lng": 139.7454},
      ],
    },
    {
      "id": "proj_watched_1",
      "name": "京都三日遊 (Watched)",
      "type": "PROJECT",
      "lat": 0.0,
      "lng": 0.0,
      "isWatched": true, // Current user is OBSERVER
      "proposals": [
        {"id": "prop_1", "name": "清水寺", "lat": 34.9949, "lng": 135.7850},
      ],
      "items": [
         {"type": "PlannerItemType.dayHeader", "label": "Day 1"},
         {"type": "PlannerItemType.waypoint", "id": "京都1", "name": "金閣寺", "lat": 35.0394, "lng": 135.7292},
      ],
    }
  ];

  // Update state with new favorite spot
  void _addFavorite(Map<String, dynamic> item) {
    setState(() {
      _favorites.add(item);
    });
    _saveFavorites();
  }

  // Update state with a new proposal for a project
  void _proposeToProject(String projectId, Map<String, dynamic> spot) {
    setState(() {
      final projIdx = _favorites.indexWhere((e) => e['id'] == projectId);
      if (projIdx != -1) {
        final proposals = _favorites[projIdx]['proposals'] as List;
        proposals.add(spot);
      }
    });
    _saveFavorites();
  }

  // Handle Bulk Uploaded Spot
  void _handleBulkUpload(String projectName, String dayLabel, String spotName, double lat, double lng) {
    setState(() {
      // 1. Find or Create Project
      int projIdx = _favorites.indexWhere((e) => e['name'] == projectName && e['type'] == 'PROJECT');
      if (projIdx == -1) {
        _favorites.add({
          "id": "proj_${DateTime.now().millisecondsSinceEpoch}_${_favorites.length}",
          "name": projectName,
          "type": "PROJECT",
          "lat": lat,
          "lng": lng,
          "isWatched": false,
          "proposals": [],
          "items": [],
        });
        projIdx = _favorites.length - 1;
      }

      final project = _favorites[projIdx];
      final List items = project['items'] as List;

      // 2. Find or Create Day Header
      int dayIdx = items.indexWhere((item) => item['type'] == 'PlannerItemType.dayHeader' && item['label'] == dayLabel);
      if (dayIdx == -1) {
        items.add({"type": "PlannerItemType.dayHeader", "label": dayLabel});
        dayIdx = items.length - 1;
      }

      // 3. Add Waypoint after the day header (or at the end of that day's block)
      // For simplicity, we just add it to the end of the items list
      items.add({
        "type": "PlannerItemType.waypoint",
        "id": "up_${DateTime.now().millisecondsSinceEpoch}_${items.length}",
        "name": spotName,
        "lat": lat,
        "lng": lng,
      });

      // 4. Also add to global "All Spots" for the Registry logic
      if (!_favorites.any((e) => e['name'] == spotName && e['type'] != 'PROJECT')) {
        _favorites.insert(0, {
          'id': 'fav_up_${DateTime.now().millisecondsSinceEpoch}', 
          'name': spotName, 
          'lat': lat, 
          'lng': lng
        });
      }
    });
    _saveFavorites();
  }

  void _handleAIPlanAccepted(String projectName, List<Map<String, dynamic>> items) {
    setState(() {
      final newProject = {
        "id": "ai_${DateTime.now().millisecondsSinceEpoch}",
        "name": projectName,
        "type": "PROJECT",
        "lat": 0.0,
        "lng": 0.0,
        "items": items.map((item) {
          if (item['id'] == null) {
            item['id'] = "ai_item_${DateTime.now().microsecondsSinceEpoch}_${items.indexOf(item)}";
          }
          return item;
        }).toList(),
      };
      _favorites.insert(0, newProject);
      _activeProject = newProject;
      _selectedIndex = 9; // Switch to Global Optimizer (Manual)
    });
    updateWebUrl(9);
    _saveFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已套用行程: $projectName。已為您載入 Global Optimizer (Manual)。'),
        backgroundColor: Colors.green,
      )
    );
  }


  // List of Menu Items
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': '首頁 (Home)'}, // 0
    {'icon': Icons.hotel, 'label': '住宿 (Lodging)'}, // 1
    {'icon': Icons.restaurant, 'label': '餐廳 (Restaurants)'}, // 2
    {'icon': Icons.flight, 'label': '機票 (Flights)'}, // 3
    {'icon': Icons.attractions, 'label': '景點 (Attractions)'}, // 4
    {'icon': Icons.favorite, 'label': '我的最愛 (Favorites)'}, // 5
    {'icon': Icons.volunteer_activism, 'label': '許願池 (Wishlist)'}, // 6 (New)
    {'icon': Icons.file_upload, 'label': '上傳景點 (Upload)'}, // 7 (New)
    {'icon': Icons.explore, 'label': 'Exploration Mode (Maze)', 'hidden': true}, // 8 (Planning)
    {'icon': Icons.edit_road, 'label': 'Global Optimizer (Manual)'}, // 9 (Planning)
    {'icon': Icons.auto_awesome, 'label': 'Global Optimizer (AI)', 'hidden': true}, // 10 (Planning)
    {'icon': Icons.psychology_alt, 'label': 'Smart Trip Planner'}, // 11 (AI Logic)
    {'icon': Icons.person, 'label': '個人帳號 (Account)'}, // 12
    {'icon': Icons.language, 'label': '語言 (Language)'}, // 13
    {'icon': Icons.payment, 'label': '繳費管理 (Billing)'}, // 14
    {'icon': Icons.admin_panel_settings, 'label': '後台管理 (Admin)'}, // 15
    {'icon': Icons.public, 'label': '社群動態 (Social)'}, // 16
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // --- Left Sidebar ---
              if (_isSidebarVisible)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isMenuCollapsed ? 70 : 250,
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      const SizedBox(height: 80), // Padding for buttons
                      if (!_isMenuCollapsed)
                        Text("Travep", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            if (item['hidden'] == true) return const SizedBox.shrink();

                            final isSelected = _selectedIndex == index;
                            return ListTile(
                              leading: Icon(item['icon'] as IconData, color: isSelected ? Colors.blue : Colors.grey),
                              title: _isMenuCollapsed ? null : Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.blue : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                              onTap: () => _navigateToPage(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isSidebarVisible) const VerticalDivider(width: 1),

              // --- Right Content Area ---
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
          
          // --- Floating Sidebar Toggle (Menu) ---
          Positioned(
            top: 16,
            left: 16,
            child: Material(
              color: Colors.blue, // Theme color
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                   setState(() {
                     _areTogglesExpanded = !_areTogglesExpanded;
                     // Optional: Also toggle sidebar if desired, but user asked for expansion
                     // _isSidebarVisible = !_isSidebarVisible; 
                   });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _areTogglesExpanded ? 0.25 : 0,
                    child: const Icon(Icons.menu, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),

          // --- Universal Sidebar Toggle (Red Home Circle) ---
          if (_areTogglesExpanded) ...[
            Positioned(
              top: 16,
              left: 80, // It will be the first button after Menu
              child: Tooltip(
                message: "Toggle Sidebar (收折選單)",
                child: Material(
                  color: Colors.red.shade400,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _isMenuCollapsed = !_isMenuCollapsed;
                        _areTogglesExpanded = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.home, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Dashboard Toggles (Only for Planning Modes)
          if (_selectedIndex >= 8 && _selectedIndex <= 10) ...[
              // Maze Mode: 4 buttons (Spots, Trips, Favorites, Editor)
              if (_selectedIndex == 8 && _areTogglesExpanded) ...[
                Positioned(
                  top: 16,
                  left: 144, // Shifted by 64 to make room for Home
                  child: Tooltip(
                    message: "Toggle Spots",
                    child: Material(
                      color: _mazeShowSpots ? Colors.green : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _mazeShowSpots = !_mazeShowSpots),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.place, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 208,
                  child: Tooltip(
                    message: "Toggle Trips",
                    child: Material(
                      color: _mazeShowTrips ? Colors.orange : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _mazeShowTrips = !_mazeShowTrips),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.map, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 272,
                  child: Tooltip(
                    message: "Toggle Favorites",
                    child: Material(
                      color: _dashShowLeft ? Colors.purple : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _dashShowLeft = !_dashShowLeft),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.bookmarks, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 336,
                  child: Tooltip(
                    message: "Toggle Editor",
                    child: Material(
                      color: _dashShowMiddle ? Colors.blue : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _dashShowMiddle = !_dashShowMiddle),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.edit_location_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Manual/AI Mode: 2 buttons (Library, Editor)
              if ((_selectedIndex == 9 || _selectedIndex == 10) && _areTogglesExpanded) ...[
                Positioned(
                  top: 16,
                  left: 144, // Shifted by 64
                  child: Tooltip(
                    message: "Toggle Library",
                    child: Material(
                      color: _dashShowLeft ? Colors.orange : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _dashShowLeft = !_dashShowLeft),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.bookmarks, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 208,
                  child: Tooltip(
                    message: "Toggle Editor",
                    child: Material(
                      color: _dashShowMiddle ? Colors.blue : Colors.grey,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _dashShowMiddle = !_dashShowMiddle),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.edit_location_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
          ],

          // Favorites Mode: 3 buttons (All Spots, By Region, Saved Projects)
          if (_selectedIndex == 5 && _areTogglesExpanded) ...[
            Positioned(
              top: 16,
              left: 144, // Shifted by 64
              child: Tooltip(
                message: "Toggle All Spots",
                child: Material(
                  color: _favShowAllSpots ? Colors.blue.shade300 : Colors.grey,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _favShowAllSpots = !_favShowAllSpots),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.place, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 208,
              child: Tooltip(
                message: "Toggle By Region",
                child: Material(
                  color: _favShowByRegion ? Colors.green.shade300 : Colors.grey,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _favShowByRegion = !_favShowByRegion),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.category, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 272,
              child: Tooltip(
                message: "Toggle Saved Projects",
                child: Material(
                  color: _favShowSavedProjects ? Colors.orange.shade300 : Colors.grey,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _favShowSavedProjects = !_favShowSavedProjects),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(Icons.folder_special, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Builder for the right-side content based on selection
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: // Home
        return _buildPushPage();
      case 1: // Lodging
        return const LodgingPage();
      case 2: // Restaurants
        return const RestaurantsPage();
      case 3: // Flights
        return const FlightSearchPage();
      case 5: // Favorites Page (3-Column Layout)
        return FavoritesPage(
          favorites: _favorites,
          showAllSpots: _favShowAllSpots,
          showByRegion: _favShowByRegion,
          showSavedProjects: _favShowSavedProjects,
        );
      case 6: // Wishlist
        return WishlistPage(
          onSuggestToProject: _proposeToProject,
          onAddFavorite: _addFavorite,
          availableProjects: _favorites
              .where((e) => e['type'] == 'PROJECT')
              .map((e) => {'id': e['id'], 'name': e['name'], 'isWatched': e['isWatched']})
              .toList(),
        );
      case 7: // Upload
        return UploadPage(
          registryService: _registryService,
          onUploadSuccess: _handleBulkUpload,
          existingProjectNames: _favorites
              .where((e) => e['type'] == 'PROJECT')
              .map((e) => e['name'] as String)
              .toList(),
        );
      case 8: // Maze
        return PlanningDashboard(
          mode: PlanningMode.maze, 
          showLeftPane: _dashShowLeft, 
          showMiddlePane: _dashShowMiddle,
          favorites: _favorites,
          mazeShowSpots: _mazeShowSpots,
          mazeShowTrips: _mazeShowTrips,
          registryService: _registryService,
        );
      case 9: // Manual
        return PlanningDashboard(
          mode: PlanningMode.manual, 
          showLeftPane: _dashShowLeft, 
          showMiddlePane: _dashShowMiddle,
          favorites: _favorites,
          registryService: _registryService,
          initialProject: _activeProject,
        );
      case 10: // AI
        return PlanningDashboard(
          mode: PlanningMode.ai, 
          showLeftPane: _dashShowLeft, 
          showMiddlePane: _dashShowMiddle,
          favorites: _favorites,
          registryService: _registryService,
          initialProject: _activeProject,
        );
      case 11: // Smart Trip Planner
        return SmartPlannerPage(
          onApplyPlan: _handleAIPlanAccepted,
        );
      case 14: // Billing
        return const BillingPage();
      case 15: // Admin
        return const AdminPage();
      case 16: // Social Feed
        return const FeedPage();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_menuItems[_selectedIndex]['icon'] as IconData, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Feature: ${_menuItems[_selectedIndex]['label']}", style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              const Text("Coming Soon", style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    }
  }

  // Definition of the "Right Side Push Page" (首頁的右邊為推播頁面)
  Widget _buildPushPage() {
    return Container(
      color: Colors.grey[50],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. Quick Launch Hero Cards (核心功能直達捷徑)
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              const Text(
                "核心功能直達 (Quick Launch)",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                "點擊卡片直接進入功能",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _buildQuickFeatureCard(
                  icon: Icons.psychology_alt,
                  iconColor: Colors.amber[800]!,
                  bgColor: Colors.amber[50]!,
                  borderColor: Colors.amber[300]!,
                  title: "🤖 AI 智慧行程規劃",
                  subtitle: "Smart Trip Planner (一鍵自動生成完整每日動線)",
                  badge: "推薦",
                  onTap: () => _navigateToPage(11),
                ),
                _buildQuickFeatureCard(
                  icon: Icons.edit_road,
                  iconColor: Colors.blue[700]!,
                  bgColor: Colors.blue[50]!,
                  borderColor: Colors.blue[300]!,
                  title: "🧭 全球路線優化器",
                  subtitle: "Global Optimizer (手動微調與高自由度路線排程)",
                  badge: "核心",
                  onTap: () => _navigateToPage(9),
                ),
                _buildQuickFeatureCard(
                  icon: Icons.favorite,
                  iconColor: Colors.pink[600]!,
                  bgColor: Colors.pink[50]!,
                  borderColor: Colors.pink[300]!,
                  title: "🧳 景點收藏與許願池",
                  subtitle: "Favorites & Wishlist (景點庫與個人收藏專案)",
                  badge: "必備",
                  onTap: () => _navigateToPage(5),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 16),
                    Expanded(child: cards[2]),
                  ],
                );
              } else {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                    const SizedBox(height: 12),
                    cards[2],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // 2. Development Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "開發與試作階段說明",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "目前本網站仍處於開發與試作階段，住宿、餐廳、機票、景點備在評估開放正式使用。",
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const Text(
                  "未來會上線功能包含：帳號、權限、朋友共同編輯、路線下載、留言社群。",
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const Text(
                  "另機票部份，尋求出票合作廠商～有興趣的請mail:windsong0910@gmail.com",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text("Welcome Back, Traveler!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Latest News & Promotions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(3, (index) => Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                   image: NetworkImage("https://picsum.photos/400/300"), // Placeholder images
                   fit: BoxFit.cover,
                ),
              ),
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Promotion Item #${index + 1}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )),
          )
        ],
      ),
    );
  }

  Widget _buildQuickFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              "立即開啟 ➔",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
