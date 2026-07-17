// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_location_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateLocationRequestModel _$UpdateLocationRequestModelFromJson(
  Map<String, dynamic> json,
) => _UpdateLocationRequestModel(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  source: (json['source'] as num).toInt(),
);

Map<String, dynamic> _$UpdateLocationRequestModelToJson(
  _UpdateLocationRequestModel instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'source': instance.source,
};
