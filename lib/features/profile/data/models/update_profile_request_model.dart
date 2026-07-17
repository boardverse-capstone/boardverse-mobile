import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_profile_request_model.freezed.dart';
part 'update_profile_request_model.g.dart';

/// Request body for PUT /api/userprofile.
///
/// Only changed fields should be sent — all fields are optional per the
/// backend contract.
@freezed
abstract class UpdateProfileRequestModel with _$UpdateProfileRequestModel {
  const factory UpdateProfileRequestModel({
    String? bio,
    String? globalElo,
    int? level,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  }) = _UpdateProfileRequestModel;

  factory UpdateProfileRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestModelFromJson(json);
}
