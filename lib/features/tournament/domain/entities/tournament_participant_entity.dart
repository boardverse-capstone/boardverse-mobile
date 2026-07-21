/// Tournament participant entity representing a player in a tournament.
class TournamentParticipantEntity {
  final String id;
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int elo;
  final int karma;
  final ParticipantStatus status;
  final int swissScore;
  final int prestigePoints;
  final int? finalRank;
  final int eloDelta;
  final bool isWalkIn;
  final bool isCurrentUser;

  const TournamentParticipantEntity({
    required this.id,
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.elo,
    required this.karma,
    required this.status,
    required this.swissScore,
    required this.prestigePoints,
    this.finalRank,
    required this.eloDelta,
    required this.isWalkIn,
    this.isCurrentUser = false,
  });

  /// Whether this participant is the current user.
  bool get isCurrentUserFlag => isCurrentUser;

  /// Whether this participant has finished (completed the tournament).
  bool get hasFinished => status == ParticipantStatus.finished;

  /// Whether this participant is an active competitor.
  bool get isActive => status == ParticipantStatus.active;

  /// Formatted Swiss score display (e.g., "2.5/3").
  String get formattedSwissScore => '$swissScore/$swissScore';
}

/// Participant status enum.
enum ParticipantStatus {
  /// Player has registered but not yet checked in.
  registered,

  /// Player has checked in at the venue.
  checkedIn,

  /// Player is actively competing.
  active,

  /// Player has finished the tournament.
  finished,

  /// Player withdrew before the tournament started.
  withdrawn,

  /// Player was marked as no-show (didn't show up after check-in).
  noShow;

  String get label {
    switch (this) {
      case ParticipantStatus.registered:
        return 'Đã đăng ký';
      case ParticipantStatus.checkedIn:
        return 'Đã check-in';
      case ParticipantStatus.active:
        return 'Đang thi đấu';
      case ParticipantStatus.finished:
        return 'Hoàn thành';
      case ParticipantStatus.withdrawn:
        return 'Đã rút lui';
      case ParticipantStatus.noShow:
        return 'Vắng mặt';
    }
  }

  static ParticipantStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'registered':
        return ParticipantStatus.registered;
      case 'checkedin':
        return ParticipantStatus.checkedIn;
      case 'active':
        return ParticipantStatus.active;
      case 'finished':
        return ParticipantStatus.finished;
      case 'withdrawn':
        return ParticipantStatus.withdrawn;
      case 'noshow':
        return ParticipantStatus.noShow;
      default:
        return ParticipantStatus.registered;
    }
  }
}
