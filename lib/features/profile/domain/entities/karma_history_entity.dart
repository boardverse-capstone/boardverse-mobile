import 'package:equatable/equatable.dart';

/// Domain entity for karma status returned by GET /me/karma-history.
class KarmaHistoryEntity extends Equatable {
  final String userId;
  final String username;
  final int karmaPoints;
  final String gamerTier;
  final String? avatarUrl;
  final String? updatedAt;

  const KarmaHistoryEntity({
    required this.userId,
    required this.username,
    required this.karmaPoints,
    required this.gamerTier,
    this.avatarUrl,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        karmaPoints,
        gamerTier,
        avatarUrl,
        updatedAt,
      ];
}
