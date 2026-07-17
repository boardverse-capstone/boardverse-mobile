// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerLocationModel _$PlayerLocationModelFromJson(Map<String, dynamic> json) =>
    _PlayerLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: json['updatedAt'] as String,
      source: (json['source'] as num).toInt(),
      hasLocation: json['hasLocation'] as bool,
    );

Map<String, dynamic> _$PlayerLocationModelToJson(
  _PlayerLocationModel instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'updatedAt': instance.updatedAt,
  'source': instance.source,
  'hasLocation': instance.hasLocation,
};
