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

 String get userId; String get username; String? get avatarUrl; String? get avatarBorderUrl; String? get bio; String? get firstName; String? get lastName; String? get dateOfBirth; String? get phoneNumber; int? get karmaPoints; String? get gamerTier; int get globalElo; int get level; int get currentExp; String? get lastActiveAt; String? get updatedAt; bool get hasProfile; bool get isFriendListPublic; String? get acceptFriendRequestsFrom; int get friendLimit;
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileModelCopyWith<ProfileModel> get copyWith => _$ProfileModelCopyWithImpl<ProfileModel>(this as ProfileModel, _$identity);

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.avatarBorderUrl, avatarBorderUrl) || other.avatarBorderUrl == avatarBorderUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentExp, currentExp) || other.currentExp == currentExp)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasProfile, hasProfile) || other.hasProfile == hasProfile)&&(identical(other.isFriendListPublic, isFriendListPublic) || other.isFriendListPublic == isFriendListPublic)&&(identical(other.acceptFriendRequestsFrom, acceptFriendRequestsFrom) || other.acceptFriendRequestsFrom == acceptFriendRequestsFrom)&&(identical(other.friendLimit, friendLimit) || other.friendLimit == friendLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,username,avatarUrl,avatarBorderUrl,bio,firstName,lastName,dateOfBirth,phoneNumber,karmaPoints,gamerTier,globalElo,level,currentExp,lastActiveAt,updatedAt,hasProfile,isFriendListPublic,acceptFriendRequestsFrom,friendLimit]);

@override
String toString() {
  return 'ProfileModel(userId: $userId, username: $username, avatarUrl: $avatarUrl, avatarBorderUrl: $avatarBorderUrl, bio: $bio, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber, karmaPoints: $karmaPoints, gamerTier: $gamerTier, globalElo: $globalElo, level: $level, currentExp: $currentExp, lastActiveAt: $lastActiveAt, updatedAt: $updatedAt, hasProfile: $hasProfile, isFriendListPublic: $isFriendListPublic, acceptFriendRequestsFrom: $acceptFriendRequestsFrom, friendLimit: $friendLimit)';
}


}

/// @nodoc
abstract mixin class $ProfileModelCopyWith<$Res>  {
  factory $ProfileModelCopyWith(ProfileModel value, $Res Function(ProfileModel) _then) = _$ProfileModelCopyWithImpl;
@useResult
$Res call({
 String userId, String username, String? avatarUrl, String? avatarBorderUrl, String? bio, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber, int? karmaPoints, String? gamerTier, int globalElo, int level, int currentExp, String? lastActiveAt, String? updatedAt, bool hasProfile, bool isFriendListPublic, String? acceptFriendRequestsFrom, int friendLimit
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
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarBorderUrl = freezed,Object? bio = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,Object? karmaPoints = freezed,Object? gamerTier = freezed,Object? globalElo = null,Object? level = null,Object? currentExp = null,Object? lastActiveAt = freezed,Object? updatedAt = freezed,Object? hasProfile = null,Object? isFriendListPublic = null,Object? acceptFriendRequestsFrom = freezed,Object? friendLimit = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarBorderUrl: freezed == avatarBorderUrl ? _self.avatarBorderUrl : avatarBorderUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,karmaPoints: freezed == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int?,gamerTier: freezed == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String?,globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentExp: null == currentExp ? _self.currentExp : currentExp // ignore: cast_nullable_to_non_nullable
as int,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,hasProfile: null == hasProfile ? _self.hasProfile : hasProfile // ignore: cast_nullable_to_non_nullable
as bool,isFriendListPublic: null == isFriendListPublic ? _self.isFriendListPublic : isFriendListPublic // ignore: cast_nullable_to_non_nullable
as bool,acceptFriendRequestsFrom: freezed == acceptFriendRequestsFrom ? _self.acceptFriendRequestsFrom : acceptFriendRequestsFrom // ignore: cast_nullable_to_non_nullable
as String?,friendLimit: null == friendLimit ? _self.friendLimit : friendLimit // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String username,  String? avatarUrl,  String? avatarBorderUrl,  String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  int currentExp,  String? lastActiveAt,  String? updatedAt,  bool hasProfile,  bool isFriendListPublic,  String? acceptFriendRequestsFrom,  int friendLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.userId,_that.username,_that.avatarUrl,_that.avatarBorderUrl,_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.currentExp,_that.lastActiveAt,_that.updatedAt,_that.hasProfile,_that.isFriendListPublic,_that.acceptFriendRequestsFrom,_that.friendLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String username,  String? avatarUrl,  String? avatarBorderUrl,  String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  int currentExp,  String? lastActiveAt,  String? updatedAt,  bool hasProfile,  bool isFriendListPublic,  String? acceptFriendRequestsFrom,  int friendLimit)  $default,) {final _that = this;
switch (_that) {
case _ProfileModel():
return $default(_that.userId,_that.username,_that.avatarUrl,_that.avatarBorderUrl,_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.currentExp,_that.lastActiveAt,_that.updatedAt,_that.hasProfile,_that.isFriendListPublic,_that.acceptFriendRequestsFrom,_that.friendLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String username,  String? avatarUrl,  String? avatarBorderUrl,  String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber,  int? karmaPoints,  String? gamerTier,  int globalElo,  int level,  int currentExp,  String? lastActiveAt,  String? updatedAt,  bool hasProfile,  bool isFriendListPublic,  String? acceptFriendRequestsFrom,  int friendLimit)?  $default,) {final _that = this;
switch (_that) {
case _ProfileModel() when $default != null:
return $default(_that.userId,_that.username,_that.avatarUrl,_that.avatarBorderUrl,_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber,_that.karmaPoints,_that.gamerTier,_that.globalElo,_that.level,_that.currentExp,_that.lastActiveAt,_that.updatedAt,_that.hasProfile,_that.isFriendListPublic,_that.acceptFriendRequestsFrom,_that.friendLimit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileModel implements ProfileModel {
  const _ProfileModel({required this.userId, required this.username, this.avatarUrl, this.avatarBorderUrl, this.bio, this.firstName, this.lastName, this.dateOfBirth, this.phoneNumber, this.karmaPoints, this.gamerTier, required this.globalElo, required this.level, this.currentExp = 0, this.lastActiveAt, this.updatedAt, required this.hasProfile, this.isFriendListPublic = true, this.acceptFriendRequestsFrom, this.friendLimit = 0});
  factory _ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

@override final  String userId;
@override final  String username;
@override final  String? avatarUrl;
@override final  String? avatarBorderUrl;
@override final  String? bio;
@override final  String? firstName;
@override final  String? lastName;
@override final  String? dateOfBirth;
@override final  String? phoneNumber;
@override final  int? karmaPoints;
@override final  String? gamerTier;
@override final  int globalElo;
@override final  int level;
@override@JsonKey() final  int currentExp;
@override final  String? lastActiveAt;
@override final  String? updatedAt;
@override final  bool hasProfile;
@override@JsonKey() final  bool isFriendListPublic;
@override final  String? acceptFriendRequestsFrom;
@override@JsonKey() final  int friendLimit;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.avatarBorderUrl, avatarBorderUrl) || other.avatarBorderUrl == avatarBorderUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.karmaPoints, karmaPoints) || other.karmaPoints == karmaPoints)&&(identical(other.gamerTier, gamerTier) || other.gamerTier == gamerTier)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.currentExp, currentExp) || other.currentExp == currentExp)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasProfile, hasProfile) || other.hasProfile == hasProfile)&&(identical(other.isFriendListPublic, isFriendListPublic) || other.isFriendListPublic == isFriendListPublic)&&(identical(other.acceptFriendRequestsFrom, acceptFriendRequestsFrom) || other.acceptFriendRequestsFrom == acceptFriendRequestsFrom)&&(identical(other.friendLimit, friendLimit) || other.friendLimit == friendLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,username,avatarUrl,avatarBorderUrl,bio,firstName,lastName,dateOfBirth,phoneNumber,karmaPoints,gamerTier,globalElo,level,currentExp,lastActiveAt,updatedAt,hasProfile,isFriendListPublic,acceptFriendRequestsFrom,friendLimit]);

@override
String toString() {
  return 'ProfileModel(userId: $userId, username: $username, avatarUrl: $avatarUrl, avatarBorderUrl: $avatarBorderUrl, bio: $bio, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber, karmaPoints: $karmaPoints, gamerTier: $gamerTier, globalElo: $globalElo, level: $level, currentExp: $currentExp, lastActiveAt: $lastActiveAt, updatedAt: $updatedAt, hasProfile: $hasProfile, isFriendListPublic: $isFriendListPublic, acceptFriendRequestsFrom: $acceptFriendRequestsFrom, friendLimit: $friendLimit)';
}


}

/// @nodoc
abstract mixin class _$ProfileModelCopyWith<$Res> implements $ProfileModelCopyWith<$Res> {
  factory _$ProfileModelCopyWith(_ProfileModel value, $Res Function(_ProfileModel) _then) = __$ProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String username, String? avatarUrl, String? avatarBorderUrl, String? bio, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber, int? karmaPoints, String? gamerTier, int globalElo, int level, int currentExp, String? lastActiveAt, String? updatedAt, bool hasProfile, bool isFriendListPublic, String? acceptFriendRequestsFrom, int friendLimit
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
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? username = null,Object? avatarUrl = freezed,Object? avatarBorderUrl = freezed,Object? bio = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,Object? karmaPoints = freezed,Object? gamerTier = freezed,Object? globalElo = null,Object? level = null,Object? currentExp = null,Object? lastActiveAt = freezed,Object? updatedAt = freezed,Object? hasProfile = null,Object? isFriendListPublic = null,Object? acceptFriendRequestsFrom = freezed,Object? friendLimit = null,}) {
  return _then(_ProfileModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,avatarBorderUrl: freezed == avatarBorderUrl ? _self.avatarBorderUrl : avatarBorderUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,karmaPoints: freezed == karmaPoints ? _self.karmaPoints : karmaPoints // ignore: cast_nullable_to_non_nullable
as int?,gamerTier: freezed == gamerTier ? _self.gamerTier : gamerTier // ignore: cast_nullable_to_non_nullable
as String?,globalElo: null == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,currentExp: null == currentExp ? _self.currentExp : currentExp // ignore: cast_nullable_to_non_nullable
as int,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,hasProfile: null == hasProfile ? _self.hasProfile : hasProfile // ignore: cast_nullable_to_non_nullable
as bool,isFriendListPublic: null == isFriendListPublic ? _self.isFriendListPublic : isFriendListPublic // ignore: cast_nullable_to_non_nullable
as bool,acceptFriendRequestsFrom: freezed == acceptFriendRequestsFrom ? _self.acceptFriendRequestsFrom : acceptFriendRequestsFrom // ignore: cast_nullable_to_non_nullable
as String?,friendLimit: null == friendLimit ? _self.friendLimit : friendLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
