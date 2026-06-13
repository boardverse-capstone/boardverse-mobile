// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) =>
    _ProfileModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      gamerTag: json['gamerTag'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      karmaPoints: (json['karmaPoints'] as num?)?.toInt(),
      gamerTier: json['gamerTier'] as String?,
      globalElo: (json['globalElo'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$ProfileModelToJson(_ProfileModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'gamerTag': instance.gamerTag,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'karmaPoints': instance.karmaPoints,
      'gamerTier': instance.gamerTier,
      'globalElo': instance.globalElo,
      'level': instance.level,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dateOfBirth': instance.dateOfBirth,
      'phoneNumber': instance.phoneNumber,
      'updatedAt': instance.updatedAt,
    };
