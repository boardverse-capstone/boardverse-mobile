import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mock_rating_datasource.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  final RatingRepository _repository;
  String _currentSessionId = 'session_001';

  RatingCubit({required this._repository})
      : super(const RatingInitial());

  // ─── Start Rating Flow ─────────────────────────────────────────────────

  Future<void> startRatingFlow(String sessionId) async {
    emit(const RatingLoading());
    _currentSessionId = sessionId;

    final result = await _repository.getAvailableKarmaTags();

    result.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (tags) {
        final players = MockRatingDatasource.mockPlayersToRate
            .map((p) => RatingPlayer(
                  id: p.id,
                  name: p.name,
                  avatarUrl: p.avatarUrl,
                ))
            .toList();

        emit(KarmaRating(
          playersToRate: players,
          availableTags: tags,
          playerRatings: {},
        ));
      },
    );
  }

  // ─── Toggle Karma Tag ──────────────────────────────────────────────────

  void toggleKarmaTag(String playerId, String tagId) {
    final currentState = state;
    if (currentState is! KarmaRating) return;

    final updatedPlayers = currentState.playersToRate.map((player) {
      if (player.id == playerId) {
        final selectedTags = List<String>.from(player.selectedTagIds);
        if (selectedTags.contains(tagId)) {
          selectedTags.remove(tagId);
        } else {
          selectedTags.add(tagId);
        }
        return player.copyWith(selectedTagIds: selectedTags);
      }
      return player;
    }).toList();

    final updatedRatings = <String, List<String>>{};
    for (final player in updatedPlayers) {
      updatedRatings[player.id] = player.selectedTagIds;
    }

    emit(KarmaRating(
      playersToRate: updatedPlayers,
      availableTags: currentState.availableTags,
      playerRatings: updatedRatings,
    ));
  }

  // ─── Submit Karma Ratings ──────────────────────────────────────────────

  Future<void> submitKarmaRatings() async {
    final currentState = state;
    if (currentState is! KarmaRating) return;

    emit(const RatingLoading());

    final result = await _repository.submitKarmaRating(
      _currentSessionId,
      currentState.playerRatings,
    );

    result.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (_) => emit(const MatchResultEntry()),
    );
  }

  // ─── Submit Match Result ──────────────────────────────────────────────

  Future<void> submitMatchResult(MatchResult result) async {
    emit(const MatchResultEntry(isWaitingConsensus: true));

    final eloResult = await _repository.submitMatchResult(
      _currentSessionId,
      result,
    );

    await Future.delayed(const Duration(seconds: 1));

    eloResult.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (elo) => emit(EloResultDisplay(eloResult: elo)),
    );
  }

  // ─── Skip Match Result (for non-competitive games) ─────────────────────

  void skipMatchResult() {
    emit(const RatingComplete());
  }

  // ─── Complete Rating ──────────────────────────────────────────────────

  void completeRating() {
    emit(const RatingComplete());
  }
}
