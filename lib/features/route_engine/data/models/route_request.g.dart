// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteRequestImpl _$$RouteRequestImplFromJson(Map<String, dynamic> json) =>
    _$RouteRequestImpl(
      mode: json['mode'] as String,
      waypoints: (json['waypoints'] as List<dynamic>)
          .map((e) => Waypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      constraints: json['constraints'] == null
          ? const Constraints()
          : Constraints.fromJson(json['constraints'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RouteRequestImplToJson(_$RouteRequestImpl instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'waypoints': instance.waypoints,
      'constraints': instance.constraints,
    };

_$WaypointImpl _$$WaypointImplFromJson(Map<String, dynamic> json) =>
    _$WaypointImpl(
      id: json['id'] as String,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      durationCheck: (json['duration_check'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$$WaypointImplToJson(_$WaypointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'location': instance.location,
      'duration_check': instance.durationCheck,
    };

_$LocationImpl _$$LocationImplFromJson(Map<String, dynamic> json) =>
    _$LocationImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$$LocationImplToJson(_$LocationImpl instance) =>
    <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};

_$ConstraintsImpl _$$ConstraintsImplFromJson(Map<String, dynamic> json) =>
    _$ConstraintsImpl(
      transportMode: json['transport_mode'] as String? ?? 'DRIVING',
      avoidTolls: json['avoid_tolls'] as bool? ?? false,
    );

Map<String, dynamic> _$$ConstraintsImplToJson(_$ConstraintsImpl instance) =>
    <String, dynamic>{
      'transport_mode': instance.transportMode,
      'avoid_tolls': instance.avoidTolls,
    };
