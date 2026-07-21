/// Trạng thái đồng thuận kết quả trận trong lobby.
///
/// Mapping theo spec `.agents/docs/apis_docs/matches.md:48-52`:
/// - [AwaitingSubmissions] : Chưa đủ thành viên gửi.
/// - [Conflict]            : Mâu thuẫn (vd. cả hai bên đều Win) — cho phép gửi lại.
/// - [Finalized]           : Đồng thuận 100%, Elo đã cập nhật — cố định, không cho gửi thêm.
enum MatchConsensusStatus {
  awaitingSubmissions,
  conflict,
  finalized;

  static MatchConsensusStatus fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'awaitingsubmissions':
      case 'awaiting_submissions':
      case 'awaiting-submissions':
        return MatchConsensusStatus.awaitingSubmissions;
      case 'conflict':
        return MatchConsensusStatus.conflict;
      case 'finalized':
        return MatchConsensusStatus.finalized;
      default:
        return MatchConsensusStatus.awaitingSubmissions;
    }
  }
}

/// Outcome user chọn — UI binding 1-1 với spec:
/// - Win  : thắng
/// - Loss : thua
/// - Draw : hòa
enum MatchOutcome {
  win,
  loss,
  draw;

  String get apiValue {
    switch (this) {
      case MatchOutcome.win:
        return 'Win';
      case MatchOutcome.loss:
        return 'Loss';
      case MatchOutcome.draw:
        return 'Draw';
    }
  }

  static MatchOutcome fromApi(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'win':
        return MatchOutcome.win;
      case 'loss':
      case 'lose':
        return MatchOutcome.loss;
      case 'draw':
        return MatchOutcome.draw;
      default:
        throw ArgumentError('Unknown MatchOutcome: $raw');
    }
  }
}

/// Dữ liệu đồng thuận hiện tại của 1 lobby — payload của `GET /results/lobbies/{lobbyId}`.
class MatchConsensusEntity {
  final String lobbyId;
  final String gameTemplateId;
  final String gameName;
  final bool supportsMatchResults;
  final MatchConsensusStatus consensusStatus;
  final int submittedCount;
  final int requiredCount;
  final String? conflictReason;
  final List<MatchOutcomeChoice> availableOutcomes;
  final List<MatchSubmission> submissions;

  const MatchConsensusEntity({
    required this.lobbyId,
    required this.gameTemplateId,
    required this.gameName,
    required this.supportsMatchResults,
    required this.consensusStatus,
    required this.submittedCount,
    required this.requiredCount,
    this.conflictReason,
    required this.availableOutcomes,
    required this.submissions,
  });

  /// Trạng thái user có thể gửi / gửi lại tiếp hay không.
  bool get canSubmit => consensusStatus != MatchConsensusStatus.finalized;
}

/// Nhãn hiển thị khi user bấm chọn — mapping `availableOutcomes` của backend.
class MatchOutcomeChoice {
  final MatchOutcome outcome;
  final String label;

  const MatchOutcomeChoice({required this.outcome, required this.label});
}

/// Một lượt submit của 1 member trong lobby.
class MatchSubmission {
  final String userId;
  final String username;
  final MatchOutcome outcome;
  final bool isCurrentUser;

  const MatchSubmission({
    required this.userId,
    required this.username,
    required this.outcome,
    required this.isCurrentUser,
  });
}

/// Response khi gửi kết quả — payload của `POST /results` (matches.md:81-104).
/// Có thêm `eloUpdates` để UI hiển thị ngay sau khi finalize.
class MatchSubmissionResultEntity {
  final String lobbyId;
  final MatchConsensusStatus consensusStatus;
  final int submittedCount;
  final int requiredCount;
  final String? matchHistoryId;
  final List<EloUpdateEntity> eloUpdates;

  const MatchSubmissionResultEntity({
    required this.lobbyId,
    required this.consensusStatus,
    required this.submittedCount,
    required this.requiredCount,
    this.matchHistoryId,
    required this.eloUpdates,
  });

  bool get isFinalized => consensusStatus == MatchConsensusStatus.finalized;
}

class EloUpdateEntity {
  final String userId;
  final MatchOutcome reportedOutcome;
  final int eloBefore;
  final int eloAfter;
  final int eloDelta;

  const EloUpdateEntity({
    required this.userId,
    required this.reportedOutcome,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
  });
}
