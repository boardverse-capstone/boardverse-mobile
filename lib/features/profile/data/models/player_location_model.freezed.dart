// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_location_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerLocationModel {

 double? get latitude; double? get longitude; String? get updatedAt;/// 0 = Gps (device), 1 = Manual (map picker)
 int? get source; bool get hasLocation;
/// Create a copy of PlayerLocationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerLocationModelCopyWith<PlayerLocationModel> get copyWith => _$PlayerLocationModelCopyWithImpl<PlayerLocationModel>(this as PlayerLocationModel, _$identity);

  /// Serializes this PlayerLocationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerLocationModel&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.hasLocation, hasLocation) || other.hasLocation == hasLocation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,updatedAt,source,hasLocation);

@override
String toString() {
  return 'PlayerLocationModel(latitude: $latitude, longitude: $longitude, updatedAt: $updatedAt, source: $source, hasLocation: $hasLocation)';
}


}

/// @nodoc
abstract mixin class $PlayerLocationModelCopyWith<$Res>  {
  factory $PlayerLocationModelCopyWith(PlayerLocationModel value, $Res Function(PlayerLocationModel) _then) = _$PlayerLocationModelCopyWithImpl;
@useResult
$Res call({
 double? latitude, double? longitude, String? updatedAt, int? source, bool hasLocation
});




}
/// @nodoc
class _$PlayerLocationModelCopyWithImpl<$Res>
    implements $PlayerLocationModelCopyWith<$Res> {
  _$PlayerLocationModelCopyWithImpl(this._self, this._then);

  final PlayerLocationModel _self;
  final $Res Function(PlayerLocationModel) _then;

/// Create a copy of PlayerLocationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = freezed,Object? longitude = freezed,Object? updatedAt = freezed,Object? source = freezed,Object? hasLocation = null,}) {
  return _then(_self.copyWith(
latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as int?,hasLocation: null == hasLocation ? _self.hasLocation : hasLocation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerLocationModel].
extension PlayerLocationModelPatterns on PlayerLocationModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerLocationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerLocationModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerLocationModel value)  $default,){
final _that = this;
switch (_that) {
case _PlayerLocationModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerLocationModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerLocationModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? latitude,  double? longitude,  String? updatedAt,  int? source,  bool hasLocation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerLocationModel() when $default != null:
return $default(_that.latitude,_that.longitude,_that.updatedAt,_that.source,_that.hasLocation);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? latitude,  double? longitude,  String? updatedAt,  int? source,  bool hasLocation)  $default,) {final _that = this;
switch (_that) {
case _PlayerLocationModel():
return $default(_that.latitude,_that.longitude,_that.updatedAt,_that.source,_that.hasLocation);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? latitude,  double? longitude,  String? updatedAt,  int? source,  bool hasLocation)?  $default,) {final _that = this;
switch (_that) {
case _PlayerLocationModel() when $default != null:
return $default(_that.latitude,_that.longitude,_that.updatedAt,_that.source,_that.hasLocation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerLocationModel implements PlayerLocationModel {
  const _PlayerLocationModel({this.latitude, this.longitude, this.updatedAt, this.source, required this.hasLocation});
  factory _PlayerLocationModel.fromJson(Map<String, dynamic> json) => _$PlayerLocationModelFromJson(json);

@override final  double? latitude;
@override final  double? longitude;
@override final  String? updatedAt;
/// 0 = Gps (device), 1 = Manual (map picker)
@override final  int? source;
@override final  bool hasLocation;

/// Create a copy of PlayerLocationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerLocationModelCopyWith<_PlayerLocationModel> get copyWith => __$PlayerLocationModelCopyWithImpl<_PlayerLocationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerLocationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerLocationModel&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.hasLocation, hasLocation) || other.hasLocation == hasLocation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,updatedAt,source,hasLocation);

@override
String toString() {
  return 'PlayerLocationModel(latitude: $latitude, longitude: $longitude, updatedAt: $updatedAt, source: $source, hasLocation: $hasLocation)';
}


}

/// @nodoc
abstract mixin class _$PlayerLocationModelCopyWith<$Res> implements $PlayerLocationModelCopyWith<$Res> {
  factory _$PlayerLocationModelCopyWith(_PlayerLocationModel value, $Res Function(_PlayerLocationModel) _then) = __$PlayerLocationModelCopyWithImpl;
@override @useResult
$Res call({
 double? latitude, double? longitude, String? updatedAt, int? source, bool hasLocation
});




}
/// @nodoc
class __$PlayerLocationModelCopyWithImpl<$Res>
    implements _$PlayerLocationModelCopyWith<$Res> {
  __$PlayerLocationModelCopyWithImpl(this._self, this._then);

  final _PlayerLocationModel _self;
  final $Res Function(_PlayerLocationModel) _then;

/// Create a copy of PlayerLocationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = freezed,Object? longitude = freezed,Object? updatedAt = freezed,Object? source = freezed,Object? hasLocation = null,}) {
  return _then(_PlayerLocationModel(
latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as int?,hasLocation: null == hasLocation ? _self.hasLocation : hasLocation // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
