import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../../domain/repositories/matchmaking_repository.dart';
import '../../../lobby_management/domain/repositories/lobby_repository.dart';
import 'matchmaking_state.dart';

class MatchmakingCubit extends Cubit<MatchmakingState> {
  final MatchmakingRepository repository;
  final LobbyRepository? lobbyRepository;

  MatchmakingCubit({
    required this.repository,
    this.lobbyRepository,
  }) : super(const MatchmakingInitial());

  // ─── Search Games ──────────────────────────────────────────────────────

  Future<void> searchGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.searchBoardGames(
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

  /// Tìm kiếm với SearchFilterEntity (mở rộng)
  Future<void> searchWithFilter(SearchFilterEntity filter) async {
    emit(const MatchmakingLoading());

    final result = await repository.searchGames(filter);

    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (games) => emit(
        MatchmakingSearchResults(
          games: games,
          filter: filter,
        ),
      ),
    );
  }

  /// Load danh mục game categories
  Future<void> loadCategories() async {
    final currentState = state;
    if (currentState is MatchmakingSearchResults) {
      final result = await repository.getGameCategories();
      result.fold(
        (failure) => null, // Keep current state on failure
        (categories) => emit(currentState.copyWith(categories: categories)),
      );
    }
  }

  // ─── Load Game Detail ─────────────────────────────────────────────────

  Future<void> loadGameDetail({
    required String gameId,
    double latitude = 10.7769,
    double longitude = 106.7009,
    bool isGpsEnabled = true,
  }) async {
    emit(const MatchmakingLoading());

    final gameResult = await repository.getBoardGameById(gameId);
    final cafesResult = await repository.getNearbyCafesWithGame(
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
              final similarResult = await repository.getSimilarGames(
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

    final gameResult = await repository.getBoardGameById(gameId);
    final cafesResult = await repository.getNearbyCafesWithGame(
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

  // ─── Seat Availability Methods (BR-05, BR-06) ─────────────────────────

  /// Kiểm tra ghế trống của một quán (BR-05)
  Future<void> checkSeatAvailability({
    required String cafeId,
    required int requiredSeats,
    DateTime? timeSlot,
  }) async {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      // Emit loading state while checking
      emit(currentState.copyWith(
        isCheckingSeats: true,
        selectedCafeId: cafeId,
        clearSeatError: true,
      ));

      final result = await repository.checkSeatsAvailable(
        cafeId: cafeId,
        requiredSeats: requiredSeats,
        timeSlot: timeSlot ?? DateTime.now(),
      );

      await result.fold(
        (failure) async {
          emit(currentState.copyWith(
            isCheckingSeats: false,
            seatErrorMessage: failure.message,
          ));
        },
        (isAvailable) async {
          if (isAvailable) {
            // Load full seat availability details
            await loadSeatAvailability(cafeId: cafeId, timeSlot: timeSlot);
          } else {
            emit(currentState.copyWith(
              isCheckingSeats: false,
              seatErrorMessage: 'Quán không đủ số chỗ trống yêu cầu ($requiredSeats ghế)',
            ));
          }
        },
      );
    }
  }

  /// Load thông tin ghế trống chi tiết
  Future<void> loadSeatAvailability({
    required String cafeId,
    DateTime? timeSlot,
  }) async {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      final result = await repository.getSeatAvailability(
        cafeId: cafeId,
        timeSlot: timeSlot ?? DateTime.now(),
      );

      result.fold(
        (failure) => emit(currentState.copyWith(
          isCheckingSeats: false,
          seatErrorMessage: failure.message,
        )),
        (availability) => emit(currentState.copyWith(
          isCheckingSeats: false,
          selectedCafeSeats: availability,
          selectedCafeId: cafeId,
          clearSeatError: true,
        )),
      );
    }
  }

  /// Clear seat selection
  void clearSeatSelection() {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      emit(currentState.copyWith(
        selectedCafeSeats: null,
        selectedCafeId: null,
        clearSeatError: true,
      ));
    }
  }

  /// Chọn quán để xem chi tiết ghế
  void selectCafe(String cafeId) {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      emit(currentState.copyWith(
        selectedCafeId: cafeId,
        selectedCafeSeats: null, // Will be loaded when accessing
      ));
    }
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
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    final repo = lobbyRepository;
    if (repo == null) {
      return (success: false, lobbyId: null, error: 'Lobby service not available');
    }

    try {
      final result = await repo.createLobby(
        gameId: gameId,
        cafeId: cafeId,
        scheduledTime: scheduledTime,
        additionalSlots: additionalSlots,
        isPublic: isPublic,
        searchRadiusKm: searchRadiusKm,
        minimumKarma: minimumKarma,
        leadTime: leadTime,
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
    if (lobbyRepository == null) return null;
    return null;
  }

  // ─── Helper Methods ───────────────────────────────────────────────────

  /// Kiểm tra xem có thể đặt chỗ không
  bool canBookNow() {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      final seats = currentState.selectedCafeSeats;
      final requiredSeats = currentState.game.minPlayers;
      
      if (seats == null) return false;
      return seats.hasEnoughSeats(requiredSeats);
    }
    return false;
  }

  /// Lấy thông báo lỗi ghế (nếu có)
  String? getSeatErrorMessage() {
    final currentState = state;
    if (currentState is MatchmakingGameDetail) {
      return currentState.seatErrorMessage;
    }
    return null;
  }
}
