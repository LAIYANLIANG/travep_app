import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/wishlist_repository.dart';
import 'package:google_service_app/features/smart_itinerary/domain/entities/spot_model.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final FirebaseFirestore _firestore;

  WishlistRepositoryImpl(this._firestore);

  @override
  Stream<List<Spot>> getWishlist(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('spots')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Spot.fromJson(doc.data());
      }).toList();
    });
  }

  @override
  Future<void> addSpot(String projectId, Spot spot) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('spots')
        .doc(spot.id)
        .set(spot.toJson());
  }

  @override
  Future<void> updateSpot(String projectId, Spot spot) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('spots')
        .doc(spot.id)
        .update(spot.toJson());
  }

  @override
  Future<void> deleteSpot(String projectId, String spotId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('spots')
        .doc(spotId)
        .delete();
  }
}
