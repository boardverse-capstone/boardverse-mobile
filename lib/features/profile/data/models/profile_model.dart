import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class ProfileModel with _$ProfileModel {
  /// PII fields (firstName, lastName, dateOfBirth, phoneNumber) come from
  /// ProfileDetailDto returned by POST /api/userprofile — not guaranteed in
  /// GET responses until the profile has been created.
  const factory ProfileModel({
    required String userId,
    required String username,
    String? avatarUrl,
    String? bio,
    int? karmaPoints,
    String? gamerTier,
    required int globalElo,
    required int level,
    String? updatedAt,
    required bool hasProfile,
    // PII from ProfileDetailDto
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

extension ProfileModelX on ProfileModel {
  ProfileEntity toEntity() => ProfileEntity(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        globalElo: globalElo,
        level: level,
        updatedAt: updatedAt,
        hasProfile: hasProfile,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
      );
}
