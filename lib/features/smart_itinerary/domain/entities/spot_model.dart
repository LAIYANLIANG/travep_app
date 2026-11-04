import 'package:equatable/equatable.dart';

enum SpotStatus {
  pending,  // Wishlist / Draft
  approved, // Locked / Generic
}

enum SpotCategory {
  accommodation,
  restaurant,
  flight,
  spot,
  other,
}

class Spot extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? googlePlaceId;
  final SpotStatus status;
  final SpotCategory category;
  final String creatorId; // For permission checks
  final Map<String, dynamic> metadata; // Extra fields (rating, opening hours)

  const Spot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.googlePlaceId,
    this.status = SpotStatus.pending,
    this.category = SpotCategory.other,
    required this.creatorId,
    this.metadata = const {},
  });

  Spot copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? googlePlaceId,
    SpotStatus? status,
    SpotCategory? category,
    String? creatorId,
    Map<String, dynamic>? metadata,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      status: status ?? this.status,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      metadata: metadata ?? this.metadata,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'googlePlaceId': googlePlaceId,
      'status': status.name, // Convert enum to string
      'category': category.name, // Convert enum to string
      'creatorId': creatorId,
      'metadata': metadata,
    };
  }

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      googlePlaceId: json['googlePlaceId'] as String?,
      status: SpotStatus.values.firstWhere(
        (e) => e.name == json['status'], 
        orElse: () => SpotStatus.pending
      ),
      category: SpotCategory.values.firstWhere(
        (e) => e.name == json['category'], 
        orElse: () => SpotCategory.other
      ),
      creatorId: json['creatorId'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        address,
        googlePlaceId,
        status,
        category,
        creatorId,
        metadata,
      ];
}
