import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String userId,
    required String username,
    String? avatarUrl,
    String? avatarBorderUrl,
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
    int? karmaPoints,
    String? gamerTier,
    required int globalElo,
    required int level,
    @Default(0) int currentExp,
    String? lastActiveAt,
    String? updatedAt,
    required bool hasProfile,
    @Default(true) bool isFriendListPublic,
    String? acceptFriendRequestsFrom,
    @Default(0) int friendLimit,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

extension ProfileModelX on ProfileModel {
  ProfileEntity toEntity() => ProfileEntity(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        avatarBorderUrl: avatarBorderUrl,
        bio: bio,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        globalElo: globalElo,
        level: level,
        currentExp: currentExp,
        lastActiveAt: lastActiveAt,
        updatedAt: updatedAt,
        hasProfile: hasProfile,
        isFriendListPublic: isFriendListPublic,
        acceptFriendRequestsFrom: acceptFriendRequestsFrom,
        friendLimit: friendLimit,
      );
}
