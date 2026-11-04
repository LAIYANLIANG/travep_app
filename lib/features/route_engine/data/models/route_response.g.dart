// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteResponseImpl _$$RouteResponseImplFromJson(Map<String, dynamic> json) =>
    _$RouteResponseImpl(
      routeId: json['route_id'] as String,
      totalDurationSeconds: (json['total_duration_seconds'] as num).toInt(),
      totalDistanceMeters: (json['total_distance_meters'] as num).toInt(),
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map((e) => RouteSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warnings:
          (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RouteResponseImplToJson(_$RouteResponseImpl instance) =>
    <String, dynamic>{
      'route_id': instance.routeId,
      'total_duration_seconds': instance.totalDurationSeconds,
      'total_distance_meters': instance.totalDistanceMeters,
      'segments': instance.segments,
      'warnings': instance.warnings,
    };

_$RouteSegmentImpl _$$RouteSegmentImplFromJson(Map<String, dynamic> json) =>
    _$RouteSegmentImpl(
      fromId: json['from_id'] as String,
      toId: json['to_id'] as String,
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      distanceMeters: (json['distance_meters'] as num).toInt(),
      polyline: json['polyline'] as String,
      transportMode: json['transport_mode'] as String,
    );

Map<String, dynamic> _$$RouteSegmentImplToJson(_$RouteSegmentImpl instance) =>
    <String, dynamic>{
      'from_id': instance.fromId,
      'to_id': instance.toId,
      'duration_seconds': instance.durationSeconds,
      'distance_meters': instance.distanceMeters,
      'polyline': instance.polyline,
      'transport_mode': instance.transportMode,
    };
