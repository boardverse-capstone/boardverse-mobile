import 'package:equatable/equatable.dart';

import '../../domain/entities/match_result_entity.dart';
import '../../domain/entities/elo_update_entity.dart';

sealed class MatchResultState extends Equatable {
  const MatchResultState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu.
class MatchResultInitial extends MatchResultState {
  const MatchResultInitial();
}

/// Đang tải trạng thái consensus.
class MatchResultLoading extends MatchResultState {
  const MatchResultLoading();
}

/// Trạng thái consensus đã tải.
class MatchResultLoaded extends MatchResultState {
  final MatchResultEntity result;
  final MatchOutcome? selectedOutcome;
  final bool isSubmitting;

  const MatchResultLoaded({
    required this.result,
    this.selectedOutcome,
    this.isSubmitting = false,
  });

  @override
  List<Object?> get props => [result, selectedOutcome, isSubmitting];

  MatchResultLoaded copyWith({
    MatchResultEntity? result,
    MatchOutcome? selectedOutcome,
    bool? isSubmitting,
  }) {
    return MatchResultLoaded(
      result: result ?? this.result,
      selectedOutcome: selectedOutcome ?? this.selectedOutcome,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Đã submit thành công (chưa finalize).
class MatchResultSubmitted extends MatchResultState {
  final MatchResultEntity result;
  final MatchOutcome submittedOutcome;

  const MatchResultSubmitted({
    required this.result,
    required this.submittedOutcome,
  });

  @override
  List<Object?> get props => [result, submittedOutcome];
}

/// Đã finalize - hiển thị Elo changes.
class MatchResultFinalized extends MatchResultState {
  final MatchResultEntity result;
  final MatchResultSubmitResponse submitResponse;

  const MatchResultFinalized({
    required this.result,
    required this.submitResponse,
  });

  @override
  List<Object?> get props => [result, submitResponse];
}

/// Có mâu thuẫn - yêu cầu re-submit.
class MatchResultConflict extends MatchResultState {
  final MatchResultEntity result;
  final String conflictReason;

  const MatchResultConflict({
    required this.result,
    required this.conflictReason,
  });

  @override
  List<Object?> get props => [result, conflictReason];
}

/// Lỗi xảy ra.
class MatchResultError extends MatchResultState {
  final String message;

  const MatchResultError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Response sau khi submit (chứa Elo updates).
class MatchResultSubmitResponse extends Equatable {
  final String lobbyId;
  final ConsensusStatus consensusStatus;
  final int submittedCount;
  final int requiredCount;
  final String? matchHistoryId;
  final List<EloUpdateEntity> eloUpdates;

  const MatchResultSubmitResponse({
    required this.lobbyId,
    required this.consensusStatus,
    required this.submittedCount,
    required this.requiredCount,
    this.matchHistoryId,
    this.eloUpdates = const [],
  });

  bool get isFinalized => consensusStatus == ConsensusStatus.finalized;

  @override
  List<Object?> get props => [
    lobbyId,
    consensusStatus,
    submittedCount,
    requiredCount,
    matchHistoryId,
    eloUpdates,
  ];
}
