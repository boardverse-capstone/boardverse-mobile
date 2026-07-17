import 'package:equatable/equatable.dart';

/// Clean domain entity representing a user's profile.
class ProfileEntity extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int? karmaPoints;
  final String? gamerTier;
  final int globalElo;
  final int level;
  final String? updatedAt;
  final bool hasProfile;
  // PII from ProfileDetailDto
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? phoneNumber;

  const ProfileEntity({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.karmaPoints,
    this.gamerTier,
    required this.globalElo,
    required this.level,
    this.updatedAt,
    required this.hasProfile,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        avatarUrl,
        bio,
        karmaPoints,
        gamerTier,
        globalElo,
        level,
        updatedAt,
        hasProfile,
        firstName,
        lastName,
        dateOfBirth,
        phoneNumber,
      ];
}
