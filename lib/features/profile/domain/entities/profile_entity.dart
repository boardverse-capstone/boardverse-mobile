import 'package:equatable/equatable.dart';

/// Clean domain entity representing a user's profile.
class ProfileEntity extends Equatable {
  final String userId;
  final String username;
  final String? gamerTag;
  final String? avatarUrl;
  final String? bio;
  final int? karmaPoints;
  final String? gamerTier;
  final int globalElo;
  final int level;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? updatedAt;

  const ProfileEntity({
    required this.userId,
    required this.username,
    this.gamerTag,
    this.avatarUrl,
    this.bio,
    this.karmaPoints,
    this.gamerTier,
    required this.globalElo,
    required this.level,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        gamerTag,
        avatarUrl,
        bio,
        karmaPoints,
        gamerTier,
        globalElo,
        level,
        firstName,
        lastName,
        dateOfBirth,
        phoneNumber,
        updatedAt,
      ];
}
