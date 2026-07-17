// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_profile_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateProfileRequestModel {

 String? get bio; String? get globalElo; int? get level; String? get firstName; String? get lastName; String? get dateOfBirth;
/// Create a copy of UpdateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProfileRequestModelCopyWith<UpdateProfileRequestModel> get copyWith => _$UpdateProfileRequestModelCopyWithImpl<UpdateProfileRequestModel>(this as UpdateProfileRequestModel, _$identity);

  /// Serializes this UpdateProfileRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProfileRequestModel&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bio,globalElo,level,firstName,lastName,dateOfBirth);

@override
String toString() {
  return 'UpdateProfileRequestModel(bio: $bio, globalElo: $globalElo, level: $level, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth)';
}


}

/// @nodoc
abstract mixin class $UpdateProfileRequestModelCopyWith<$Res>  {
  factory $UpdateProfileRequestModelCopyWith(UpdateProfileRequestModel value, $Res Function(UpdateProfileRequestModel) _then) = _$UpdateProfileRequestModelCopyWithImpl;
@useResult
$Res call({
 String? bio, String? globalElo, int? level, String? firstName, String? lastName, String? dateOfBirth
});




}
/// @nodoc
class _$UpdateProfileRequestModelCopyWithImpl<$Res>
    implements $UpdateProfileRequestModelCopyWith<$Res> {
  _$UpdateProfileRequestModelCopyWithImpl(this._self, this._then);

  final UpdateProfileRequestModel _self;
  final $Res Function(UpdateProfileRequestModel) _then;

/// Create a copy of UpdateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bio = freezed,Object? globalElo = freezed,Object? level = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,}) {
  return _then(_self.copyWith(
bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,globalElo: freezed == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateProfileRequestModel].
extension UpdateProfileRequestModelPatterns on UpdateProfileRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateProfileRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateProfileRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateProfileRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _UpdateProfileRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateProfileRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateProfileRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? bio,  String? globalElo,  int? level,  String? firstName,  String? lastName,  String? dateOfBirth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateProfileRequestModel() when $default != null:
return $default(_that.bio,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? bio,  String? globalElo,  int? level,  String? firstName,  String? lastName,  String? dateOfBirth)  $default,) {final _that = this;
switch (_that) {
case _UpdateProfileRequestModel():
return $default(_that.bio,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? bio,  String? globalElo,  int? level,  String? firstName,  String? lastName,  String? dateOfBirth)?  $default,) {final _that = this;
switch (_that) {
case _UpdateProfileRequestModel() when $default != null:
return $default(_that.bio,_that.globalElo,_that.level,_that.firstName,_that.lastName,_that.dateOfBirth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateProfileRequestModel implements UpdateProfileRequestModel {
  const _UpdateProfileRequestModel({this.bio, this.globalElo, this.level, this.firstName, this.lastName, this.dateOfBirth});
  factory _UpdateProfileRequestModel.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestModelFromJson(json);

@override final  String? bio;
@override final  String? globalElo;
@override final  int? level;
@override final  String? firstName;
@override final  String? lastName;
@override final  String? dateOfBirth;

/// Create a copy of UpdateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProfileRequestModelCopyWith<_UpdateProfileRequestModel> get copyWith => __$UpdateProfileRequestModelCopyWithImpl<_UpdateProfileRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateProfileRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProfileRequestModel&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.globalElo, globalElo) || other.globalElo == globalElo)&&(identical(other.level, level) || other.level == level)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bio,globalElo,level,firstName,lastName,dateOfBirth);

@override
String toString() {
  return 'UpdateProfileRequestModel(bio: $bio, globalElo: $globalElo, level: $level, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth)';
}


}

/// @nodoc
abstract mixin class _$UpdateProfileRequestModelCopyWith<$Res> implements $UpdateProfileRequestModelCopyWith<$Res> {
  factory _$UpdateProfileRequestModelCopyWith(_UpdateProfileRequestModel value, $Res Function(_UpdateProfileRequestModel) _then) = __$UpdateProfileRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String? bio, String? globalElo, int? level, String? firstName, String? lastName, String? dateOfBirth
});




}
/// @nodoc
class __$UpdateProfileRequestModelCopyWithImpl<$Res>
    implements _$UpdateProfileRequestModelCopyWith<$Res> {
  __$UpdateProfileRequestModelCopyWithImpl(this._self, this._then);

  final _UpdateProfileRequestModel _self;
  final $Res Function(_UpdateProfileRequestModel) _then;

/// Create a copy of UpdateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bio = freezed,Object? globalElo = freezed,Object? level = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,}) {
  return _then(_UpdateProfileRequestModel(
bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,globalElo: freezed == globalElo ? _self.globalElo : globalElo // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
