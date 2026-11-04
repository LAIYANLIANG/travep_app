import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/wishlist_repository.dart';

part 'wishlist_provider.g.dart';

@riverpod
class Wishlist extends _$Wishlist {
  // Hardcoded Project ID for Feasibility Demo
  static const String _demoProjectId = 'demo_project_v1';

  @override
  Stream<List<Spot>> build() {
    final repo = sl<WishlistRepository>();
    return repo.getWishlist(_demoProjectId);
  }

  Future<void> addSpot(Spot spot) async {
    final repo = sl<WishlistRepository>();
    // Optimistic update could go here, but relying on Stream for simplicity
    await repo.addSpot(_demoProjectId, spot);
  }

  Future<void> removeSpot(String id) async {
    final repo = sl<WishlistRepository>();
    await repo.deleteSpot(_demoProjectId, id);
  }

  Future<void> approveSpot(String id) async {
    final repo = sl<WishlistRepository>();
    // We need to fetch the spot first to toggle? Or just pass id and update?
    // Repository updateSpot takes a Spot object. 
    // Ideally we update partial, but our Repo is simple.
    // Let's find the spot in current state.
    final currentList = state.valueOrNull;
    if (currentList != null) {
      final spot = currentList.firstWhere((s) => s.id == id);
      final updatedSpot = spot.copyWith(status: SpotStatus.approved);
      await repo.updateSpot(_demoProjectId, updatedSpot);
    }
  }
}
