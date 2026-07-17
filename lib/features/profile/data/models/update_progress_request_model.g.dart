// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_progress_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateProgressRequestModel _$UpdateProgressRequestModelFromJson(
  Map<String, dynamic> json,
) => _UpdateProgressRequestModel(
  globalElo: (json['globalElo'] as num).toInt(),
  level: (json['level'] as num).toInt(),
);

Map<String, dynamic> _$UpdateProgressRequestModelToJson(
  _UpdateProgressRequestModel instance,
) => <String, dynamic>{
  'globalElo': instance.globalElo,
  'level': instance.level,
};
