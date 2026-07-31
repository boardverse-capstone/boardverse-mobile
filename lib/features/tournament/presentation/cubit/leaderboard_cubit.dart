import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final TournamentRepository _repository;

  LeaderboardCubit({required this._repository})
    : super(const LeaderboardInitial());

  String? _gameTemplateId;

  Future<void> loadLeaderboard({
    int topCount = 100,
    String? gameTemplateId,
  }) async {
    _gameTemplateId = gameTemplateId;
    emit(const LeaderboardLoading());

    final result = await _repository.getLeaderboard(
      topCount: topCount,
      gameTemplateId: gameTemplateId,
    );

    result.fold(
      (failure) => emit(LeaderboardError(message: failure.message)),
      (entries) => emit(
        LeaderboardLoaded(entries: entries, totalPlayers: entries.length),
      ),
    );
  }

  Future<void> refresh() => loadLeaderboard(gameTemplateId: _gameTemplateId);
}
