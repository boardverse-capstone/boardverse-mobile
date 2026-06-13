// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_profile_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateProfileRequestModel _$CreateProfileRequestModelFromJson(
  Map<String, dynamic> json,
) => _CreateProfileRequestModel(
  gamerTag: json['gamerTag'] as String,
  bio: json['bio'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
);

Map<String, dynamic> _$CreateProfileRequestModelToJson(
  _CreateProfileRequestModel instance,
) => <String, dynamic>{
  'gamerTag': instance.gamerTag,
  'bio': instance.bio,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'dateOfBirth': instance.dateOfBirth,
  'phoneNumber': instance.phoneNumber,
};
