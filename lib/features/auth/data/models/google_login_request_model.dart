import 'package:json_annotation/json_annotation.dart';

part 'google_login_request_model.g.dart';

@JsonSerializable()
class GoogleLoginRequestModel {
  final String idToken;

  GoogleLoginRequestModel({required this.idToken});

  factory GoogleLoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleLoginRequestModelToJson(this);
}
