import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_profile_request_model.freezed.dart';
part 'create_profile_request_model.g.dart';

@freezed
abstract class CreateProfileRequestModel with _$CreateProfileRequestModel {
  const factory CreateProfileRequestModel({
    required String bio,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String phoneNumber,
  }) = _CreateProfileRequestModel;

  factory CreateProfileRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateProfileRequestModelFromJson(json);
}
