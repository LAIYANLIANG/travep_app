import 'package:equatable/equatable.dart';

class Waypoint extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String mode; // 'walk', 'drive', 'transit'

  const Waypoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.mode = 'drive',
  });

  Waypoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? mode,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, mode];
}
