import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/game_play_configuration_entity.dart';
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

    if (isClosed) return;
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

    if (isClosed) return;
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
      if (isClosed) return;
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

    final gameResult = await repository.getBoardGameDetails(gameId);
    final cafesResult = await repository.getNearbyCafesWithGame(
      gameId: gameId,
      latitude: latitude,
      longitude: longitude,
    );

    if (isClosed) return;

    await gameResult.fold(
      (failure) async => emit(MatchmakingFailure(message: failure.message)),
      (gameDetail) async {
        if (gameDetail == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        await cafesResult.fold(
          (failure) async => emit(MatchmakingFailure(message: failure.message)),
          (cafes) async {
            final nearbyCafes = _filterCafesWithGame(cafes, gameId);

            if (!isGpsEnabled) {
              emit(MatchmakingGpsDisabled(selectedGame: gameDetail.toBoardGameEntity()));
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
              if (isClosed) return;
              similarResult.fold(
                (failure) => emit(
                  MatchmakingOutOfRadius(selectedGame: gameDetail.toBoardGameEntity(), similarGames: []),
                ),
                (similarGames) => emit(
                  MatchmakingOutOfRadius(
                    selectedGame: gameDetail.toBoardGameEntity(),
                    similarGames: similarGames,
                  ),
                ),
              );
              return;
            }

            emit(
              MatchmakingGameDetail(
                game: gameDetail,
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

    if (isClosed) return;

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

      if (isClosed) return;

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

      if (isClosed) return;
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

  // ─── New API methods (Backend mới) ─────────────────────────────────

  /// Tìm kiếm + lọc + phân trang — gọi `GET /api/v1/board-games?...`.
  Future<void> searchWithFilterPaged({
    String? query,
    List<String>? categoryIds,
    int? playerCount,
    List<DurationRange>? durationRanges,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.searchBoardGamesPaged(
      query: query,
      categoryIds: categoryIds,
      playerCount: playerCount,
      durationRanges: durationRanges,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (games) => emit(
        MatchmakingSearchResults(
          games: games,
          query: query,
          filter: SearchFilterEntity(
            query: query,
            categoryIds: categoryIds,
            minPlayers: playerCount,
            durationRanges: durationRanges,
            pageNumber: pageNumber,
            pageSize: pageSize,
          ),
        ),
      ),
    );
  }

  /// Load chi tiết game đầy đủ (kèm components[]) — `GET /api/v1/board-games/{id}`.
  Future<void> loadBoardGameDetails(
    String gameId, {
    double latitude = 10.7769,
    double longitude = 106.7009,
    bool isGpsEnabled = true,
  }) async {
    emit(const MatchmakingLoading());

    final detailResult = await repository.getBoardGameDetails(gameId);
    final cafesEither = await repository.getNearbyCafesWithGame(
      gameId: gameId,
      latitude: latitude,
      longitude: longitude,
    );

    if (isClosed) return;

    await detailResult.fold(
      (failure) async => emit(MatchmakingFailure(message: failure.message)),
      (detail) async {
        if (detail == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        if (isClosed) return;
        await cafesEither.fold(
          (failure) async =>
              emit(MatchmakingFailure(message: failure.message)),
          (cafes) async {
            final nearbyCafes = _filterCafesWithGame(cafes, gameId);
            final isOutOfRadius =
                cafes.isEmpty && !nearbyCafes.any((c) => c.distanceKm <= 15);

            emit(MatchmakingBoardGameDetailLoaded(
              game: detail,
              nearbyCafes: nearbyCafes,
              isGpsEnabled: isGpsEnabled,
              isOutOfRadius: isOutOfRadius,
            ));
          },
        );
      },
    );
  }

  /// Load cấu hình chơi của tựa game — `GET /api/v1/board-games/{id}/play-configuration`.
  Future<void> loadGamePlayConfiguration(String gameId) async {
    final result = await repository.getGamePlayConfiguration(gameId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (config) => emit(MatchmakingPlayConfigurationLoaded(
        config: config,
        gameId: gameId,
      )),
    );
  }

  /// Điều hướng chế độ chơi — `POST /api/v1/board-games/{id}/play-navigation`.
  /// Trả về cho UI để push sang Lobby (Group) hoặc Solo Booking.
  Future<void> resolvePlayNavigation({
    required String gameId,
    required PlayMode mode,
  }) async {
    emit(MatchmakingPlayNavigationResolving(gameId: gameId, mode: mode));

    final result = await repository.resolvePlayNavigation(
      gameId: gameId,
      mode: mode,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (navigation) => emit(MatchmakingPlayNavigationResolved(
        navigation: navigation,
      )),
    );
  }

  /// Lấy quán gần dùng vị trí đã lưu — `GET /api/cafes/nearby/me`.
  Future<void> loadNearbyCafesForCurrentUser({
    required String gameId,
    double radiusKm = 15.0,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.getNearbyCafesForCurrentUser(
      gameId: gameId,
      radiusKm: radiusKm,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (data) => emit(MatchmakingNearbyCafesLoaded(
        gameId: gameId,
        cafes: data.cafes,
        emptyResultMessage: data.emptyResultMessage,
        alternativeSuggestions: data.alternativeSuggestions,
      )),
    );
  }

  /// Lấy quán gần theo toạ độ — `GET /api/cafes/nearby?...`.
  Future<void> loadNearbyCafesWithCoordinates({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.getNearbyCafesWithGameSearch(
      gameId: gameId,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (data) => emit(MatchmakingNearbyCafesLoaded(
        gameId: gameId,
        cafes: data.cafes,
        emptyResultMessage: data.emptyResultMessage,
        alternativeSuggestions: data.alternativeSuggestions,
      )),
    );
  }
}
