// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateProfileRequestModel _$UpdateProfileRequestModelFromJson(
  Map<String, dynamic> json,
) => _UpdateProfileRequestModel(
  bio: json['bio'] as String?,
  globalElo: json['globalElo'] as String?,
  level: (json['level'] as num?)?.toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestModelToJson(
  _UpdateProfileRequestModel instance,
) => <String, dynamic>{
  'bio': instance.bio,
  'globalElo': instance.globalElo,
  'level': instance.level,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'dateOfBirth': instance.dateOfBirth,
};
