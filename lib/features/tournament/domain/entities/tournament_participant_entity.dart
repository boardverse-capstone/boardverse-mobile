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

  /// Tổng điểm prestige tích luỹ (lifetime).
  final int prestigePoints;

  /// Hạng cuối cùng trong giải (chỉ có khi `status == finished`).
  final int? finalRank;

  /// Chênh lệch Elo sau giải.
  final int eloDelta;
  final bool isWalkIn;
  final bool isCurrentUser;

  /// Tổng số vòng Swiss của giải — dùng để format `swissScore/totalRounds`.
  /// Optional vì participants có thể đứng độc lập (test fixture, mock).
  final int? totalRounds;

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
    this.totalRounds,
  });

  /// Whether this participant is the current user.
  bool get isCurrentUserFlag => isCurrentUser;

  /// Whether this participant has finished (completed the tournament).
  bool get hasFinished => status == ParticipantStatus.finished;

  /// Whether this participant is an active competitor.
  bool get isActive => status == ParticipantStatus.active;

  /// Formatted Swiss score display (e.g., `"2.5/3"`).
  ///
  /// Nếu biết [totalRounds] thì hiển thị `score/totalRounds`.
  /// Ngược lại chỉ hiển thị điểm Swiss thuần (cho trường hợp không
  /// có ngữ cảnh giải).
  String get formattedSwissScore {
    if (totalRounds == null) return swissScore.toString();
    return '$swissScore/$totalRounds';
  }
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
