import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/config/app_config.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'tournament_list_state.dart';

/// Cubit for managing tournament list state.
class TournamentListCubit extends Cubit<TournamentListState> {
  final TournamentRepository _repository;
  bool _isDisposed = false;

  TournamentListCubit({required this._repository})
      : super(const TournamentListInitial());

  /// Loads open tournaments + my registrations in parallel.
  ///
  /// Backend hiện chỉ có:
  /// - `GET /api/v1/tournaments/open?gameTemplateId=...`
  /// - `GET /api/v1/tournaments/me?status=...`
  ///
  /// Endpoint `/tournaments/upcoming` trả 404 → đã bỏ.
  /// Endpoint `/open` yêu cầu `gameTemplateId` bắt buộc (theo docs,
  /// backend trả 400 nếu thiếu), nên ta truyền Splendor ID mặc định.
  Future<void> loadTournaments() async {
    return loadTournamentsByGame(AppConfig.defaultSplendorGameTemplateId);
  }

  /// Loads tournaments filtered by the given game template id.
  Future<void> loadTournamentsByGame(String gameTemplateId) async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final openResult = await _repository.getOpenTournaments(
      gameTemplateId: gameTemplateId,
    );
    if (_isDisposed) return;

    final myOngoingResult =
        await _repository.getMyRegistrations(status: 'OnGoing');
    if (_isDisposed) return;

    final myCompletedResult =
        await _repository.getMyRegistrations(status: 'Completed');

    return _emitFromResults(
      openResult,
      myOngoingResult,
      myCompletedResult,
    );
  }

  void _emitFromResults(
    Either<Failure, List<TournamentEntity>> openResult,
    Either<Failure, List<TournamentEntity>> myOngoingResult,
    Either<Failure, List<TournamentEntity>> myCompletedResult,
  ) {
    // Guard: don't emit if cubit is disposed
    if (_isDisposed || isClosed) return;

    String? errorMessage;
    List<TournamentEntity> open = const [];
    List<TournamentEntity> ongoing = const [];
    List<TournamentEntity> completed = const [];

    openResult.fold(
      (failure) => errorMessage = failure.message,
      (tournaments) {
        open = tournaments
            .where((t) =>
                t.status == TournamentStatus.registrationOpen &&
                !t.isRegistrationDeadlinePassed &&
                t.slotsRemaining > 0)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      },
    );

    myOngoingResult.fold(
      (failure) => errorMessage ??= failure.message,
      (tournaments) {
        ongoing = tournaments
            .where((t) => t.status == TournamentStatus.ongoing)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    myCompletedResult.fold(
      (failure) => errorMessage ??= failure.message,
      (tournaments) {
        completed = tournaments
            .where((t) => t.status == TournamentStatus.completed)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    // Double-check before emitting
    if (_isDisposed || isClosed) return;

    if (errorMessage != null &&
        open.isEmpty &&
        ongoing.isEmpty &&
        completed.isEmpty) {
      emit(TournamentListError(message: errorMessage!));
      return;
    }

    emit(TournamentListLoaded(
      openTournaments: open,
      upcomingTournaments: const [], // backend không expose /upcoming
      ongoingTournaments: ongoing,
      completedTournaments: completed,
      totalOpenCount: open.length,
    ));
  }

  /// Refreshes the tournament list.
  Future<void> refresh() async {
    await loadTournaments();
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    return super.close();
  }
}
