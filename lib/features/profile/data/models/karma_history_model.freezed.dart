// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'karma_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KarmaHistoryModel {

 String get userId; String get username; int get karmaPoints; String get gamerTier; String? get avatarUrl; String? get updatedAt;
/// Create a copy of KarmaHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KarmaHistoryModelCopyWith<KarmaHistoryModel> get copyWith => _$KarmaHistoryModelCopyWithImpl<KarmaHistoryModel>(this as KarmaHistoryModel, _$identity);

  /// Serializes this KarmaHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KarmaHistoryModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,karmaPoints,gamerTier,avatarUrl,updatedAt);

@override
String toString() {
  return 'KarmaHistoryModel(userId: $userId, username: $username, karmaPoints: $karmaPoints, gamerTier: $gamerTier, avatarUrl: $avatarUrl, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $KarmaHistoryModelCopyWith<$Res>  {
  factory $KarmaHistoryModelCopyWith(KarmaHistoryModel value, $Res Function(KarmaHistoryModel) _then) = _$KarmaHistoryModelCopyWithImpl;
@useResult
$Res call({
 String userId, String username, int karmaPoints, String gamerTier, String? avatarUrl, String? updatedAt
});




}
/// @nodoc
class _$KarmaHistoryModelCopyWithImpl<$Res>
    implements $KarmaHistoryModelCopyWith<$Res> {
  _$KarmaHistoryModelCopyWithImpl(this._self, this._then);

  final KarmaHistoryModel _self;
  final $Res Function(KarmaHistoryModel) _then;

/// Create a copy of KarmaHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,Object? karmaPoints = null,Object? gamerTier = null,Object? avatarUrl = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,karmaPoints: null == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int,gamerTier: null == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KarmaHistoryModel].
extension KarmaHistoryModelPatterns on KarmaHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KarmaHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KarmaHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KarmaHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _KarmaHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KarmaHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _KarmaHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username,  int karmaPoints,  String gamerTier,  String? avatarUrl,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KarmaHistoryModel() when $default != null:
return $default(_that.userId,_that.username,_that.karmaPoints,_that.gamerTier,_that.avatarUrl,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username,  int karmaPoints,  String gamerTier,  String? avatarUrl,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _KarmaHistoryModel():
return $default(_that.userId,_that.username,_that.karmaPoints,_that.gamerTier,_that.avatarUrl,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username,  int karmaPoints,  String gamerTier,  String? avatarUrl,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _KarmaHistoryModel() when $default != null:
return $default(_that.userId,_that.username,_that.karmaPoints,_that.gamerTier,_that.avatarUrl,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KarmaHistoryModel implements KarmaHistoryModel {
  const _KarmaHistoryModel({required this.userId, required this.username, required this.karmaPoints, required this.gamerTier, this.avatarUrl, this.updatedAt});
  factory _KarmaHistoryModel.fromJson(Map<String, dynamic> json) => _$KarmaHistoryModelFromJson(json);

@override final  String userId;
@override final  String username;
@override final  int karmaPoints;
@override final  String gamerTier;
@override final  String? avatarUrl;
@override final  String? updatedAt;

/// Create a copy of KarmaHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KarmaHistoryModelCopyWith<_KarmaHistoryModel> get copyWith => __$KarmaHistoryModelCopyWithImpl<_KarmaHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KarmaHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KarmaHistoryModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,karmaPoints,gamerTier,avatarUrl,updatedAt);

@override
String toString() {
  return 'KarmaHistoryModel(userId: $userId, username: $username, karmaPoints: $karmaPoints, gamerTier: $gamerTier, avatarUrl: $avatarUrl, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$KarmaHistoryModelCopyWith<$Res> implements $KarmaHistoryModelCopyWith<$Res> {
  factory _$KarmaHistoryModelCopyWith(_KarmaHistoryModel value, $Res Function(_KarmaHistoryModel) _then) = __$KarmaHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username, int karmaPoints, String gamerTier, String? avatarUrl, String? updatedAt
});




}
/// @nodoc
class __$KarmaHistoryModelCopyWithImpl<$Res>
    implements _$KarmaHistoryModelCopyWith<$Res> {
  __$KarmaHistoryModelCopyWithImpl(this._self, this._then);

  final _KarmaHistoryModel _self;
  final $Res Function(_KarmaHistoryModel) _then;

/// Create a copy of KarmaHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,Object? karmaPoints = null,Object? gamerTier = null,Object? avatarUrl = freezed,Object? updatedAt = freezed,}) {
  return _then(_KarmaHistoryModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,karmaPoints: null == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int,gamerTier: null == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
