import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';
import 'elo_history_state.dart';

/// Cubit for managing "My Elo History" view.
///
/// Endpoint `/tournaments/my-elo-history` trả về wrapper
/// `MyEloHistoryResponse { userId, username, currentElo, history[] }` —
/// cubit unwrap response rồi emit [EloHistoryLoaded] cho UI.
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
      (response) {
        final history = response.history;

        if (history.isEmpty) {
          emit(
            const EloHistoryLoaded(
              history: [],
              initialElo: 0,
              currentElo: 0,
              totalDelta: 0,
              tournamentsPlayed: 0,
              username: '',
            ),
          );
          return;
        }

        // Sort ascending by playedAt so the chart reads left → right.
        final sorted = [...history]
          ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

        final initial = sorted.first.initialElo;
        final current = response.currentElo != 0
            ? response.currentElo
            : sorted.last.finalElo;
        final totalDelta = sorted.fold<int>(
          0,
          (sum, entry) => sum + entry.delta,
        );

        emit(
          EloHistoryLoaded(
            history: sorted,
            initialElo: initial,
            currentElo: current,
            totalDelta: totalDelta,
            tournamentsPlayed: sorted.length,
            username: response.username,
          ),
        );
      },
    );
  }

  /// Refreshes the history.
  Future<void> refresh() async {
    await loadEloHistory();
  }
}
