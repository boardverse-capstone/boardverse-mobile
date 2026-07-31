import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// Loads open tournaments and the user's active/history lists in parallel.
  ///
  /// The current Swagger contract exposes `GET /tournaments/open` without a
  /// required game filter. Upcoming/draft tournaments are not exposed to the
  /// player API, so the main page only offers filters backed by real data.
  Future<void> loadTournaments() async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final results = await Future.wait([
      _repository.getOpenTournaments(),
      _repository.getMyRegistrations(
        status: TournamentStatus.ongoing.toBackendStatus(),
      ),
      _repository.getMyRegistrations(
        status: TournamentStatus.completed.toBackendStatus(),
      ),
    ]);
    if (_isDisposed) return;

    _emitFromResults(results[0], results[1], results[2]);
  }

  /// Loads open tournaments filtered by a game template when supported.
  Future<void> loadTournamentsByGame(String gameTemplateId) async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final results = await Future.wait([
      _repository.getOpenTournaments(gameTemplateId: gameTemplateId),
      _repository.getMyRegistrations(
        status: TournamentStatus.ongoing.toBackendStatus(),
      ),
      _repository.getMyRegistrations(
        status: TournamentStatus.completed.toBackendStatus(),
      ),
    ]);
    if (_isDisposed) return;

    _emitFromResults(results[0], results[1], results[2]);
  }

  void _emitFromResults(
    Either<Failure, List<TournamentEntity>> openResult,
    Either<Failure, List<TournamentEntity>> myOngoingResult,
    Either<Failure, List<TournamentEntity>> myCompletedResult,
  ) {
    // Guard: don't emit if cubit is disposed
    if (_isDisposed || isClosed) return;

    List<TournamentEntity> open = const [];
    List<TournamentEntity> ongoing = const [];
    List<TournamentEntity> completed = const [];
    final errors = <String>[];

    openResult.fold((failure) => errors.add('open: ${failure.message}'), (
      tournaments,
    ) {
      open =
          tournaments
              .where(
                (t) =>
                    t.status == TournamentStatus.registrationOpen &&
                    !t.isRegistrationDeadlinePassed &&
                    t.slotsRemaining > 0,
              )
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    myOngoingResult.fold(
      (failure) => errors.add('ongoing: ${failure.message}'),
      (tournaments) {
        ongoing =
            tournaments
                .where((t) => t.status == TournamentStatus.ongoing)
                .toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    myCompletedResult.fold(
      (failure) => errors.add('completed: ${failure.message}'),
      (tournaments) {
        completed =
            tournaments
                .where((t) => t.status == TournamentStatus.completed)
                .toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    // Double-check before emitting
    if (_isDisposed || isClosed) return;

    final hasAnyData =
        open.isNotEmpty || ongoing.isNotEmpty || completed.isNotEmpty;
    if (!hasAnyData && errors.isNotEmpty) {
      emit(TournamentListError(message: errors.first));
      return;
    }

    emit(
      TournamentListLoaded(
        openTournaments: open,
        upcomingTournaments: const [], // backend không expose /upcoming
        ongoingTournaments: ongoing,
        completedTournaments: completed,
        totalOpenCount: open.length,
      ),
    );
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
