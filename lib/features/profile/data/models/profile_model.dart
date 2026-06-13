import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/profile_entity.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String userId,
    required String username,
    String? gamerTag,
    String? avatarUrl,
    String? bio,
    int? karmaPoints,
    String? gamerTier,
    required int globalElo,
    required int level,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
    String? updatedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

extension ProfileModelX on ProfileModel {
  ProfileEntity toEntity() => ProfileEntity(
        userId: userId,
        username: username,
        gamerTag: gamerTag,
        avatarUrl: avatarUrl,
        bio: bio,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        globalElo: globalElo,
        level: level,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        updatedAt: updatedAt,
      );
}
