import 'package:equatable/equatable.dart';

import '../../domain/entities/voting_session.dart';

/// Sealed class cho trạng thái voting.
sealed class VotingState extends Equatable {
  const VotingState();

  @override
  List<Object?> get props => [];
}

/// Initial state - chưa có voting.
class VotingInitial extends VotingState {
  const VotingInitial();
}

/// Loading state - đang tải voting.
class VotingLoading extends VotingState {
  const VotingLoading();
}

/// Có pending votes nhưng user chưa bắt đầu vote.
class VotingPending extends VotingState {
  /// Danh sách các candidate có thể bị mark no-show.
  final List<VotingCandidate> candidates;

  /// Số người đã check-in.
  final int checkedInCount;

  /// Threshold cần để mark no-show.
  final int threshold;

  const VotingPending({
    required this.candidates,
    required this.checkedInCount,
    required this.threshold,
  });

  @override
  List<Object?> get props => [candidates, checkedInCount, threshold];
}

/// Đang trong quá trình vote cho một target.
class VotingActive extends VotingState {
  /// Session voting hiện tại.
  final VotingSession session;

  /// ID của user hiện tại (để check đã vote chưa).
  final String currentUserId;

  /// User đã vote chưa?
  final bool hasVoted;

  const VotingActive({
    required this.session,
    required this.currentUserId,
    this.hasVoted = false,
  });

  @override
  List<Object?> get props => [session, currentUserId, hasVoted];
}

/// Kết quả voting - hiển thị kết quả cho user.
class VotingResult extends VotingState {
  /// Danh sách player bị mark NO_SHOW.
  final List<VotingCandidate> noShowPlayers;

  /// Danh sách player KHÔNG bị mark.
  final List<VotingCandidate> attendedPlayers;

  const VotingResult({
    required this.noShowPlayers,
    required this.attendedPlayers,
  });

  @override
  List<Object?> get props => [noShowPlayers, attendedPlayers];
}

/// Voting đã hoàn thành - chuyển sang complete.
class VotingComplete extends VotingState {
  const VotingComplete();
}

/// Lỗi voting.
class VotingFailure extends VotingState {
  final String message;

  const VotingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Candidate trong voting (player có thể được bình chọn).
class VotingCandidate extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isHost;

  const VotingCandidate({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, isHost];
}
