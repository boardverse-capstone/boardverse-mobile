// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) =>
    _ProfileModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarBorderUrl: json['avatarBorderUrl'] as String?,
      bio: json['bio'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      karmaPoints: (json['karmaPoints'] as num?)?.toInt(),
      gamerTier: json['gamerTier'] as String?,
      globalElo: (json['globalElo'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      currentExp: (json['currentExp'] as num?)?.toInt() ?? 0,
      lastActiveAt: json['lastActiveAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      hasProfile: json['hasProfile'] as bool,
      isFriendListPublic: json['isFriendListPublic'] as bool? ?? true,
      acceptFriendRequestsFrom: json['acceptFriendRequestsFrom'] as String?,
      friendLimit: (json['friendLimit'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProfileModelToJson(_ProfileModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'avatarBorderUrl': instance.avatarBorderUrl,
      'bio': instance.bio,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dateOfBirth': instance.dateOfBirth,
      'phoneNumber': instance.phoneNumber,
      'karmaPoints': instance.karmaPoints,
      'gamerTier': instance.gamerTier,
      'globalElo': instance.globalElo,
      'level': instance.level,
      'currentExp': instance.currentExp,
      'lastActiveAt': instance.lastActiveAt,
      'updatedAt': instance.updatedAt,
      'hasProfile': instance.hasProfile,
      'isFriendListPublic': instance.isFriendListPublic,
      'acceptFriendRequestsFrom': instance.acceptFriendRequestsFrom,
      'friendLimit': instance.friendLimit,
    };
