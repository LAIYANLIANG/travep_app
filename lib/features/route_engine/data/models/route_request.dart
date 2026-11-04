// ignore_for_file: invalid_annotation_target, unreachable_switch_case
import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_request.freezed.dart';
part 'route_request.g.dart';

@freezed
sealed class RouteRequest with _$RouteRequest implements _$RouteRequest {
  /// Request body for POST /v1/routes/calculate
  /// 
  /// [mode] can be "OPTIMIZED" or "MAZE".
  /// [waypoints] is the list of spots to visit.
  const factory RouteRequest({
    required String mode,
    required List<Waypoint> waypoints,
    @Default(Constraints()) Constraints constraints,
  }) = _RouteRequest;

  factory RouteRequest.fromJson(Map<String, dynamic> json) => _$RouteRequestFromJson(json);
}

@freezed
sealed class Waypoint with _$Waypoint implements _$Waypoint {
  /// Represents a single location in the itinerary.
  /// 
  /// [id] matches the Firestore Document ID.
  /// [location] contains lat/lng.
  const factory Waypoint({
    required String id,
    required Location location,
    @JsonKey(name: 'duration_check') @Default(60) int durationCheck,
  }) = _Waypoint;

  factory Waypoint.fromJson(Map<String, dynamic> json) => _$WaypointFromJson(json);
}

@freezed
sealed class Location with _$Location implements _$Location {
  const factory Location({
    required double lat,
    required double lng,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
}

@freezed
sealed class Constraints with _$Constraints implements _$Constraints {
  const factory Constraints({
    @JsonKey(name: 'transport_mode') @Default('DRIVING') String transportMode,
    @JsonKey(name: 'avoid_tolls') @Default(false) bool avoidTolls,
  }) = _Constraints;

  factory Constraints.fromJson(Map<String, dynamic> json) => _$ConstraintsFromJson(json);
}
