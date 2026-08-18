import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';
import 'tournament_list_state.dart';

/// Cubit for managing tournament list state.
class TournamentListCubit extends Cubit<TournamentListState> {
  final TournamentRepository _repository;
  bool _isDisposed = false;

  TournamentListCubit({required this._repository})
    : super(const TournamentListInitial());

  /// Resets the cubit to its initial state. Called on logout so the
  /// next user doesn't see cached lists/registrations from the
  /// previous session.
  void reset() {
    if (_isDisposed || isClosed) return;
    emit(const TournamentListInitial());
  }

  /// Loads open tournaments and the user's active/history lists in parallel.
  ///
  /// Gọi 1 endpoint `/tournaments/open` (giải đang mở, server lọc deadline
  /// + slots) + 5 endpoint `/tournaments?status=` (RegistrationClosed,
  /// OnGoing, Completed, Cancelled) song song. Endpoint mới trả về đầy đủ
  /// `TournamentEntity` thay vì flat shape như `/my-registrations`.
  Future<void> loadTournaments() async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final results = await Future.wait<Object>([
      _repository.getOpenTournaments(),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.registrationClosed.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.ongoing.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.completed.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.cancelled.toBackendStatus(),
      ),
    ]);
    if (_isDisposed) return;

    _emitFromResults(
      results[0] as Either<Failure, List<TournamentEntity>>,
      results[1] as Either<Failure, List<TournamentEntity>>,
      results[2] as Either<Failure, List<TournamentEntity>>,
      results[3] as Either<Failure, List<TournamentEntity>>,
      results[4] as Either<Failure, List<TournamentEntity>>,
    );
  }

  /// Loads open tournaments filtered by a game template when supported.
  Future<void> loadTournamentsByGame(String gameTemplateId) async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final results = await Future.wait<Object>([
      _repository.getOpenTournaments(gameTemplateId: gameTemplateId),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.registrationClosed.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.ongoing.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.completed.toBackendStatus(),
      ),
      _repository.getTournamentsByStatus(
        status: TournamentStatus.cancelled.toBackendStatus(),
      ),
    ]);
    if (_isDisposed) return;

    _emitFromResults(
      results[0] as Either<Failure, List<TournamentEntity>>,
      results[1] as Either<Failure, List<TournamentEntity>>,
      results[2] as Either<Failure, List<TournamentEntity>>,
      results[3] as Either<Failure, List<TournamentEntity>>,
      results[4] as Either<Failure, List<TournamentEntity>>,
    );
  }

  /// Loads only open tournaments without my-registrations.
  /// Used by ActivityPage which only displays open tournaments.
  Future<void> loadOpenTournamentsOnly() async {
    if (_isDisposed) return;
    emit(const TournamentListLoading());

    final result = await _repository.getOpenTournaments();
    if (_isDisposed) return;

    result.fold(
      (failure) {
        if (_isDisposed || isClosed) return;
        emit(TournamentListError(message: failure.message));
      },
      (tournaments) {
        if (_isDisposed || isClosed) return;
        final open = tournaments
            .where(
              (t) =>
                  t.status == TournamentStatus.registrationOpen &&
                  !t.isRegistrationDeadlinePassed &&
                  t.slotsRemaining > 0,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        emit(
          TournamentListLoaded(
            openTournaments: open,
            upcomingTournaments: const [],
            closedTournaments: const [],
            ongoingTournaments: const [],
            completedTournaments: const [],
            cancelledTournaments: const [],
            totalOpenCount: open.length,
          ),
        );
      },
    );
  }

  void _emitFromResults(
    Either<Failure, List<TournamentEntity>> openResult,
    Either<Failure, List<TournamentEntity>> closedResult,
    Either<Failure, List<TournamentEntity>> ongoingResult,
    Either<Failure, List<TournamentEntity>> completedResult,
    Either<Failure, List<TournamentEntity>> cancelledResult,
  ) {
    if (_isDisposed || isClosed) return;

    List<TournamentEntity> open = const [];
    List<TournamentEntity> closed = const [];
    List<TournamentEntity> ongoing = const [];
    List<TournamentEntity> completed = const [];
    List<TournamentEntity> cancelled = const [];
    final errors = <String>[];

    openResult.fold(
      (failure) => errors.add('open: ${failure.message}'),
      (tournaments) {
        // `/tournaments/open` server đã lọc deadline + slots, nhưng client
        // vẫn check lại để an toàn (tránh race condition khi deadline
        // pass ngay lúc đang fetch).
        open = tournaments
            .where(
              (t) =>
                  t.status == TournamentStatus.registrationOpen &&
                  !t.isRegistrationDeadlinePassed &&
                  t.slotsRemaining > 0,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      },
    );

    closedResult.fold(
      (failure) => errors.add('closed: ${failure.message}'),
      (tournaments) {
        closed = tournaments
            .where(
              (t) => t.status == TournamentStatus.registrationClosed,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      },
    );

    ongoingResult.fold(
      (failure) => errors.add('ongoing: ${failure.message}'),
      (tournaments) {
        ongoing = tournaments
            .where((t) => t.status == TournamentStatus.ongoing)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    completedResult.fold(
      (failure) => errors.add('completed: ${failure.message}'),
      (tournaments) {
        completed = tournaments
            .where((t) => t.status == TournamentStatus.completed)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    cancelledResult.fold(
      (failure) => errors.add('cancelled: ${failure.message}'),
      (tournaments) {
        cancelled = tournaments
            .where((t) => t.status == TournamentStatus.cancelled)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      },
    );

    if (_isDisposed || isClosed) return;

    final hasAnyData =
        open.isNotEmpty ||
        closed.isNotEmpty ||
        ongoing.isNotEmpty ||
        completed.isNotEmpty ||
        cancelled.isNotEmpty;

    if (!hasAnyData && errors.isNotEmpty) {
      emit(TournamentListError(message: errors.first));
      return;
    }

    emit(
      TournamentListLoaded(
        openTournaments: open,
        upcomingTournaments: const [],
        closedTournaments: closed,
        ongoingTournaments: ongoing,
        completedTournaments: completed,
        cancelledTournaments: cancelled,
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
