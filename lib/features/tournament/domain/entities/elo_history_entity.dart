/// Elo history entry for a player's tournament performance.
class EloHistoryEntity {
  final String id;
  final String oderId;
  final String displayName;
  final String tournamentTitle;
  final String tournamentId;
  final int initialElo;
  final int finalElo;
  final int delta;
  final DateTime playedAt;
  final int? rank;

  const EloHistoryEntity({
    required this.id,
    required this.oderId,
    required this.displayName,
    required this.tournamentTitle,
    required this.tournamentId,
    required this.initialElo,
    required this.finalElo,
    required this.delta,
    required this.playedAt,
    this.rank,
  });

  /// Whether the player gained Elo.
  bool get gainedElo => delta > 0;

  /// Whether the player lost Elo.
  bool get lostElo => delta < 0;

  /// Formatted delta display (e.g., "+25", "-15").
  String get formattedDelta {
    if (delta > 0) return '+$delta';
    return delta.toString();
  }

  /// Formatted rank display (e.g., "#3").
  String? get formattedRank {
    if (rank == null) return null;
    return '#$rank';
  }

  /// Final rank display for winner.
  String get rankDisplayName {
    if (rank == null) return '-';
    switch (rank!) {
      case 1:
        return 'Nhà vô địch';
      case 2:
        return 'Á quân';
      case 3:
        return 'Hạng 3';
      case 4:
        return 'Hạng 4';
      default:
        return 'Hạng $rank';
    }
  }
}
