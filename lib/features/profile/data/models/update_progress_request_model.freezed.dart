// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_progress_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateProgressRequestModel {

 int get globalElo; int get level;
/// Create a copy of UpdateProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProgressRequestModelCopyWith<UpdateProgressRequestModel> get copyWith => _$UpdateProgressRequestModelCopyWithImpl<UpdateProgressRequestModel>(this as UpdateProgressRequestModel, _$identity);

  /// Serializes this UpdateProgressRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProgressRequestModel&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,globalElo,level);

@override
String toString() {
  return 'UpdateProgressRequestModel(globalElo: $globalElo, level: $level)';
}


}

/// @nodoc
abstract mixin class $UpdateProgressRequestModelCopyWith<$Res>  {
  factory $UpdateProgressRequestModelCopyWith(UpdateProgressRequestModel value, $Res Function(UpdateProgressRequestModel) _then) = _$UpdateProgressRequestModelCopyWithImpl;
@useResult
$Res call({
 int globalElo, int level
});




}
/// @nodoc
class _$UpdateProgressRequestModelCopyWithImpl<$Res>
    implements $UpdateProgressRequestModelCopyWith<$Res> {
  _$UpdateProgressRequestModelCopyWithImpl(this._self, this._then);

  final UpdateProgressRequestModel _self;
  final $Res Function(UpdateProgressRequestModel) _then;

/// Create a copy of UpdateProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? globalElo = null,Object? level = null,}) {
  return _then(_self.copyWith(
globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateProgressRequestModel].
extension UpdateProgressRequestModelPatterns on UpdateProgressRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateProgressRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateProgressRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateProgressRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _UpdateProgressRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateProgressRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateProgressRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int globalElo,  int level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateProgressRequestModel() when $default != null:
return $default(_that.globalElo,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int globalElo,  int level)  $default,) {final _that = this;
switch (_that) {
case _UpdateProgressRequestModel():
return $default(_that.globalElo,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int globalElo,  int level)?  $default,) {final _that = this;
switch (_that) {
case _UpdateProgressRequestModel() when $default != null:
return $default(_that.globalElo,_that.level);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateProgressRequestModel implements UpdateProgressRequestModel {
  const _UpdateProgressRequestModel({required this.globalElo, required this.level});
  factory _UpdateProgressRequestModel.fromJson(Map<String, dynamic> json) => _$UpdateProgressRequestModelFromJson(json);

@override final  int globalElo;
@override final  int level;

/// Create a copy of UpdateProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProgressRequestModelCopyWith<_UpdateProgressRequestModel> get copyWith => __$UpdateProgressRequestModelCopyWithImpl<_UpdateProgressRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateProgressRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProgressRequestModel&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,globalElo,level);

@override
String toString() {
  return 'UpdateProgressRequestModel(globalElo: $globalElo, level: $level)';
}


}

/// @nodoc
abstract mixin class _$UpdateProgressRequestModelCopyWith<$Res> implements $UpdateProgressRequestModelCopyWith<$Res> {
  factory _$UpdateProgressRequestModelCopyWith(_UpdateProgressRequestModel value, $Res Function(_UpdateProgressRequestModel) _then) = __$UpdateProgressRequestModelCopyWithImpl;
@override @useResult
$Res call({
 int globalElo, int level
});




}
/// @nodoc
class __$UpdateProgressRequestModelCopyWithImpl<$Res>
    implements _$UpdateProgressRequestModelCopyWith<$Res> {
  __$UpdateProgressRequestModelCopyWithImpl(this._self, this._then);

  final _UpdateProgressRequestModel _self;
  final $Res Function(_UpdateProgressRequestModel) _then;

/// Create a copy of UpdateProgressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? globalElo = null,Object? level = null,}) {
  return _then(_UpdateProgressRequestModel(
globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
