// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegisterRequestModel _$RegisterRequestModelFromJson(
  Map<String, dynamic> json,
) => _RegisterRequestModel(
  username: json['username'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$RegisterRequestModelToJson(
  _RegisterRequestModel instance,
) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'password': instance.password,
};
