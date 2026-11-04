import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/spot_card.dart';
import '../widgets/search_spot_dialog.dart';

class WishlistPage extends ConsumerStatefulWidget {
  final Function(String, Map<String, dynamic>)? onSuggestToProject;
  final Function(Map<String, dynamic>)? onAddFavorite;
  final List<Map<String, dynamic>>? availableProjects;

  const WishlistPage({
    super.key, 
    this.onSuggestToProject, 
    this.onAddFavorite,
    this.availableProjects,
  });

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  // UI State: Filter
  bool _showPendingOnly = false;
  
  // UI State: Mock Role (In real app, get from AuthProvider)
  bool _isPlannerMode = false;

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("許願池 (Wishlist)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (wishlist) {
          // Filter Logic
          final filteredList = _showPendingOnly
              ? wishlist.where((spot) => spot.status == SpotStatus.pending).toList()
              : wishlist;
              
          return Column(
            children: [
              // --- Filter Tab Bar ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.list, size: 16),
                      label: const Text("All Spots"),
                      selected: !_showPendingOnly,
                      onSelected: (val) => setState(() => _showPendingOnly = false),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.history_toggle_off, size: 16),
                      label: Text("Pending Approval (${wishlist.where((s) => s.status == SpotStatus.pending).length})"),
                      selected: _showPendingOnly,
                      onSelected: (val) => setState(() => _showPendingOnly = true),
                      selectedColor: Colors.orange.withOpacity(0.2),
                      side: _showPendingOnly ? const BorderSide(color: Colors.orange) : null,
                    ),
                  ],
                ),
              ),
              
              // --- Grid Content ---
              Expanded(
                child: filteredList.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _showPendingOnly ? "No pending wishes." : "Wishlist is empty.",
                            style: TextStyle(color: Colors.grey[500], fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = (constraints.maxWidth / 300).floor().clamp(1, 4);
                          return GridView.builder(
                            itemCount: filteredList.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemBuilder: (context, index) {
                              final spot = filteredList[index];
                              return SpotCard(
                                spot: spot,
                                isPlanner: _isPlannerMode,
                                onDelete: () {
                                   if (spot.creatorId == 'client_1' || _isPlannerMode) {
                                     ref.read(wishlistProvider.notifier).removeSpot(spot.id);
                                   }
                                },
                                onApprove: () {
                                  if (_isPlannerMode) {
                                    ref.read(wishlistProvider.notifier).approveSpot(spot.id);
                                  }
                                },
                                onSuggest: spot.status == SpotStatus.approved ? () => _showSuggestDialog(spot) : null,
                              );
                            },
                          );
                        }
                      ),
                    ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // --- Role Switcher (View as) ---
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("View as: ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Switch(
                    value: _isPlannerMode, 
                    onChanged: (val) => setState(() => _isPlannerMode = val),
                    activeThumbColor: Colors.blue,
                  ),
                  Text(
                    _isPlannerMode ? "Planner" : "Client", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13,
                      color: _isPlannerMode ? Colors.blue : Colors.green
                    )
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          // --- Make a Wish Button ---
          if (!_isPlannerMode)
            FloatingActionButton.extended(
              heroTag: "wish_btn",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SearchSpotDialog(
                    onSpotSelected: (spot) {
                      ref.read(wishlistProvider.notifier).addSpot(spot);
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Added '${spot.name}' to Wishlist"),
                          backgroundColor: Colors.green,
                        )
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Make a Wish"),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
        ],
      ),
    );
  }

  // --- Proposal Logic ---
  void _showSuggestDialog(Spot spot) {
    if (widget.availableProjects == null || widget.availableProjects!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No shared projects available.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Suggest to Project"),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.availableProjects!.length,
            itemBuilder: (context, index) {
              final proj = widget.availableProjects![index];
              return ListTile(
                title: Text(proj['name']),
                subtitle: Text(proj['isWatched'] ? "Observer View" : "Master View"),
                onTap: () {
                  widget.onSuggestToProject?.call(proj['id'], {
                    "id": spot.id,
                    "name": spot.name,
                    "lat": spot.latitude,
                    "lng": spot.longitude,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Suggested '${spot.name}' to ${proj['name']}"))
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

}

