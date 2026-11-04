// ignore_for_file: invalid_annotation_target, unreachable_switch_case
import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_response.freezed.dart';
part 'route_response.g.dart';

@freezed
sealed class RouteResponse with _$RouteResponse implements _$RouteResponse {
  /// Response from POST /v1/routes/calculate
  const factory RouteResponse({
    @JsonKey(name: 'route_id') required String routeId,
    @JsonKey(name: 'total_duration_seconds') required int totalDurationSeconds,
    @JsonKey(name: 'total_distance_meters') required int totalDistanceMeters,
    @Default([]) List<RouteSegment> segments,
    @Default([]) List<String> warnings,
  }) = _RouteResponse;

  factory RouteResponse.fromJson(Map<String, dynamic> json) => _$RouteResponseFromJson(json);
}

@freezed
sealed class RouteSegment with _$RouteSegment implements _$RouteSegment {
  /// Represents a calculated path between two points.
  const factory RouteSegment({
    @JsonKey(name: 'from_id') required String fromId,
    @JsonKey(name: 'to_id') required String toId,
    @JsonKey(name: 'duration_seconds') required int durationSeconds,
    @JsonKey(name: 'distance_meters') required int distanceMeters,
    required String polyline,
    @JsonKey(name: 'transport_mode') required String transportMode,
  }) = _RouteSegment;

  factory RouteSegment.fromJson(Map<String, dynamic> json) => _$RouteSegmentFromJson(json);
}
