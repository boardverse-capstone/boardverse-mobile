import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_email_request_model.freezed.dart';
part 'verify_email_request_model.g.dart';

/// Request body for `POST /api/Auth/verify-email`.
///
/// The [token] field is the 6-digit OTP code sent to the user's email.
@freezed
abstract class VerifyEmailRequestModel with _$VerifyEmailRequestModel {
  const factory VerifyEmailRequestModel({
    required String token,
  }) = _VerifyEmailRequestModel;

  factory VerifyEmailRequestModel.fromJson(Map<String, dynamic> json) =>
      _$VerifyEmailRequestModelFromJson(json);
}
