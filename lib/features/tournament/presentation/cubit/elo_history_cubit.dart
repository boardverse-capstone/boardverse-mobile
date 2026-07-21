import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'elo_history_state.dart';

/// Cubit for managing "My Elo History" view.
class EloHistoryCubit extends Cubit<EloHistoryState> {
  final TournamentRepository _repository;

  EloHistoryCubit({required this._repository})
      : super(const EloHistoryInitial());

  /// Loads elo history for the current user.
  Future<void> loadEloHistory() async {
    emit(const EloHistoryLoading());

    final result = await _repository.getMyEloHistory();

    result.fold(
      (failure) => emit(EloHistoryError(message: failure.message)),
      (history) {
        if (history.isEmpty) {
          emit(const EloHistoryLoaded(
            history: [],
            initialElo: 0,
            currentElo: 0,
            totalDelta: 0,
            tournamentsPlayed: 0,
          ));
          return;
        }

        // Sort ascending by playedAt so the chart reads left → right.
        final sorted = [...history]
          ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

        final initial = sorted.first.initialElo;
        final current = sorted.last.finalElo;
        final totalDelta = current - initial;

        emit(EloHistoryLoaded(
          history: sorted,
          initialElo: initial,
          currentElo: current,
          totalDelta: totalDelta,
          tournamentsPlayed: sorted.length,
        ));
      },
    );
  }

  /// Refreshes the history.
  Future<void> refresh() async {
    await loadEloHistory();
  }
}