import 'package:json_annotation/json_annotation.dart';

part 'request_password_reset_request_model.g.dart';

@JsonSerializable()
class RequestPasswordResetRequestModel {
  final String email;

  RequestPasswordResetRequestModel({required this.email});

  factory RequestPasswordResetRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestPasswordResetRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$RequestPasswordResetRequestModelToJson(this);
}
