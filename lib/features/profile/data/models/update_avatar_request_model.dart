import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_avatar_request_model.freezed.dart';
part 'update_avatar_request_model.g.dart';

/// Request body for PUT /api/userprofile/me/avatar.
@freezed
abstract class UpdateAvatarRequestModel with _$UpdateAvatarRequestModel {
  const factory UpdateAvatarRequestModel({
    required String avatarUrl,
  }) = _UpdateAvatarRequestModel;

  factory UpdateAvatarRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateAvatarRequestModelFromJson(json);
}
