import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cafe_entity.dart';
import '../../domain/repositories/matchmaking_repository.dart';
import '../../../lobby_management/domain/repositories/lobby_repository.dart';
import 'matchmaking_state.dart';

class MatchmakingCubit extends Cubit<MatchmakingState> {
  final MatchmakingRepository _repository;
  final LobbyRepository? _lobbyRepository;

  MatchmakingCubit({
    required this._repository,
    this._lobbyRepository,
  }) : super(const MatchmakingInitial());

  // ─── Search Games ──────────────────────────────────────────────────────

  Future<void> searchGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    emit(const MatchmakingLoading());

    final result = await _repository.searchBoardGames(
      query: query,
      category: category,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
    );

    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (games) => emit(
        MatchmakingSearchResults(
          games: games,
          query: query,
          category: category,
          minPlayers: minPlayers,
          maxPlayers: maxPlayers,
        ),
      ),
    );
  }

  // ─── Load Game Detail ─────────────────────────────────────────────────

  Future<void> loadGameDetail({
    required String gameId,
    double latitude = 10.7769,
    double longitude = 106.7009,
    bool isGpsEnabled = true,
  }) async {
    emit(const MatchmakingLoading());

    final gameResult = await _repository.getBoardGameById(gameId);
    final cafesResult = await _repository.getNearbyCafesWithGame(
      gameId: gameId,
      latitude: latitude,
      longitude: longitude,
    );

    await gameResult.fold(
      (failure) async => emit(MatchmakingFailure(message: failure.message)),
      (game) async {
        if (game == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        await cafesResult.fold(
          (failure) async => emit(MatchmakingFailure(message: failure.message)),
          (cafes) async {
            final nearbyCafes = _filterCafesWithGame(cafes, gameId);

            if (!isGpsEnabled) {
              emit(MatchmakingGpsDisabled(selectedGame: game));
              return;
            }

            final outOfRadiusCafes = nearbyCafes
                .where((c) => c.distanceKm > 15)
                .toList();
            if (outOfRadiusCafes.isNotEmpty && nearbyCafes.isEmpty) {
              final similarResult = await _repository.getSimilarGames(
                gameId: gameId,
                latitude: latitude,
                longitude: longitude,
              );
              similarResult.fold(
                (failure) => emit(
                  MatchmakingOutOfRadius(selectedGame: game, similarGames: []),
                ),
                (similarGames) => emit(
                  MatchmakingOutOfRadius(
                    selectedGame: game,
                    similarGames: similarGames,
                  ),
                ),
              );
              return;
            }

            emit(
              MatchmakingGameDetail(
                game: game,
                nearbyCafes: nearbyCafes,
                isGpsEnabled: isGpsEnabled,
                isOutOfRadius: nearbyCafes.isEmpty,
              ),
            );
          },
        );
      },
    );
  }

  // ─── Load Cafes Without GPS ────────────────────────────────────────────

  Future<void> loadCafesWithManualLocation({
    required String gameId,
    String? district,
  }) async {
    emit(const MatchmakingLoading());

    final gameResult = await _repository.getBoardGameById(gameId);
    final cafesResult = await _repository.getNearbyCafesWithGame(
      gameId: gameId,
      latitude: 0,
      longitude: 0,
    );

    await gameResult.fold(
      (failure) async => emit(MatchmakingFailure(message: failure.message)),
      (game) async {
        if (game == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        await cafesResult.fold(
          (failure) async => emit(MatchmakingFailure(message: failure.message)),
          (cafes) {
            final nearbyCafes = _filterCafesWithGame(cafes, gameId);
            emit(
              MatchmakingCafeList(
                selectedGame: game,
                cafes: nearbyCafes,
                isGpsEnabled: false,
              ),
            );
          },
        );
      },
    );
  }

  // ─── Enable GPS ───────────────────────────────────────────────────────

  Future<void> enableGpsAndReload({
    required String gameId,
    double latitude = 10.7769,
    double longitude = 106.7009,
  }) async {
    await loadGameDetail(
      gameId: gameId,
      latitude: latitude,
      longitude: longitude,
      isGpsEnabled: true,
    );
  }

  List<CafeEntity> _filterCafesWithGame(List<CafeEntity> cafes, String gameId) {
    return cafes
        .where((cafe) => cafe.availableGameIds.contains(gameId))
        .toList();
  }

  // ─── Create Lobby ─────────────────────────────────────────────────────

  Future<({bool success, String? lobbyId, String? error})> createLobby({
    required String gameId,
    required String gameName,
    required String cafeId,
    required String cafeName,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
  }) async {
    if (_lobbyRepository == null) {
      return (success: false, lobbyId: null, error: 'Lobby service not available');
    }

    try {
      final result = await _lobbyRepository.createLobby(
        gameId: gameId,
        cafeId: cafeId,
        scheduledTime: scheduledTime,
        additionalSlots: additionalSlots,
        isPublic: isPublic,
      );

      return result.fold(
        (failure) => (success: false, lobbyId: null, error: failure.message),
        (lobby) => (success: true, lobbyId: lobby.id, error: null),
      );
    } catch (e) {
      return (success: false, lobbyId: null, error: e.toString());
    }
  }

  // ─── Get User's Active Lobby ──────────────────────────────────────────

  Future<String?> getUserActiveLobbyId() async {
    if (_lobbyRepository == null) return null;

    // In a real app, this would check local storage or API for user's active lobby
    // For now, return null as we don't have persistence yet
    return null;
  }
}
