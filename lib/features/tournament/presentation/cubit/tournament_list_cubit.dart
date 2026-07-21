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

  TournamentListCubit({required this._repository})
      : super(const TournamentListInitial());

  /// Loads open and upcoming tournaments in parallel.
  Future<void> loadTournaments() async {
    emit(const TournamentListLoading());

    final openResult = await _repository.getOpenTournaments();
    final upcomingResult = await _repository.getUpcomingTournaments();
    final myOngoingResult =
        await _repository.getMyRegistrations(status: 'OnGoing');
    final myCompletedResult =
        await _repository.getMyRegistrations(status: 'Completed');

    return _emitFromResults(
      openResult,
      upcomingResult,
      myOngoingResult,
      myCompletedResult,
    );
  }

  /// Loads tournaments using the provided game template.
  Future<void> loadTournamentsByGame(String gameTemplateId) async {
    emit(const TournamentListLoading());

    final openResult = await _repository.getOpenTournaments(
      gameTemplateId: gameTemplateId,
    );
    final upcomingResult = await _repository.getUpcomingTournaments(
      gameTemplateId: gameTemplateId,
    );
    final myOngoingResult =
        await _repository.getMyRegistrations(status: 'OnGoing');
    final myCompletedResult =
        await _repository.getMyRegistrations(status: 'Completed');

    return _emitFromResults(
      openResult,
      upcomingResult,
      myOngoingResult,
      myCompletedResult,
    );
  }

  void _emitFromResults(
    Either<Failure, List<TournamentEntity>> openResult,
    Either<Failure, List<TournamentEntity>> upcomingResult,
    Either<Failure, List<TournamentEntity>> myOngoingResult,
    Either<Failure, List<TournamentEntity>> myCompletedResult,
  ) {
    String? errorMessage;
    List<TournamentEntity> open = const [];
    List<TournamentEntity> upcoming = const [];
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

    upcomingResult.fold(
      (failure) => errorMessage ??= failure.message,
      (tournaments) {
        upcoming = tournaments
            .where((t) =>
                t.status == TournamentStatus.upcoming ||
                (t.status == TournamentStatus.registrationOpen &&
                    t.isRegistrationDeadlinePassed))
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

    if (errorMessage != null &&
        open.isEmpty &&
        upcoming.isEmpty &&
        ongoing.isEmpty &&
        completed.isEmpty) {
      emit(TournamentListError(message: errorMessage!));
      return;
    }

    emit(TournamentListLoaded(
      openTournaments: open,
      upcomingTournaments: upcoming,
      ongoingTournaments: ongoing,
      completedTournaments: completed,
      totalOpenCount: open.length,
    ));
  }

  /// Refreshes the tournament list.
  Future<void> refresh() async {
    await loadTournaments();
  }
}
