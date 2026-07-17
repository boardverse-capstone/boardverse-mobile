// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_profile_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateProfileRequestModel {

 String? get bio; String? get firstName; String? get lastName; String? get dateOfBirth; String? get phoneNumber;
/// Create a copy of CreateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateProfileRequestModelCopyWith<CreateProfileRequestModel> get copyWith => _$CreateProfileRequestModelCopyWithImpl<CreateProfileRequestModel>(this as CreateProfileRequestModel, _$identity);

  /// Serializes this CreateProfileRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateProfileRequestModel&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bio,firstName,lastName,dateOfBirth,phoneNumber);

@override
String toString() {
  return 'CreateProfileRequestModel(bio: $bio, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $CreateProfileRequestModelCopyWith<$Res>  {
  factory $CreateProfileRequestModelCopyWith(CreateProfileRequestModel value, $Res Function(CreateProfileRequestModel) _then) = _$CreateProfileRequestModelCopyWithImpl;
@useResult
$Res call({
 String? bio, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber
});




}
/// @nodoc
class _$CreateProfileRequestModelCopyWithImpl<$Res>
    implements $CreateProfileRequestModelCopyWith<$Res> {
  _$CreateProfileRequestModelCopyWithImpl(this._self, this._then);

  final CreateProfileRequestModel _self;
  final $Res Function(CreateProfileRequestModel) _then;

/// Create a copy of CreateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bio = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,}) {
  return _then(_self.copyWith(
bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateProfileRequestModel].
extension CreateProfileRequestModelPatterns on CreateProfileRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateProfileRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateProfileRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateProfileRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _CreateProfileRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateProfileRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _CreateProfileRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateProfileRequestModel() when $default != null:
return $default(_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _CreateProfileRequestModel():
return $default(_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? bio,  String? firstName,  String? lastName,  String? dateOfBirth,  String? phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _CreateProfileRequestModel() when $default != null:
return $default(_that.bio,_that.firstName,_that.lastName,_that.dateOfBirth,_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateProfileRequestModel implements CreateProfileRequestModel {
  const _CreateProfileRequestModel({this.bio, this.firstName, this.lastName, this.dateOfBirth, this.phoneNumber});
  factory _CreateProfileRequestModel.fromJson(Map<String, dynamic> json) => _$CreateProfileRequestModelFromJson(json);

@override final  String? bio;
@override final  String? firstName;
@override final  String? lastName;
@override final  String? dateOfBirth;
@override final  String? phoneNumber;

/// Create a copy of CreateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateProfileRequestModelCopyWith<_CreateProfileRequestModel> get copyWith => __$CreateProfileRequestModelCopyWithImpl<_CreateProfileRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateProfileRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateProfileRequestModel&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bio,firstName,lastName,dateOfBirth,phoneNumber);

@override
String toString() {
  return 'CreateProfileRequestModel(bio: $bio, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$CreateProfileRequestModelCopyWith<$Res> implements $CreateProfileRequestModelCopyWith<$Res> {
  factory _$CreateProfileRequestModelCopyWith(_CreateProfileRequestModel value, $Res Function(_CreateProfileRequestModel) _then) = __$CreateProfileRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String? bio, String? firstName, String? lastName, String? dateOfBirth, String? phoneNumber
});




}
/// @nodoc
class __$CreateProfileRequestModelCopyWithImpl<$Res>
    implements _$CreateProfileRequestModelCopyWith<$Res> {
  __$CreateProfileRequestModelCopyWithImpl(this._self, this._then);

  final _CreateProfileRequestModel _self;
  final $Res Function(_CreateProfileRequestModel) _then;

/// Create a copy of CreateProfileRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bio = freezed,Object? firstName = freezed,Object? lastName = freezed,Object? dateOfBirth = freezed,Object? phoneNumber = freezed,}) {
  return _then(_CreateProfileRequestModel(
bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
