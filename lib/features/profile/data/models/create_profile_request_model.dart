import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_profile_request_model.freezed.dart';
part 'create_profile_request_model.g.dart';

@freezed
abstract class CreateProfileRequestModel with _$CreateProfileRequestModel {
  const factory CreateProfileRequestModel({
    required String gamerTag,
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) = _CreateProfileRequestModel;

  factory CreateProfileRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateProfileRequestModelFromJson(json);
}
