import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final TournamentRepository _repository;

  LeaderboardCubit({required this._repository})
      : super(const LeaderboardInitial());

  Future<void> loadLeaderboard({int topCount = 100}) async {
    emit(const LeaderboardLoading());

    final result = await _repository.getLeaderboard(topCount: topCount);

    result.fold(
      (failure) => emit(LeaderboardError(message: failure.message)),
      (entries) => emit(LeaderboardLoaded(
        entries: entries,
        totalPlayers: entries.length,
      )),
    );
  }

  Future<void> refresh() => loadLeaderboard();
}