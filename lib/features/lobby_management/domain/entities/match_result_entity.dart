import 'package:equatable/equatable.dart';

/// Trạng thái đồng thuận kết quả trận đấu.
enum ConsensusStatus {
  /// Chưa đủ thành viên gửi kết quả.
  awaitingSubmissions,

  /// Mâu thuẫn kết quả (vd: cả hai bên đều Win).
  conflict,

  /// Đồng thuận 100%, Elo đã được cập nhật.
  finalized;

  /// Chuyển từ string sang enum.
  static ConsensusStatus fromString(String? value) {
    if (value == null) return ConsensusStatus.awaitingSubmissions;
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'awaitingsubmissions':
      case 'awaiting_submissions':
      case 'awaiting-submissions':
        return ConsensusStatus.awaitingSubmissions;
      case 'conflict':
        return ConsensusStatus.conflict;
      case 'finalized':
        return ConsensusStatus.finalized;
      default:
        return ConsensusStatus.awaitingSubmissions;
    }
  }
}

/// Loại kết quả trận đấu có thể chọn.
enum MatchOutcome {
  win,
  loss,
  draw;

  /// Label hiển thị cho người dùng.
  String get label {
    switch (this) {
      case MatchOutcome.win:
        return 'Thắng';
      case MatchOutcome.loss:
        return 'Thua';
      case MatchOutcome.draw:
        return 'Hòa';
    }
  }

  /// Giá trị string gửi lên API.
  String get value => name;

  /// Chuyển từ string (API) sang enum.
  static MatchOutcome fromString(String? value) {
    if (value == null) return MatchOutcome.win;
    final normalized = value.toLowerCase().trim();
    for (final outcome in MatchOutcome.values) {
      if (outcome.name == normalized) return outcome;
    }
    return MatchOutcome.win;
  }
}

/// Thông tin kết quả trận đấu từ API.
class MatchResultEntity extends Equatable {
  /// ID của lobby.
  final String lobbyId;

  /// ID của game template.
  final String gameTemplateId;

  /// Tên game.
  final String gameName;

  /// Game có hỗ trợ nhập kết quả không.
  final bool supportsMatchResults;

  /// Trạng thái đồng thuận.
  final ConsensusStatus consensusStatus;

  /// Số thành viên đã gửi kết quả.
  final int submittedCount;

  /// Tổng số thành viên cần gửi kết quả.
  final int requiredCount;

  /// Lý do mâu thuẫn (nếu có).
  final String? conflictReason;

  /// Các loại kết quả có thể chọn.
  final List<MatchOutcome> availableOutcomes;

  /// Danh sách submissions của các thành viên.
  final List<MatchSubmissionEntity> submissions;

  const MatchResultEntity({
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

  /// Kiểm tra current user đã submit chưa.
  bool hasCurrentUserSubmitted(List<MatchSubmissionEntity> submissions, String currentUserId) {
    return submissions.any((s) => s.isCurrentUser && s.outcome != null);
  }

  /// Kiểm tra có mâu thuẫn không.
  bool get hasConflict => consensusStatus == ConsensusStatus.conflict;

  /// Kiểm tra đã finalize chưa.
  bool get isFinalized => consensusStatus == ConsensusStatus.finalized;

  /// Kiểm tra đang chờ submissions.
  bool get isAwaiting => consensusStatus == ConsensusStatus.awaitingSubmissions;

  /// Số thành viên còn lại cần submit.
  int get remainingSubmissions => requiredCount - submittedCount;

  @override
  List<Object?> get props => [
    lobbyId,
    gameTemplateId,
    gameName,
    supportsMatchResults,
    consensusStatus,
    submittedCount,
    requiredCount,
    conflictReason,
    availableOutcomes,
    submissions,
  ];
}

/// Submission của một thành viên.
class MatchSubmissionEntity extends Equatable {
  /// ID của user.
  final String odId;

  /// Username.
  final String username;

  /// Kết quả đã chọn (null nếu chưa submit).
  final MatchOutcome? outcome;

  /// Có phải là current user không.
  final bool isCurrentUser;

  const MatchSubmissionEntity({
    required this.odId,
    required this.username,
    this.outcome,
    required this.isCurrentUser,
  });

  @override
  List<Object?> get props => [odId, username, outcome, isCurrentUser];
}
