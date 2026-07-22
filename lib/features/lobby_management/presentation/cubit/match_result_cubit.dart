import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/base/lobby_remote_datasource.dart';
import '../../data/models/elo_update_model.dart';
import '../../domain/entities/match_result_entity.dart';
import '../../domain/entities/elo_update_entity.dart';
import 'match_result_state.dart';

class MatchResultCubit extends Cubit<MatchResultState> {
  final LobbyRemoteDatasource _remoteDatasource;

  MatchResultEntity? _currentResult;
  MatchOutcome? _selectedOutcome;

  MatchResultCubit({required this._remoteDatasource}) : super(const MatchResultInitial());

  /// Load trạng thái consensus của một lobby.
  Future<void> loadMatchResult(String lobbyId) async {
    emit(const MatchResultLoading());

    final result = await _remoteDatasource.getMatchResultStatus(lobbyId);

    result.fold(
      (failure) => emit(MatchResultError(message: failure.message)),
      (matchResult) {
        _currentResult = matchResult;

        if (matchResult.isFinalized) {
          emit(MatchResultLoaded(result: matchResult));
        } else if (matchResult.hasConflict) {
          emit(MatchResultConflict(
            result: matchResult,
            conflictReason: matchResult.conflictReason ?? 'Kết quả không khớp',
          ));
        } else {
          emit(MatchResultLoaded(result: matchResult));
        }
      },
    );
  }

  /// Chọn một outcome.
  void selectOutcome(MatchOutcome outcome) {
    _selectedOutcome = outcome;
    final currentState = state;
    if (currentState is MatchResultLoaded) {
      emit(currentState.copyWith(selectedOutcome: outcome));
    }
  }

  /// Submit kết quả.
  Future<void> submitResult(String lobbyId) async {
    if (_selectedOutcome == null) {
      emit(const MatchResultError(message: 'Vui lòng chọn kết quả'));
      return;
    }

    final currentState = state;
    if (currentState is MatchResultLoaded) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    final result = await _remoteDatasource.submitMatchResult(
      lobbyId: lobbyId,
      outcome: _selectedOutcome!,
    );

    result.fold(
      (failure) => emit(MatchResultError(message: failure.message)),
      (response) {
        final updatedResult = _currentResult?.copyWith(
          submittedCount: response.submittedCount,
          consensusStatus: _mapConsensusStatus(response.consensusStatus),
        ) ?? MatchResultEntity(
          lobbyId: lobbyId,
          gameTemplateId: '',
          gameName: 'Board Game',
          supportsMatchResults: true,
          consensusStatus: _mapConsensusStatus(response.consensusStatus),
          submittedCount: response.submittedCount,
          requiredCount: response.requiredCount,
          availableOutcomes: MatchOutcome.values,
          submissions: [],
        );

        _currentResult = updatedResult;

        if (response.isFinalized) {
          emit(MatchResultFinalized(
            result: updatedResult,
            submitResponse: MatchResultSubmitResponse(
              lobbyId: response.lobbyId,
              consensusStatus: _mapConsensusStatus(response.consensusStatus),
              submittedCount: response.submittedCount,
              requiredCount: response.requiredCount,
              matchHistoryId: response.matchHistoryId,
              eloUpdates: response.eloUpdates.map((e) => EloUpdateEntity(
                odId: e.odId,
                reportedOutcome: e.reportedOutcome,
                eloBefore: e.eloBefore,
                eloAfter: e.eloAfter,
                eloDelta: e.eloDelta,
              )).toList(),
            ),
          ));
        } else if (response.consensusStatus == MatchConsensusStatus.conflict) {
          emit(MatchResultConflict(
            result: updatedResult,
            conflictReason: 'Kết quả không khớp với các thành viên khác',
          ));
        } else {
          emit(MatchResultSubmitted(
            result: updatedResult,
            submittedOutcome: _selectedOutcome!,
          ));
          emit(MatchResultLoaded(
            result: updatedResult,
            selectedOutcome: _selectedOutcome,
          ));
        }
      },
    );
  }

  ConsensusStatus _mapConsensusStatus(MatchConsensusStatus status) {
    switch (status) {
      case MatchConsensusStatus.awaitingSubmissions:
        return ConsensusStatus.awaitingSubmissions;
      case MatchConsensusStatus.conflict:
        return ConsensusStatus.conflict;
      case MatchConsensusStatus.finalized:
        return ConsensusStatus.finalized;
    }
  }

  /// Reset state.
  void reset() {
    _currentResult = null;
    _selectedOutcome = null;
    emit(const MatchResultInitial());
  }
}

/// Extension để copy MatchResultEntity.
extension MatchResultEntityCopy on MatchResultEntity {
  MatchResultEntity copyWith({
    String? lobbyId,
    String? gameTemplateId,
    String? gameName,
    bool? supportsMatchResults,
    ConsensusStatus? consensusStatus,
    int? submittedCount,
    int? requiredCount,
    String? conflictReason,
    List<MatchOutcome>? availableOutcomes,
    List<MatchSubmissionEntity>? submissions,
  }) {
    return MatchResultEntity(
      lobbyId: lobbyId ?? this.lobbyId,
      gameTemplateId: gameTemplateId ?? this.gameTemplateId,
      gameName: gameName ?? this.gameName,
      supportsMatchResults: supportsMatchResults ?? this.supportsMatchResults,
      consensusStatus: consensusStatus ?? this.consensusStatus,
      submittedCount: submittedCount ?? this.submittedCount,
      requiredCount: requiredCount ?? this.requiredCount,
      conflictReason: conflictReason ?? this.conflictReason,
      availableOutcomes: availableOutcomes ?? this.availableOutcomes,
      submissions: submissions ?? this.submissions,
    );
  }
}
