// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteResponse _$RouteResponseFromJson(Map<String, dynamic> json) {
  return _RouteResponse.fromJson(json);
}

/// @nodoc
mixin _$RouteResponse {
  @JsonKey(name: 'route_id')
  String get routeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_duration_seconds')
  int get totalDurationSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_distance_meters')
  int get totalDistanceMeters => throw _privateConstructorUsedError;
  List<RouteSegment> get segments => throw _privateConstructorUsedError;
  List<String> get warnings => throw _privateConstructorUsedError;

  /// Serializes this RouteResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteResponseCopyWith<RouteResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteResponseCopyWith<$Res> {
  factory $RouteResponseCopyWith(
    RouteResponse value,
    $Res Function(RouteResponse) then,
  ) = _$RouteResponseCopyWithImpl<$Res, RouteResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'route_id') String routeId,
    @JsonKey(name: 'total_duration_seconds') int totalDurationSeconds,
    @JsonKey(name: 'total_distance_meters') int totalDistanceMeters,
    List<RouteSegment> segments,
    List<String> warnings,
  });
}

/// @nodoc
class _$RouteResponseCopyWithImpl<$Res, $Val extends RouteResponse>
    implements $RouteResponseCopyWith<$Res> {
  _$RouteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? totalDurationSeconds = null,
    Object? totalDistanceMeters = null,
    Object? segments = null,
    Object? warnings = null,
  }) {
    return _then(
      _value.copyWith(
            routeId: null == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalDurationSeconds: null == totalDurationSeconds
                ? _value.totalDurationSeconds
                : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDistanceMeters: null == totalDistanceMeters
                ? _value.totalDistanceMeters
                : totalDistanceMeters // ignore: cast_nullable_to_non_nullable
                      as int,
            segments: null == segments
                ? _value.segments
                : segments // ignore: cast_nullable_to_non_nullable
                      as List<RouteSegment>,
            warnings: null == warnings
                ? _value.warnings
                : warnings // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteResponseImplCopyWith<$Res>
    implements $RouteResponseCopyWith<$Res> {
  factory _$$RouteResponseImplCopyWith(
    _$RouteResponseImpl value,
    $Res Function(_$RouteResponseImpl) then,
  ) = __$$RouteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'route_id') String routeId,
    @JsonKey(name: 'total_duration_seconds') int totalDurationSeconds,
    @JsonKey(name: 'total_distance_meters') int totalDistanceMeters,
    List<RouteSegment> segments,
    List<String> warnings,
  });
}

/// @nodoc
class __$$RouteResponseImplCopyWithImpl<$Res>
    extends _$RouteResponseCopyWithImpl<$Res, _$RouteResponseImpl>
    implements _$$RouteResponseImplCopyWith<$Res> {
  __$$RouteResponseImplCopyWithImpl(
    _$RouteResponseImpl _value,
    $Res Function(_$RouteResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeId = null,
    Object? totalDurationSeconds = null,
    Object? totalDistanceMeters = null,
    Object? segments = null,
    Object? warnings = null,
  }) {
    return _then(
      _$RouteResponseImpl(
        routeId: null == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalDurationSeconds: null == totalDurationSeconds
            ? _value.totalDurationSeconds
            : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDistanceMeters: null == totalDistanceMeters
            ? _value.totalDistanceMeters
            : totalDistanceMeters // ignore: cast_nullable_to_non_nullable
                  as int,
        segments: null == segments
            ? _value._segments
            : segments // ignore: cast_nullable_to_non_nullable
                  as List<RouteSegment>,
        warnings: null == warnings
            ? _value._warnings
            : warnings // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteResponseImpl implements _RouteResponse {
  const _$RouteResponseImpl({
    @JsonKey(name: 'route_id') required this.routeId,
    @JsonKey(name: 'total_duration_seconds') required this.totalDurationSeconds,
    @JsonKey(name: 'total_distance_meters') required this.totalDistanceMeters,
    final List<RouteSegment> segments = const [],
    final List<String> warnings = const [],
  }) : _segments = segments,
       _warnings = warnings;

  factory _$RouteResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteResponseImplFromJson(json);

  @override
  @JsonKey(name: 'route_id')
  final String routeId;
  @override
  @JsonKey(name: 'total_duration_seconds')
  final int totalDurationSeconds;
  @override
  @JsonKey(name: 'total_distance_meters')
  final int totalDistanceMeters;
  final List<RouteSegment> _segments;
  @override
  @JsonKey()
  List<RouteSegment> get segments {
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_segments);
  }

  final List<String> _warnings;
  @override
  @JsonKey()
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  @override
  String toString() {
    return 'RouteResponse(routeId: $routeId, totalDurationSeconds: $totalDurationSeconds, totalDistanceMeters: $totalDistanceMeters, segments: $segments, warnings: $warnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteResponseImpl &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.totalDistanceMeters, totalDistanceMeters) ||
                other.totalDistanceMeters == totalDistanceMeters) &&
            const DeepCollectionEquality().equals(other._segments, _segments) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    routeId,
    totalDurationSeconds,
    totalDistanceMeters,
    const DeepCollectionEquality().hash(_segments),
    const DeepCollectionEquality().hash(_warnings),
  );

  /// Create a copy of RouteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteResponseImplCopyWith<_$RouteResponseImpl> get copyWith =>
      __$$RouteResponseImplCopyWithImpl<_$RouteResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteResponseImplToJson(this);
  }
}

abstract class _RouteResponse implements RouteResponse {
  const factory _RouteResponse({
    @JsonKey(name: 'route_id') required final String routeId,
    @JsonKey(name: 'total_duration_seconds')
    required final int totalDurationSeconds,
    @JsonKey(name: 'total_distance_meters')
    required final int totalDistanceMeters,
    final List<RouteSegment> segments,
    final List<String> warnings,
  }) = _$RouteResponseImpl;

  factory _RouteResponse.fromJson(Map<String, dynamic> json) =
      _$RouteResponseImpl.fromJson;

  @override
  @JsonKey(name: 'route_id')
  String get routeId;
  @override
  @JsonKey(name: 'total_duration_seconds')
  int get totalDurationSeconds;
  @override
  @JsonKey(name: 'total_distance_meters')
  int get totalDistanceMeters;
  @override
  List<RouteSegment> get segments;
  @override
  List<String> get warnings;

  /// Create a copy of RouteResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteResponseImplCopyWith<_$RouteResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RouteSegment _$RouteSegmentFromJson(Map<String, dynamic> json) {
  return _RouteSegment.fromJson(json);
}

/// @nodoc
mixin _$RouteSegment {
  @JsonKey(name: 'from_id')
  String get fromId => throw _privateConstructorUsedError;
  @JsonKey(name: 'to_id')
  String get toId => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_seconds')
  int get durationSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'distance_meters')
  int get distanceMeters => throw _privateConstructorUsedError;
  String get polyline => throw _privateConstructorUsedError;
  @JsonKey(name: 'transport_mode')
  String get transportMode => throw _privateConstructorUsedError;

  /// Serializes this RouteSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteSegmentCopyWith<RouteSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteSegmentCopyWith<$Res> {
  factory $RouteSegmentCopyWith(
    RouteSegment value,
    $Res Function(RouteSegment) then,
  ) = _$RouteSegmentCopyWithImpl<$Res, RouteSegment>;
  @useResult
  $Res call({
    @JsonKey(name: 'from_id') String fromId,
    @JsonKey(name: 'to_id') String toId,
    @JsonKey(name: 'duration_seconds') int durationSeconds,
    @JsonKey(name: 'distance_meters') int distanceMeters,
    String polyline,
    @JsonKey(name: 'transport_mode') String transportMode,
  });
}

/// @nodoc
class _$RouteSegmentCopyWithImpl<$Res, $Val extends RouteSegment>
    implements $RouteSegmentCopyWith<$Res> {
  _$RouteSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromId = null,
    Object? toId = null,
    Object? durationSeconds = null,
    Object? distanceMeters = null,
    Object? polyline = null,
    Object? transportMode = null,
  }) {
    return _then(
      _value.copyWith(
            fromId: null == fromId
                ? _value.fromId
                : fromId // ignore: cast_nullable_to_non_nullable
                      as String,
            toId: null == toId
                ? _value.toId
                : toId // ignore: cast_nullable_to_non_nullable
                      as String,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            distanceMeters: null == distanceMeters
                ? _value.distanceMeters
                : distanceMeters // ignore: cast_nullable_to_non_nullable
                      as int,
            polyline: null == polyline
                ? _value.polyline
                : polyline // ignore: cast_nullable_to_non_nullable
                      as String,
            transportMode: null == transportMode
                ? _value.transportMode
                : transportMode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteSegmentImplCopyWith<$Res>
    implements $RouteSegmentCopyWith<$Res> {
  factory _$$RouteSegmentImplCopyWith(
    _$RouteSegmentImpl value,
    $Res Function(_$RouteSegmentImpl) then,
  ) = __$$RouteSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'from_id') String fromId,
    @JsonKey(name: 'to_id') String toId,
    @JsonKey(name: 'duration_seconds') int durationSeconds,
    @JsonKey(name: 'distance_meters') int distanceMeters,
    String polyline,
    @JsonKey(name: 'transport_mode') String transportMode,
  });
}

/// @nodoc
class __$$RouteSegmentImplCopyWithImpl<$Res>
    extends _$RouteSegmentCopyWithImpl<$Res, _$RouteSegmentImpl>
    implements _$$RouteSegmentImplCopyWith<$Res> {
  __$$RouteSegmentImplCopyWithImpl(
    _$RouteSegmentImpl _value,
    $Res Function(_$RouteSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromId = null,
    Object? toId = null,
    Object? durationSeconds = null,
    Object? distanceMeters = null,
    Object? polyline = null,
    Object? transportMode = null,
  }) {
    return _then(
      _$RouteSegmentImpl(
        fromId: null == fromId
            ? _value.fromId
            : fromId // ignore: cast_nullable_to_non_nullable
                  as String,
        toId: null == toId
            ? _value.toId
            : toId // ignore: cast_nullable_to_non_nullable
                  as String,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        distanceMeters: null == distanceMeters
            ? _value.distanceMeters
            : distanceMeters // ignore: cast_nullable_to_non_nullable
                  as int,
        polyline: null == polyline
            ? _value.polyline
            : polyline // ignore: cast_nullable_to_non_nullable
                  as String,
        transportMode: null == transportMode
            ? _value.transportMode
            : transportMode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteSegmentImpl implements _RouteSegment {
  const _$RouteSegmentImpl({
    @JsonKey(name: 'from_id') required this.fromId,
    @JsonKey(name: 'to_id') required this.toId,
    @JsonKey(name: 'duration_seconds') required this.durationSeconds,
    @JsonKey(name: 'distance_meters') required this.distanceMeters,
    required this.polyline,
    @JsonKey(name: 'transport_mode') required this.transportMode,
  });

  factory _$RouteSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteSegmentImplFromJson(json);

  @override
  @JsonKey(name: 'from_id')
  final String fromId;
  @override
  @JsonKey(name: 'to_id')
  final String toId;
  @override
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  @override
  @JsonKey(name: 'distance_meters')
  final int distanceMeters;
  @override
  final String polyline;
  @override
  @JsonKey(name: 'transport_mode')
  final String transportMode;

  @override
  String toString() {
    return 'RouteSegment(fromId: $fromId, toId: $toId, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, polyline: $polyline, transportMode: $transportMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteSegmentImpl &&
            (identical(other.fromId, fromId) || other.fromId == fromId) &&
            (identical(other.toId, toId) || other.toId == toId) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.distanceMeters, distanceMeters) ||
                other.distanceMeters == distanceMeters) &&
            (identical(other.polyline, polyline) ||
                other.polyline == polyline) &&
            (identical(other.transportMode, transportMode) ||
                other.transportMode == transportMode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fromId,
    toId,
    durationSeconds,
    distanceMeters,
    polyline,
    transportMode,
  );

  /// Create a copy of RouteSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteSegmentImplCopyWith<_$RouteSegmentImpl> get copyWith =>
      __$$RouteSegmentImplCopyWithImpl<_$RouteSegmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteSegmentImplToJson(this);
  }
}

abstract class _RouteSegment implements RouteSegment {
  const factory _RouteSegment({
    @JsonKey(name: 'from_id') required final String fromId,
    @JsonKey(name: 'to_id') required final String toId,
    @JsonKey(name: 'duration_seconds') required final int durationSeconds,
    @JsonKey(name: 'distance_meters') required final int distanceMeters,
    required final String polyline,
    @JsonKey(name: 'transport_mode') required final String transportMode,
  }) = _$RouteSegmentImpl;

  factory _RouteSegment.fromJson(Map<String, dynamic> json) =
      _$RouteSegmentImpl.fromJson;

  @override
  @JsonKey(name: 'from_id')
  String get fromId;
  @override
  @JsonKey(name: 'to_id')
  String get toId;
  @override
  @JsonKey(name: 'duration_seconds')
  int get durationSeconds;
  @override
  @JsonKey(name: 'distance_meters')
  int get distanceMeters;
  @override
  String get polyline;
  @override
  @JsonKey(name: 'transport_mode')
  String get transportMode;

  /// Create a copy of RouteSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteSegmentImplCopyWith<_$RouteSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
