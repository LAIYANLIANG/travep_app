import 'package:flutter/material.dart';

class FavoritesPage extends StatefulWidget {
  final List<Map<String, dynamic>> favorites;
  final bool showAllSpots;
  final bool showByRegion;
  final bool showSavedProjects;

  const FavoritesPage({
    super.key, 
    required this.favorites,
    this.showAllSpots = true,
    this.showByRegion = true,
    this.showSavedProjects = true,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isDeleteMode = false;
  final Set<String> _selectedIds = {};

  // Toggle Delete Mode
  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      _selectedIds.clear(); // Clear selection when toggling
    });
  }

  // Handle Item Selection
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Delete Selected Items
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete ${_selectedIds.length} items?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        // 1. Separate Root IDs and Nested IDs
        final rootIds = <String>{};
        final nestedDeletions = <String, List<int>>{}; // ProjID -> [Indices]

        for (final id in _selectedIds) {
          if (id.contains('_CHILD_')) {
             final parts = id.split('_CHILD_');
             final projId = parts[0];
             final childIdx = int.parse(parts[1]);
             
             nestedDeletions.putIfAbsent(projId, () => []).add(childIdx);
          } else {
             rootIds.add(id);
          }
        }

        // 2. Perform Nested Deletions (High Index to Low)
        nestedDeletions.forEach((projId, indices) {
           final proj = widget.favorites.firstWhere((e) => e['id'] == projId, orElse: () => {});
           if (proj.isNotEmpty && proj['items'] != null) {
              final items = proj['items'] as List;
              indices.sort((a, b) => b.compareTo(a)); // Descending
              for (var idx in indices) {
                 if (idx >= 0 && idx < items.length) {
                    items.removeAt(idx);
                 }
              }
           }
        });

        // 3. Perform Root Deletions
        widget.favorites.removeWhere((item) => rootIds.contains(item['id']));
        
        _selectedIds.clear();
        _isDeleteMode = false; // Exit delete mode after deletion
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items Deleted")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Separate Spots and Projects
    final spots = widget.favorites.where((e) => e['type'] != 'PROJECT').toList();
    final projects = widget.favorites.where((e) => e['type'] == 'PROJECT').toList();

    return Scaffold(
      floatingActionButton: _isDeleteMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel Button
                FloatingActionButton.extended(
                  heroTag: "cancel_btn",
                  onPressed: () {
                    setState(() {
                      _isDeleteMode = false;
                      _selectedIds.clear();
                    });
                  },
                  label: const Text("Give Up"),
                  icon: const Icon(Icons.close),
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 16),
                // Delete Button
                FloatingActionButton.extended(
                  heroTag: "delete_btn",
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  label: Text("Delete (${_selectedIds.length})"),
                  icon: const Icon(Icons.delete),
                  backgroundColor: _selectedIds.isEmpty ? Colors.red.shade200 : Colors.red,
                ),
              ],
            )
          : FloatingActionButton.extended(
              heroTag: "manage_btn",
              onPressed: _toggleDeleteMode,
              label: const Text("Manage Items"),
              icon: const Icon(Icons.edit),
              backgroundColor: Colors.blue,
            ),
      body: Container(
        color: Colors.white,
        child: Row(
          children: [
            // --- Column 1: All Spots (Flat List) ---
            if (widget.showAllSpots)
              Expanded(
                child: _buildColumn(
                  title: "All Spots (景點)",
                  color: Colors.blue.shade50,
                  child: ListView.builder(
                    itemCount: spots.length,
                    itemBuilder: (context, index) {
                      final item = spots[index];
                      return _buildSelectableItem(
                        item['id'],
                        ListTile(
                          leading: const Icon(Icons.place, color: Colors.red),
                          title: Text(item['name']),
                          subtitle: Text("Lat: ${item['lat']}, Lng: ${item['lng']}"),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            if (widget.showAllSpots && (widget.showByRegion || widget.showSavedProjects))
              const VerticalDivider(width: 1),

            // --- Column 2: Hierarchy (Geographic) ---
            if (widget.showByRegion)
              Expanded(
                child: _buildColumn(
                  title: "By Region (區域分類)",
                  color: Colors.green.shade50,
                  child: _buildHierarchyTree(spots),
                ),
              ),

            if (widget.showByRegion && widget.showSavedProjects)
              const VerticalDivider(width: 1),

            // --- Column 3: Projects (Itineraries) ---
            if (widget.showSavedProjects)
              Expanded(
                child: _buildColumn(
                  title: "Saved Projects (旅遊專案)",
                  color: Colors.orange.shade50,
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final proj = projects[index];
                      return _buildSelectableItem(
                          proj['id'],
                          _buildProjectTile(proj),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableItem(String id, Widget content) {
    if (!_isDeleteMode) return content;

    final isSelected = _selectedIds.contains(id);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (val) => _toggleSelection(id),
      title: content,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildProjectTile(Map<String, dynamic> proj) {
     final items = proj['items'] as List<dynamic>;
     final bool isWatched = proj['isWatched'] ?? false;
     final List<dynamic> proposals = proj['proposals'] ?? [];
     
     return ExpansionTile(
        leading: Icon(
          isWatched ? Icons.visibility : Icons.map, 
          color: isWatched ? Colors.grey : Colors.blue
        ),
        title: Row(
          children: [
            Expanded(child: Text(proj['name'])),
            if (isWatched) 
              const Tooltip(
                message: "Read-only (Observer)",
                child: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
            if (!isWatched && proposals.isNotEmpty)
              Tooltip(
                message: "${proposals.length} New Proposals",
                child: Badge(
                  label: Text(proposals.length.toString()),
                  child: const Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange),
                ),
              ),
            const SizedBox(width: 8),
            // Sharing/Watch Toggle Placeholder
            IconButton(
              icon: Icon(isWatched ? Icons.person_add_disabled : Icons.person_add, size: 20),
              onPressed: () {
                // Feature Placeholder: Toggle sharing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isWatched ? "Unwatched" : "Sharing link copied!"))
                );
              },
            ),
          ],
        ),
        subtitle: Text("${items.length} items"),
        children: [
          // Render Proposals (Only for Master)
          if (!isWatched && proposals.isNotEmpty)
            ...proposals.map((prop) => Container(
              color: Colors.orange.shade50,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.new_releases, color: Colors.orange, size: 16),
                title: Text("Proposal: ${prop['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 18),
                      onPressed: () {
                        setState(() {
                          // Approve: Move to items and remove from proposals
                          items.add({
                            "type": "PlannerItemType.waypoint",
                            "id": prop['id'],
                            "name": prop['name'],
                            "lat": prop['lat'],
                            "lng": prop['lng']
                          });
                          proposals.remove(prop);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () {
                        setState(() {
                          proposals.remove(prop);
                        });
                      },
                    ),
                  ],
                ),
              ),
            )),
          
          // Render existing items
          ...items.asMap().entries.map((entry) {
             final idx = entry.key;
             final item = entry.value;
             final compositeId = "${proj['id']}_CHILD_$idx";
             
             // If watched, use a simple ListTile instead of selectable item
             if (isWatched) {
               return ListTile(
                dense: true,
                leading: Icon(
                   item['type'].toString().contains('dayHeader') ? Icons.calendar_today : Icons.place, 
                   size: 16, 
                   color: Colors.grey
                ),
                title: Text(item['type'].toString().contains('dayHeader') 
                    ? (item['label'] ?? "Day") 
                    : (item['name'] ?? "Unknown Point")),
               );
             }

             return _buildSelectableItem(
               compositeId,
               ListTile(
                dense: true,
                leading: Icon(
                   item['type'].toString().contains('dayHeader') ? Icons.calendar_today : Icons.place, 
                   size: 16, 
                   color: Colors.grey
                ),
                title: Text(item['type'].toString().contains('dayHeader') 
                    ? (item['label'] ?? "Day") 
                    : (item['name'] ?? "Unknown Point")),
               ),
             );
          }),
        ],
     );
  }

  Widget _buildColumn({required String title, required Color color, required Widget child}) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: color,
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        // Content
        Expanded(child: child),
      ],
    );
  }

  Widget _buildHierarchyTree(List<Map<String, dynamic>> spots) {
    // Hardcoded categorization for demo (since we lack real geo-data)
    // Map Spot ID/Name to Country/City
    
    // Grouping
    final Map<String, List<Map<String, dynamic>>> byCity = {
      'Tokyo (東京)': [],
      'Yokohama (橫濱)': [],
      'Others': []
    };

    for (var s in spots) {
      if (s['name'].toString().contains('東京') || s['name'].toString().contains('上野') || s['name'].toString().contains('明治') || s['name'].toString().contains('羽田')) {
         byCity["Tokyo (東京)"]!.add(s);
      } else if (s['name'].toString().contains('橫濱') || s['name'].toString().contains('山下')) {
         byCity["Yokohama (橫濱)"]!.add(s);
      } else {
         byCity["Others"]!.add(s);
      }
    }

    return ListView(
      children: [
         ExpansionTile(
            title: const Text("Asia (亞洲)"),
            initiallyExpanded: true,
            children: [
               ExpansionTile(
                  title: const Text("East Asia (東亞)"),
                  initiallyExpanded: true,
                  children: [
                     ExpansionTile(
                        title: const Text("Japan (日本)"),
                        initiallyExpanded: true,
                        children: byCity.entries.map((entry) {
                           if (entry.value.isEmpty) return const SizedBox.shrink();
                           return ExpansionTile(
                              title: Text(entry.key),
                              initiallyExpanded: true,
                              children: entry.value.map((s) => _buildSelectableItem(
                                s['id'],
                                ListTile(
                                 leading: const Icon(Icons.place, size: 16, color: Colors.grey),
                                 title: Text(s['name'], style: const TextStyle(fontSize: 14)),
                                 dense: true,
                              ))).toList(),
                           );
                        }).toList(),
                     ),
                  ],
               ),
            ],
         ),
      ],
    );
  }
}
