// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'karma_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KarmaHistoryModel _$KarmaHistoryModelFromJson(Map<String, dynamic> json) =>
    _KarmaHistoryModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      karmaPoints: (json['karmaPoints'] as num).toInt(),
      gamerTier: json['gamerTier'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$KarmaHistoryModelToJson(_KarmaHistoryModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'karmaPoints': instance.karmaPoints,
      'gamerTier': instance.gamerTier,
      'avatarUrl': instance.avatarUrl,
      'updatedAt': instance.updatedAt,
    };
