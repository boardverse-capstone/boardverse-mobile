// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileModel {

 String get userId; String get username; String? get gamerTag; String? get avatarUrl; String? get bio; int? get karmaPoints; String? get gamerTier; int get globalElo; int get level; String? get firstName; String? get lastName; String? get dateOfBirth; String? get phoneNumber; String? get updatedAt;
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileModelCopyWith<ProfileModel> get copyWith => _$ProfileModelCopyWithImpl<ProfileModel>(this as ProfileModel, _$identity);

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.gamerTag, gamerTag) || other.gamerTag == gamerTag)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,gamerTag,avatarUrl,bio,karmaPoints,gamerTier,globalElo,level,firstName,lastName,dateOfBirth,phoneNumber,updatedAt);

@override
String toString() {
  return 'ProfileModel(userId: $userId, username: $username, gamerTag: $gamerTag, avatarUrl: $avatarUrl, bio: $bio, karmaPoints: $karmaPoints, gamerTier: $gamerTier, globalElo: $globalElo, level: $level, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProfileModelCopyWith<$Res>  {
  factory $ProfileModelCopyWith(ProfileModel value, $Res Function(ProfileModel) _then) = _$ProfileModelCopyWithImpl;
@useResult
$Res call({
 String userId, String username, String? gamerTag, String? avatarUrl, String? bio, int? karmaPoints, String? gamerTier, int globalElo, int level, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber, String? updatedAt
});




}
/// @nodoc
class _$ProfileModelCopyWithImpl<$Res>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._self, this._then);

  final ProfileModel _self;
  final $Res Function(ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,Object? gamerTag = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? karmaPoints = freezed,Object? gamerTier = freezed,Object? globalElo = null,Object? level = null,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,gamerTag: freezed == gamerTag ? _self.gamerTag : gamerTag // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,karmaPoints: freezed == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int?,gamerTier: freezed == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String?,globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileModel].
extension ProfileModelPatterns on ProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _ProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username,  String? gamerTag,  String? avatarUrl,  String? bio,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.userId,_that.username,_that.gamerTag,_that.avatarUrl,_that.bio,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username,  String? gamerTag,  String? avatarUrl,  String? bio,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileModel():
return $default(_that.userId,_that.username,_that.gamerTag,_that.avatarUrl,_that.bio,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username,  String? gamerTag,  String? avatarUrl,  String? bio,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.userId,_that.username,_that.gamerTag,_that.avatarUrl,_that.bio,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileModel implements ProfileModel {
  const _ProfileModel({required this.userId, required this.username, this.gamerTag, this.avatarUrl, this.bio, this.karmaPoints, this.gamerTier, required this.globalElo, required this.level, this.firstName, this.lastName, this.dateOfBirth, this.phoneNumber, this.updatedAt});
  factory _ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

@override final  String userId;
@override final  String username;
@override final  String? gamerTag;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  int? karmaPoints;
@override final  String? gamerTier;
@override final  int globalElo;
@override final  int level;
@override final  String? firstName;
@override final  String? lastName;
@override final  String? dateOfBirth;
@override final  String? phoneNumber;
@override final  String? updatedAt;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileModelCopyWith<_ProfileModel> get copyWith => __$ProfileModelCopyWithImpl<_ProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.gamerTag, gamerTag) || other.gamerTag == gamerTag)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,username,gamerTag,avatarUrl,bio,karmaPoints,gamerTier,globalElo,level,firstName,lastName,dateOfBirth,phoneNumber,updatedAt);

@override
String toString() {
  return 'ProfileModel(userId: $userId, username: $username, gamerTag: $gamerTag, avatarUrl: $avatarUrl, bio: $bio, karmaPoints: $karmaPoints, gamerTier: $gamerTier, globalElo: $globalElo, level: $level, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileModelCopyWith<$Res> implements $ProfileModelCopyWith<$Res> {
  factory _$ProfileModelCopyWith(_ProfileModel value, $Res Function(_ProfileModel) _then) = __$ProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username, String? gamerTag, String? avatarUrl, String? bio, int? karmaPoints, String? gamerTier, int globalElo, int level, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber, String? updatedAt
});




}
/// @nodoc
class __$ProfileModelCopyWithImpl<$Res>
    implements _$ProfileModelCopyWith<$Res> {
  __$ProfileModelCopyWithImpl(this._self, this._then);

  final _ProfileModel _self;
  final $Res Function(_ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,Object? gamerTag = freezed,Object? avatarUrl = freezed,Object? bio = freezed,Object? karmaPoints = freezed,Object? gamerTier = freezed,Object? globalElo = null,Object? level = null,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,Object? updatedAt = freezed,}) {
  return _then(_ProfileModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,gamerTag: freezed == gamerTag ? _self.gamerTag : gamerTag // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,karmaPoints: freezed == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int?,gamerTier: freezed == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String?,globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
