import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_profile_request_model.freezed.dart';
part 'create_profile_request_model.g.dart';

/// Request body for POST /api/userprofile.
///
/// All fields are optional per the backend contract. The form layer still
/// enforces required validation on the UI side; this model reflects what
/// the API actually accepts.
@freezed
abstract class CreateProfileRequestModel with _$CreateProfileRequestModel {
  const factory CreateProfileRequestModel({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) = _CreateProfileRequestModel;

  factory CreateProfileRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateProfileRequestModelFromJson(json);
}
