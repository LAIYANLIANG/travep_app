import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';

abstract class WishlistRepository {
  Stream<List<Spot>> getWishlist(String projectId);
  Future<void> addSpot(String projectId, Spot spot);
  Future<void> updateSpot(String projectId, Spot spot);
  Future<void> deleteSpot(String projectId, String spotId);
}
