// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteRequest _$RouteRequestFromJson(Map<String, dynamic> json) {
  return _RouteRequest.fromJson(json);
}

/// @nodoc
mixin _$RouteRequest {
  String get mode => throw _privateConstructorUsedError;
  List<Waypoint> get waypoints => throw _privateConstructorUsedError;
  Constraints get constraints => throw _privateConstructorUsedError;

  /// Serializes this RouteRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteRequestCopyWith<RouteRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteRequestCopyWith<$Res> {
  factory $RouteRequestCopyWith(
    RouteRequest value,
    $Res Function(RouteRequest) then,
  ) = _$RouteRequestCopyWithImpl<$Res, RouteRequest>;
  @useResult
  $Res call({String mode, List<Waypoint> waypoints, Constraints constraints});

  $ConstraintsCopyWith<$Res> get constraints;
}

/// @nodoc
class _$RouteRequestCopyWithImpl<$Res, $Val extends RouteRequest>
    implements $RouteRequestCopyWith<$Res> {
  _$RouteRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? waypoints = null,
    Object? constraints = null,
  }) {
    return _then(
      _value.copyWith(
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
            waypoints: null == waypoints
                ? _value.waypoints
                : waypoints // ignore: cast_nullable_to_non_nullable
                      as List<Waypoint>,
            constraints: null == constraints
                ? _value.constraints
                : constraints // ignore: cast_nullable_to_non_nullable
                      as Constraints,
          )
          as $Val,
    );
  }

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConstraintsCopyWith<$Res> get constraints {
    return $ConstraintsCopyWith<$Res>(_value.constraints, (value) {
      return _then(_value.copyWith(constraints: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RouteRequestImplCopyWith<$Res>
    implements $RouteRequestCopyWith<$Res> {
  factory _$$RouteRequestImplCopyWith(
    _$RouteRequestImpl value,
    $Res Function(_$RouteRequestImpl) then,
  ) = __$$RouteRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mode, List<Waypoint> waypoints, Constraints constraints});

  @override
  $ConstraintsCopyWith<$Res> get constraints;
}

/// @nodoc
class __$$RouteRequestImplCopyWithImpl<$Res>
    extends _$RouteRequestCopyWithImpl<$Res, _$RouteRequestImpl>
    implements _$$RouteRequestImplCopyWith<$Res> {
  __$$RouteRequestImplCopyWithImpl(
    _$RouteRequestImpl _value,
    $Res Function(_$RouteRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? waypoints = null,
    Object? constraints = null,
  }) {
    return _then(
      _$RouteRequestImpl(
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        waypoints: null == waypoints
            ? _value._waypoints
            : waypoints // ignore: cast_nullable_to_non_nullable
                  as List<Waypoint>,
        constraints: null == constraints
            ? _value.constraints
            : constraints // ignore: cast_nullable_to_non_nullable
                  as Constraints,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteRequestImpl implements _RouteRequest {
  const _$RouteRequestImpl({
    required this.mode,
    required final List<Waypoint> waypoints,
    this.constraints = const Constraints(),
  }) : _waypoints = waypoints;

  factory _$RouteRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteRequestImplFromJson(json);

  @override
  final String mode;
  final List<Waypoint> _waypoints;
  @override
  List<Waypoint> get waypoints {
    if (_waypoints is EqualUnmodifiableListView) return _waypoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waypoints);
  }

  @override
  @JsonKey()
  final Constraints constraints;

  @override
  String toString() {
    return 'RouteRequest(mode: $mode, waypoints: $waypoints, constraints: $constraints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteRequestImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality().equals(
              other._waypoints,
              _waypoints,
            ) &&
            (identical(other.constraints, constraints) ||
                other.constraints == constraints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    mode,
    const DeepCollectionEquality().hash(_waypoints),
    constraints,
  );

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteRequestImplCopyWith<_$RouteRequestImpl> get copyWith =>
      __$$RouteRequestImplCopyWithImpl<_$RouteRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteRequestImplToJson(this);
  }
}

abstract class _RouteRequest implements RouteRequest {
  const factory _RouteRequest({
    required final String mode,
    required final List<Waypoint> waypoints,
    final Constraints constraints,
  }) = _$RouteRequestImpl;

  factory _RouteRequest.fromJson(Map<String, dynamic> json) =
      _$RouteRequestImpl.fromJson;

  @override
  String get mode;
  @override
  List<Waypoint> get waypoints;
  @override
  Constraints get constraints;

  /// Create a copy of RouteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteRequestImplCopyWith<_$RouteRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Waypoint _$WaypointFromJson(Map<String, dynamic> json) {
  return _Waypoint.fromJson(json);
}

/// @nodoc
mixin _$Waypoint {
  String get id => throw _privateConstructorUsedError;
  Location get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_check')
  int get durationCheck => throw _privateConstructorUsedError;

  /// Serializes this Waypoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WaypointCopyWith<Waypoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WaypointCopyWith<$Res> {
  factory $WaypointCopyWith(Waypoint value, $Res Function(Waypoint) then) =
      _$WaypointCopyWithImpl<$Res, Waypoint>;
  @useResult
  $Res call({
    String id,
    Location location,
    @JsonKey(name: 'duration_check') int durationCheck,
  });

  $LocationCopyWith<$Res> get location;
}

/// @nodoc
class _$WaypointCopyWithImpl<$Res, $Val extends Waypoint>
    implements $WaypointCopyWith<$Res> {
  _$WaypointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? location = null,
    Object? durationCheck = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as Location,
            durationCheck: null == durationCheck
                ? _value.durationCheck
                : durationCheck // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res> get location {
    return $LocationCopyWith<$Res>(_value.location, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WaypointImplCopyWith<$Res>
    implements $WaypointCopyWith<$Res> {
  factory _$$WaypointImplCopyWith(
    _$WaypointImpl value,
    $Res Function(_$WaypointImpl) then,
  ) = __$$WaypointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    Location location,
    @JsonKey(name: 'duration_check') int durationCheck,
  });

  @override
  $LocationCopyWith<$Res> get location;
}

/// @nodoc
class __$$WaypointImplCopyWithImpl<$Res>
    extends _$WaypointCopyWithImpl<$Res, _$WaypointImpl>
    implements _$$WaypointImplCopyWith<$Res> {
  __$$WaypointImplCopyWithImpl(
    _$WaypointImpl _value,
    $Res Function(_$WaypointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? location = null,
    Object? durationCheck = null,
  }) {
    return _then(
      _$WaypointImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as Location,
        durationCheck: null == durationCheck
            ? _value.durationCheck
            : durationCheck // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WaypointImpl implements _Waypoint {
  const _$WaypointImpl({
    required this.id,
    required this.location,
    @JsonKey(name: 'duration_check') this.durationCheck = 60,
  });

  factory _$WaypointImpl.fromJson(Map<String, dynamic> json) =>
      _$$WaypointImplFromJson(json);

  @override
  final String id;
  @override
  final Location location;
  @override
  @JsonKey(name: 'duration_check')
  final int durationCheck;

  @override
  String toString() {
    return 'Waypoint(id: $id, location: $location, durationCheck: $durationCheck)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WaypointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.durationCheck, durationCheck) ||
                other.durationCheck == durationCheck));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, location, durationCheck);

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WaypointImplCopyWith<_$WaypointImpl> get copyWith =>
      __$$WaypointImplCopyWithImpl<_$WaypointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WaypointImplToJson(this);
  }
}

abstract class _Waypoint implements Waypoint {
  const factory _Waypoint({
    required final String id,
    required final Location location,
    @JsonKey(name: 'duration_check') final int durationCheck,
  }) = _$WaypointImpl;

  factory _Waypoint.fromJson(Map<String, dynamic> json) =
      _$WaypointImpl.fromJson;

  @override
  String get id;
  @override
  Location get location;
  @override
  @JsonKey(name: 'duration_check')
  int get durationCheck;

  /// Create a copy of Waypoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WaypointImplCopyWith<_$WaypointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Location _$LocationFromJson(Map<String, dynamic> json) {
  return _Location.fromJson(json);
}

/// @nodoc
mixin _$Location {
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;

  /// Serializes this Location to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationCopyWith<Location> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationCopyWith<$Res> {
  factory $LocationCopyWith(Location value, $Res Function(Location) then) =
      _$LocationCopyWithImpl<$Res, Location>;
  @useResult
  $Res call({double lat, double lng});
}

/// @nodoc
class _$LocationCopyWithImpl<$Res, $Val extends Location>
    implements $LocationCopyWith<$Res> {
  _$LocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? lat = null, Object? lng = null}) {
    return _then(
      _value.copyWith(
            lat: null == lat
                ? _value.lat
                : lat // ignore: cast_nullable_to_non_nullable
                      as double,
            lng: null == lng
                ? _value.lng
                : lng // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocationImplCopyWith<$Res>
    implements $LocationCopyWith<$Res> {
  factory _$$LocationImplCopyWith(
    _$LocationImpl value,
    $Res Function(_$LocationImpl) then,
  ) = __$$LocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double lat, double lng});
}

/// @nodoc
class __$$LocationImplCopyWithImpl<$Res>
    extends _$LocationCopyWithImpl<$Res, _$LocationImpl>
    implements _$$LocationImplCopyWith<$Res> {
  __$$LocationImplCopyWithImpl(
    _$LocationImpl _value,
    $Res Function(_$LocationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? lat = null, Object? lng = null}) {
    return _then(
      _$LocationImpl(
        lat: null == lat
            ? _value.lat
            : lat // ignore: cast_nullable_to_non_nullable
                  as double,
        lng: null == lng
            ? _value.lng
            : lng // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationImpl implements _Location {
  const _$LocationImpl({required this.lat, required this.lng});

  factory _$LocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationImplFromJson(json);

  @override
  final double lat;
  @override
  final double lng;

  @override
  String toString() {
    return 'Location(lat: $lat, lng: $lng)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lat, lng);

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationImplCopyWith<_$LocationImpl> get copyWith =>
      __$$LocationImplCopyWithImpl<_$LocationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationImplToJson(this);
  }
}

abstract class _Location implements Location {
  const factory _Location({
    required final double lat,
    required final double lng,
  }) = _$LocationImpl;

  factory _Location.fromJson(Map<String, dynamic> json) =
      _$LocationImpl.fromJson;

  @override
  double get lat;
  @override
  double get lng;

  /// Create a copy of Location
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationImplCopyWith<_$LocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Constraints _$ConstraintsFromJson(Map<String, dynamic> json) {
  return _Constraints.fromJson(json);
}

/// @nodoc
mixin _$Constraints {
  @JsonKey(name: 'transport_mode')
  String get transportMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'avoid_tolls')
  bool get avoidTolls => throw _privateConstructorUsedError;

  /// Serializes this Constraints to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Constraints
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConstraintsCopyWith<Constraints> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConstraintsCopyWith<$Res> {
  factory $ConstraintsCopyWith(
    Constraints value,
    $Res Function(Constraints) then,
  ) = _$ConstraintsCopyWithImpl<$Res, Constraints>;
  @useResult
  $Res call({
    @JsonKey(name: 'transport_mode') String transportMode,
    @JsonKey(name: 'avoid_tolls') bool avoidTolls,
  });
}

/// @nodoc
class _$ConstraintsCopyWithImpl<$Res, $Val extends Constraints>
    implements $ConstraintsCopyWith<$Res> {
  _$ConstraintsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Constraints
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? transportMode = null, Object? avoidTolls = null}) {
    return _then(
      _value.copyWith(
            transportMode: null == transportMode
                ? _value.transportMode
                : transportMode // ignore: cast_nullable_to_non_nullable
                      as String,
            avoidTolls: null == avoidTolls
                ? _value.avoidTolls
                : avoidTolls // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConstraintsImplCopyWith<$Res>
    implements $ConstraintsCopyWith<$Res> {
  factory _$$ConstraintsImplCopyWith(
    _$ConstraintsImpl value,
    $Res Function(_$ConstraintsImpl) then,
  ) = __$$ConstraintsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'transport_mode') String transportMode,
    @JsonKey(name: 'avoid_tolls') bool avoidTolls,
  });
}

/// @nodoc
class __$$ConstraintsImplCopyWithImpl<$Res>
    extends _$ConstraintsCopyWithImpl<$Res, _$ConstraintsImpl>
    implements _$$ConstraintsImplCopyWith<$Res> {
  __$$ConstraintsImplCopyWithImpl(
    _$ConstraintsImpl _value,
    $Res Function(_$ConstraintsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Constraints
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? transportMode = null, Object? avoidTolls = null}) {
    return _then(
      _$ConstraintsImpl(
        transportMode: null == transportMode
            ? _value.transportMode
            : transportMode // ignore: cast_nullable_to_non_nullable
                  as String,
        avoidTolls: null == avoidTolls
            ? _value.avoidTolls
            : avoidTolls // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConstraintsImpl implements _Constraints {
  const _$ConstraintsImpl({
    @JsonKey(name: 'transport_mode') this.transportMode = 'DRIVING',
    @JsonKey(name: 'avoid_tolls') this.avoidTolls = false,
  });

  factory _$ConstraintsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConstraintsImplFromJson(json);

  @override
  @JsonKey(name: 'transport_mode')
  final String transportMode;
  @override
  @JsonKey(name: 'avoid_tolls')
  final bool avoidTolls;

  @override
  String toString() {
    return 'Constraints(transportMode: $transportMode, avoidTolls: $avoidTolls)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConstraintsImpl &&
            (identical(other.transportMode, transportMode) ||
                other.transportMode == transportMode) &&
            (identical(other.avoidTolls, avoidTolls) ||
                other.avoidTolls == avoidTolls));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transportMode, avoidTolls);

  /// Create a copy of Constraints
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConstraintsImplCopyWith<_$ConstraintsImpl> get copyWith =>
      __$$ConstraintsImplCopyWithImpl<_$ConstraintsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConstraintsImplToJson(this);
  }
}

abstract class _Constraints implements Constraints {
  const factory _Constraints({
    @JsonKey(name: 'transport_mode') final String transportMode,
    @JsonKey(name: 'avoid_tolls') final bool avoidTolls,
  }) = _$ConstraintsImpl;

  factory _Constraints.fromJson(Map<String, dynamic> json) =
      _$ConstraintsImpl.fromJson;

  @override
  @JsonKey(name: 'transport_mode')
  String get transportMode;
  @override
  @JsonKey(name: 'avoid_tolls')
  bool get avoidTolls;

  /// Create a copy of Constraints
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConstraintsImplCopyWith<_$ConstraintsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
