// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_location_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateLocationRequestModel {

 double get latitude; double get longitude;/// 0 = Gps (device), 1 = Manual (map picker)
 int get source;
/// Create a copy of UpdateLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateLocationRequestModelCopyWith<UpdateLocationRequestModel> get copyWith => _$UpdateLocationRequestModelCopyWithImpl<UpdateLocationRequestModel>(this as UpdateLocationRequestModel, _$identity);

  /// Serializes this UpdateLocationRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateLocationRequestModel&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,source);

@override
String toString() {
  return 'UpdateLocationRequestModel(latitude: $latitude, longitude: $longitude, source: $source)';
}


}

/// @nodoc
abstract mixin class $UpdateLocationRequestModelCopyWith<$Res>  {
  factory $UpdateLocationRequestModelCopyWith(UpdateLocationRequestModel value, $Res Function(UpdateLocationRequestModel) _then) = _$UpdateLocationRequestModelCopyWithImpl;
@useResult
$Res call({
 double latitude, double longitude, int source
});




}
/// @nodoc
class _$UpdateLocationRequestModelCopyWithImpl<$Res>
    implements $UpdateLocationRequestModelCopyWith<$Res> {
  _$UpdateLocationRequestModelCopyWithImpl(this._self, this._then);

  final UpdateLocationRequestModel _self;
  final $Res Function(UpdateLocationRequestModel) _then;

/// Create a copy of UpdateLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,Object? source = null,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateLocationRequestModel].
extension UpdateLocationRequestModelPatterns on UpdateLocationRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateLocationRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateLocationRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateLocationRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _UpdateLocationRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateLocationRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateLocationRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitude,  double longitude,  int source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateLocationRequestModel() when $default != null:
return $default(_that.latitude,_that.longitude,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitude,  double longitude,  int source)  $default,) {final _that = this;
switch (_that) {
case _UpdateLocationRequestModel():
return $default(_that.latitude,_that.longitude,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitude,  double longitude,  int source)?  $default,) {final _that = this;
switch (_that) {
case _UpdateLocationRequestModel() when $default != null:
return $default(_that.latitude,_that.longitude,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateLocationRequestModel implements UpdateLocationRequestModel {
  const _UpdateLocationRequestModel({required this.latitude, required this.longitude, required this.source});
  factory _UpdateLocationRequestModel.fromJson(Map<String, dynamic> json) => _$UpdateLocationRequestModelFromJson(json);

@override final  double latitude;
@override final  double longitude;
/// 0 = Gps (device), 1 = Manual (map picker)
@override final  int source;

/// Create a copy of UpdateLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateLocationRequestModelCopyWith<_UpdateLocationRequestModel> get copyWith => __$UpdateLocationRequestModelCopyWithImpl<_UpdateLocationRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateLocationRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateLocationRequestModel&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,source);

@override
String toString() {
  return 'UpdateLocationRequestModel(latitude: $latitude, longitude: $longitude, source: $source)';
}


}

/// @nodoc
abstract mixin class _$UpdateLocationRequestModelCopyWith<$Res> implements $UpdateLocationRequestModelCopyWith<$Res> {
  factory _$UpdateLocationRequestModelCopyWith(_UpdateLocationRequestModel value, $Res Function(_UpdateLocationRequestModel) _then) = __$UpdateLocationRequestModelCopyWithImpl;
@override @useResult
$Res call({
 double latitude, double longitude, int source
});




}
/// @nodoc
class __$UpdateLocationRequestModelCopyWithImpl<$Res>
    implements _$UpdateLocationRequestModelCopyWith<$Res> {
  __$UpdateLocationRequestModelCopyWithImpl(this._self, this._then);

  final _UpdateLocationRequestModel _self;
  final $Res Function(_UpdateLocationRequestModel) _then;

/// Create a copy of UpdateLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,Object? source = null,}) {
  return _then(_UpdateLocationRequestModel(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
