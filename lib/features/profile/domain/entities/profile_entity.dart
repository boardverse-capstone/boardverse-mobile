import 'package:equatable/equatable.dart';

/// Clean domain entity representing a user's profile.
class ProfileEntity extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? avatarBorderUrl;
  final String? bio;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? phoneNumber;
  final int? karmaPoints;
  final String? gamerTier;
  final int globalElo;
  final int level;
  final int currentExp;
  final String? lastActiveAt;
  final String? updatedAt;
  final bool hasProfile;
  final bool isFriendListPublic;
  final String? acceptFriendRequestsFrom;
  final int friendLimit;

  const ProfileEntity({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.avatarBorderUrl,
    this.bio,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.karmaPoints,
    this.gamerTier,
    required this.globalElo,
    required this.level,
    this.currentExp = 0,
    this.lastActiveAt,
    this.updatedAt,
    required this.hasProfile,
    this.isFriendListPublic = true,
    this.acceptFriendRequestsFrom,
    this.friendLimit = 0,
  });

  /// Display name: firstName + lastName if available, else username.
  String get displayName {
    final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return fullName.isNotEmpty ? fullName : username;
  }

  /// EXP needed to reach the next level.
  /// Each level requires `level * 100` EXP.
  int get expForNextLevel => level * 100;

  /// Progress percentage (0.0 – 1.0) toward next level.
  double get levelProgress {
    final max = expForNextLevel;
    if (max <= 0) return 0;
    return (currentExp / max).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        userId,
        username,
        avatarUrl,
        avatarBorderUrl,
        bio,
        firstName,
        lastName,
        dateOfBirth,
        phoneNumber,
        karmaPoints,
        gamerTier,
        globalElo,
        level,
        currentExp,
        lastActiveAt,
        updatedAt,
        hasProfile,
        isFriendListPublic,
        acceptFriendRequestsFrom,
        friendLimit,
      ];
}
