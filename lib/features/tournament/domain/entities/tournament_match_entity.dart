/// Tournament match entity representing a single game table in a round.
class TournamentMatchEntity {
  final String id;
  final int roundNumber;
  final bool isFinal;
  final int tableNumber;
  final MatchStatus status;
  final String? winnerId;
  final List<MatchPlayerResult> results;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String? notes;

  const TournamentMatchEntity({
    required this.id,
    required this.roundNumber,
    required this.isFinal,
    required this.tableNumber,
    required this.status,
    this.winnerId,
    required this.results,
    this.actualStartTime,
    this.actualEndTime,
    this.notes,
  });

  /// Whether this match has been completed.
  bool get isCompleted => status == MatchStatus.completed;

  /// Whether this match is currently in progress.
  bool get isOngoing => status == MatchStatus.onGoing;

  /// Whether this match has been cancelled.
  bool get isCancelled => status == MatchStatus.cancelled;

  /// Duration of the match if completed.
  Duration? get duration {
    if (actualStartTime == null || actualEndTime == null) return null;
    return actualEndTime!.difference(actualStartTime!);
  }

  /// Gets the winner's result if available.
  MatchPlayerResult? get winnerResult {
    if (winnerId == null) return null;
    try {
      return results.firstWhere((r) => r.oderId == winnerId);
    } catch (_) {
      return null;
    }
  }

  /// Formatted round display (e.g., "Vòng 1", "Chung kết").
  String get roundDisplayName {
    if (isFinal) return 'Chung kết';
    return 'Vòng $roundNumber';
  }
}

/// Match status enum.
enum MatchStatus {
  scheduled,
  onGoing,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Sắp bắt đầu';
      case MatchStatus.onGoing:
        return 'Đang diễn ra';
      case MatchStatus.completed:
        return 'Đã kết thúc';
      case MatchStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static MatchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return MatchStatus.scheduled;
      case 'ongoing':
        return MatchStatus.onGoing;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }
}

/// Individual player result in a match.
class MatchPlayerResult {
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int cardsBought;
  final bool isWinner;
  int? rank;

  MatchPlayerResult({
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.cardsBought,
    required this.isWinner,
    this.rank,
  });
}
