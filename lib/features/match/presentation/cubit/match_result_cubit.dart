import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/match_consensus_entity.dart';
import '../../domain/repositories/match_result_repository.dart';

// ─── States ──────────────────────────────────────────────────────────────

sealed class MatchResultState extends Equatable {
  const MatchResultState();
  @override
  List<Object?> get props => [];
}

class MatchResultInitial extends MatchResultState {
  const MatchResultInitial();
}

class MatchResultLoading extends MatchResultState {
  const MatchResultLoading();
}

class MatchResultLoaded extends MatchResultState {
  final MatchConsensusEntity consensus;
  const MatchResultLoaded(this.consensus);

  @override
  List<Object?> get props => [consensus];
}

/// Khi `consensusStatus == Finalized`, Cubit emit state này để UI
/// navigate sang EloResultDisplay (rating_page.dart: widget đã có sẵn).
class MatchResultFinalized extends MatchResultState {
  final MatchSubmissionResultEntity result;
  const MatchResultFinalized(this.result);

  @override
  List<Object?> get props => [result];
}

class MatchResultFailure extends MatchResultState {
  final String message;
  const MatchResultFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────

class MatchResultCubit extends Cubit<MatchResultState> {
  MatchResultCubit({required this._repository})
      : super(const MatchResultInitial());

  final MatchResultRepository _repository;

  String? _activeLobbyId;

  /// Load consensus cho 1 lobby — gọi khi user mở rating/match page.
  Future<void> loadMatchResult(String lobbyId) async {
    _activeLobbyId = lobbyId;
    emit(const MatchResultLoading());
    final res = await _repository.getMatchResult(lobbyId);
    if (isClosed) return;
    res.fold(
      (failure) => emit(MatchResultFailure(message: failure.message)),
      (consensus) => emit(MatchResultLoaded(consensus)),
    );
  }

  /// Submit kết quả của user hiện tại — có thể resubmit nếu bị Conflict.
  /// Khi `result.isFinalized` → emit `MatchResultFinalized` để UI navigate.
  Future<void> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async {
    if (_activeLobbyId != null && _activeLobbyId != lobbyId) {
      _activeLobbyId = lobbyId;
    }

    // Optimistic loading (giữ snapshot cũ).
    final previousState = state;
    if (previousState is! MatchResultLoaded) {
      emit(const MatchResultLoading());
    }

    final res = await _repository.submitMatchResult(
      lobbyId: lobbyId,
      outcome: outcome,
    );
    if (isClosed) return;
    res.fold(
      (failure) {
        // Không xoá snapshot trước đó — chỉ emit failure để UI báo toast.
        emit(MatchResultFailure(message: failure.message));
        // Optional: restore previous snapshot ngay sau failure.
        if (previousState is MatchResultLoaded) {
          // Delay nhỏ để UI kịp hiển thị snackbar trước khi reload.
          // ignore: null_check_on_nullable_type_parameter
          Future<void>.delayed(const Duration(milliseconds: 10)).then((_) {
            if (!isClosed) emit(previousState);
          });
        }
      },
      (result) {
        if (result.isFinalized) {
          emit(MatchResultFinalized(result));
        } else {
          // Conflict / Awaiting — refetch snapshot mới nhất để thấy submission mới.
          loadMatchResult(lobbyId);
        }
      },
    );
  }

  /// Reset state — gọi khi user thoát page.
  void reset() {
    _activeLobbyId = null;
    emit(const MatchResultInitial());
  }

  /// Helper build failure cho callers muốn dùng `Either` ngoài state.
  Failure failure(String message) =>
      const ServerFailure(message: '');
}
