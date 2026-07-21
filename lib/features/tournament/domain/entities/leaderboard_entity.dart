/// Leaderboard entry for global Elo ranking.
class LeaderboardEntryEntity {
  final int rank;
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int globalElo;
  final int karma;
  final int tournamentsPlayed;
  final int tournamentsWon;

  const LeaderboardEntryEntity({
    required this.rank,
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.globalElo,
    required this.karma,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
  });

  /// Win rate percentage.
  double get winRate {
    if (tournamentsPlayed == 0) return 0;
    return (tournamentsWon / tournamentsPlayed) * 100;
  }

  /// Formatted Elo display.
  String get formattedElo => '$globalElo';

  /// Elo tier based on rating.
  EloTier get eloTier {
    if (globalElo >= 2500) return EloTier.diamond;
    if (globalElo >= 2000) return EloTier.platinum;
    if (globalElo >= 1500) return EloTier.gold;
    if (globalElo >= 1000) return EloTier.silver;
    return EloTier.bronze;
  }

  /// Whether this entry is the current user.
  bool isCurrentUser(String currentUserId) => oderId == currentUserId;
}

/// Elo tier classification.
enum EloTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get label {
    switch (this) {
      case EloTier.bronze:
        return 'Bronze';
      case EloTier.silver:
        return 'Silver';
      case EloTier.gold:
        return 'Gold';
      case EloTier.platinum:
        return 'Platinum';
      case EloTier.diamond:
        return 'Diamond';
    }
  }

  String get emoji {
    switch (this) {
      case EloTier.bronze:
        return '';
      case EloTier.silver:
        return '';
      case EloTier.gold:
        return '';
      case EloTier.platinum:
        return '';
      case EloTier.diamond:
        return '';
    }
  }
}
