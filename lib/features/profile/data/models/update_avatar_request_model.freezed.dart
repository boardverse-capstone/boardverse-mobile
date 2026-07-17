// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_avatar_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateAvatarRequestModel {

 String get avatarUrl;
/// Create a copy of UpdateAvatarRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateAvatarRequestModelCopyWith<UpdateAvatarRequestModel> get copyWith => _$UpdateAvatarRequestModelCopyWithImpl<UpdateAvatarRequestModel>(this as UpdateAvatarRequestModel, _$identity);

  /// Serializes this UpdateAvatarRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateAvatarRequestModel&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl);

@override
String toString() {
  return 'UpdateAvatarRequestModel(avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $UpdateAvatarRequestModelCopyWith<$Res>  {
  factory $UpdateAvatarRequestModelCopyWith(UpdateAvatarRequestModel value, $Res Function(UpdateAvatarRequestModel) _then) = _$UpdateAvatarRequestModelCopyWithImpl;
@useResult
$Res call({
 String avatarUrl
});




}
/// @nodoc
class _$UpdateAvatarRequestModelCopyWithImpl<$Res>
    implements $UpdateAvatarRequestModelCopyWith<$Res> {
  _$UpdateAvatarRequestModelCopyWithImpl(this._self, this._then);

  final UpdateAvatarRequestModel _self;
  final $Res Function(UpdateAvatarRequestModel) _then;

/// Create a copy of UpdateAvatarRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avatarUrl = null,}) {
  return _then(_self.copyWith(
avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateAvatarRequestModel].
extension UpdateAvatarRequestModelPatterns on UpdateAvatarRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateAvatarRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateAvatarRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateAvatarRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel() when $default != null:
return $default(_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel():
return $default(_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _UpdateAvatarRequestModel() when $default != null:
return $default(_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateAvatarRequestModel implements UpdateAvatarRequestModel {
  const _UpdateAvatarRequestModel({required this.avatarUrl});
  factory _UpdateAvatarRequestModel.fromJson(Map<String, dynamic> json) => _$UpdateAvatarRequestModelFromJson(json);

@override final  String avatarUrl;

/// Create a copy of UpdateAvatarRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateAvatarRequestModelCopyWith<_UpdateAvatarRequestModel> get copyWith => __$UpdateAvatarRequestModelCopyWithImpl<_UpdateAvatarRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateAvatarRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateAvatarRequestModel&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl);

@override
String toString() {
  return 'UpdateAvatarRequestModel(avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$UpdateAvatarRequestModelCopyWith<$Res> implements $UpdateAvatarRequestModelCopyWith<$Res> {
  factory _$UpdateAvatarRequestModelCopyWith(_UpdateAvatarRequestModel value, $Res Function(_UpdateAvatarRequestModel) _then) = __$UpdateAvatarRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String avatarUrl
});




}
/// @nodoc
class __$UpdateAvatarRequestModelCopyWithImpl<$Res>
    implements _$UpdateAvatarRequestModelCopyWith<$Res> {
  __$UpdateAvatarRequestModelCopyWithImpl(this._self, this._then);

  final _UpdateAvatarRequestModel _self;
  final $Res Function(_UpdateAvatarRequestModel) _then;

/// Create a copy of UpdateAvatarRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avatarUrl = null,}) {
  return _then(_UpdateAvatarRequestModel(
avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
