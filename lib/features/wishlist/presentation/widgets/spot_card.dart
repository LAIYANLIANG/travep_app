import 'package:flutter/material.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';

class SpotCard extends StatelessWidget {
  final Spot spot;
  final bool isPlanner; // To toggle Approve button
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onSuggest; // New: Suggest to Project

  const SpotCard({
    super.key,
    required this.spot,
    this.isPlanner = false,
    this.onDelete,
    this.onApprove,
    this.onSuggest,
  });

  bool get _isPending => spot.status == SpotStatus.pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Status Color Logic
    final statusColor = _isPending 
        ? Colors.orangeAccent 
        : Colors.green;
        
    final statusLabel = _isPending ? "Pending Request" : "Approved";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: _isPending ? Colors.orange.withOpacity(0.3) : Colors.transparent, 
          width: 2
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Placeholder
          Expanded(
             flex: 3,
             child: Container(
               decoration: BoxDecoration(
                 color: Colors.grey[200],
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                 image: spot.metadata['img'] != null
                    ? DecorationImage(
                        image: NetworkImage(spot.metadata['img']),
                        fit: BoxFit.cover,
                      )
                    : null,
               ),
               child: spot.metadata['img'] == null 
                  ? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)) 
                  : null,
             ),
          ),
          
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Chip
                      Row(
                        children: [
                          Icon(_getCategoryIcon(spot.category), size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel, 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spot.name, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (spot.metadata['rating'] != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(" ${spot.metadata['rating']}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        )
                    ],
                  ),
                  
                  // Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       if (_isPending && onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            tooltip: "Retract Wish",
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: onDelete,
                          ),
                       if (_isPending && isPlanner && onApprove != null)
                          const SizedBox(width: 8),
                       if (_isPending && isPlanner && onApprove != null)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                               backgroundColor: colorScheme.primary,
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                               visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text("Approve", style: TextStyle(fontSize: 12)),
                            onPressed: onApprove,
                          ),
                       if (!_isPending && onSuggest != null)
                          IconButton(
                            icon: const Icon(Icons.send_outlined, color: Colors.blue),
                            tooltip: "Suggest to Project",
                            onPressed: onSuggest,
                          ),
                       if (!_isPending && onSuggest == null)
                          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  IconData _getCategoryIcon(SpotCategory category) {
    switch (category) {
      case SpotCategory.accommodation: return Icons.hotel;
      case SpotCategory.restaurant: return Icons.restaurant;
      case SpotCategory.flight: return Icons.flight;
      case SpotCategory.spot: return Icons.camera_alt;
      case SpotCategory.other: return Icons.bookmark;
    }
  }
}
