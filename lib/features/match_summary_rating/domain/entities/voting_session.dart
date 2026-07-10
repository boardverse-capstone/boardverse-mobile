import 'package:equatable/equatable.dart';

/// Loại vote trong voting session.
enum VoteType {
  /// Người này vắng mặt.
  noShow,

  /// Người này có đến.
  notNoShow,

  /// Skip - không muốn bình chọn.
  skip,
}

/// Extension cho VoteType.
extension VoteTypeExtension on VoteType {
  String get displayLabel {
    switch (this) {
      case VoteType.noShow:
        return 'Vắng mặt';
      case VoteType.notNoShow:
        return 'Có đến';
      case VoteType.skip:
        return 'Bỏ qua';
    }
  }

  String get iconName {
    switch (this) {
      case VoteType.noShow:
        return 'cancel';
      case VoteType.notNoShow:
        return 'check_circle';
      case VoteType.skip:
        return 'skip_next';
    }
  }
}

/// Entity cho một phiên biểu quyết (Voting Session).
///
/// Đại diện cho một cuộc bình chọn về việc một thành viên
/// có bị đánh dấu no-show hay không.
class VotingSession extends Equatable {
  final String id;
  final String sessionId;
  final String targetPlayerId;
  final String targetPlayerName;
  final String? targetPlayerAvatar;
  final List<String> eligibleVoters;
  final int threshold;
  final DateTime startedAt;
  final DateTime deadline;
  final Map<String, VoteType> votes;

  const VotingSession({
    required this.id,
    required this.sessionId,
    required this.targetPlayerId,
    required this.targetPlayerName,
    this.targetPlayerAvatar,
    required this.eligibleVoters,
    required this.threshold,
    required this.startedAt,
    required this.deadline,
    this.votes = const {},
  });

  /// Số vote NO_SHOW hiện tại.
  int get noShowVotes =>
      votes.values.where((v) => v == VoteType.noShow).length;

  /// Số vote NOT_NO_SHOW hiện tại.
  int get notNoShowVotes =>
      votes.values.where((v) => v == VoteType.notNoShow).length;

  /// Số vote SKIP hiện tại.
  int get skipVotes =>
      votes.values.where((v) => v == VoteType.skip).length;

  /// Tổng số vote đã submit.
  int get totalVotes => votes.length;

  /// Số voter còn lại chưa vote.
  int get remainingVoters => eligibleVoters.length - totalVotes;

  /// Thời gian còn lại (âm nếu đã hết hạn).
  Duration get remainingTime => deadline.difference(DateTime.now());

  /// Đã hết thời gian chưa.
  bool get isExpired => DateTime.now().isAfter(deadline);

  /// Tất cả voter đã vote chưa.
  bool get allVoted => totalVotes >= eligibleVoters.length;

  /// Kiểm tra xem voting có đạt threshold NO_SHOW chưa.
  /// Nếu đạt → mark target là no-show.
  bool get isNoShowConfirmed => noShowVotes >= threshold;

  /// Kiểm tra xem voting có đạt threshold NOT_NO_SHOW chưa.
  /// Nếu đạt → target không bị mark no-show.
  bool get isNotNoShowConfirmed => notNoShowVotes >= threshold;

  /// Copy với 1 số field thay đổi.
  VotingSession copyWith({
    String? id,
    String? sessionId,
    String? targetPlayerId,
    String? targetPlayerName,
    String? targetPlayerAvatar,
    List<String>? eligibleVoters,
    int? threshold,
    DateTime? startedAt,
    DateTime? deadline,
    Map<String, VoteType>? votes,
  }) {
    return VotingSession(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      targetPlayerName: targetPlayerName ?? this.targetPlayerName,
      targetPlayerAvatar: targetPlayerAvatar ?? this.targetPlayerAvatar,
      eligibleVoters: eligibleVoters ?? this.eligibleVoters,
      threshold: threshold ?? this.threshold,
      startedAt: startedAt ?? this.startedAt,
      deadline: deadline ?? this.deadline,
      votes: votes ?? this.votes,
    );
  }

  /// Thêm một vote vào session.
  VotingSession addVote(String voterId, VoteType vote) {
    final newVotes = Map<String, VoteType>.from(votes);
    newVotes[voterId] = vote;
    return copyWith(votes: newVotes);
  }

  /// Tính threshold theo công thức: floor(n/2) + 1
  static int calculateThreshold(int checkedInCount) {
    return (checkedInCount / 2).floor() + 1;
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        targetPlayerId,
        targetPlayerName,
        targetPlayerAvatar,
        eligibleVoters,
        threshold,
        startedAt,
        deadline,
        votes,
      ];
}
