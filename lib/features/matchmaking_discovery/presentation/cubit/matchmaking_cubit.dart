import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/game_play_configuration_entity.dart';
import '../../domain/entities/nearby_cafes_search_result_entity.dart';
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

    // Theo spec `cafe.md` (luồng mobile được recommend):
    //   1. PUT /api/userprofile/me/location — lưu vị trí server
    //   2. GET /api/cafes/nearby/me?gameTemplateId=... — không cần gửi
    //      lat/lng vì server dùng LastKnownLocation trên profile.
    // Nếu user chưa lưu vị trí (`/nearby/me` trả 400), fallback về
    // public `GET /api/cafes/nearby` với hardcode HCMC.
    final cafesResult = await _loadNearbyCafesWithFallback(
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
          (searchResult) async {
            // Server `/api/cafes/nearby?gameTemplateId=...` (AC 2.1) đã đảm
            // bảo chỉ trả về quán có ít nhất một hộp game của `gameTemplateId`
            // (trạng thái `Available` **hoặc** `InUse`). Theo AC 3.1, quán
            // vẫn hiển thị khi tất cả hộp đang `InUse` (UI: "Chờ game
            // ~X phút").
            //
            // Vì vậy filter phải dựa trên `totalGameBoxCount` (Available +
            // InUse) thay vì `availableGameCount` (chỉ Available) — trước
            // đây filter chỉ `availableGameCount > 0` đã loại bỏ nhầm quán
            // có hộp đang `InUse`, dẫn đến UI hiển thị "không có quán gần"
            // dù server trả 200 đầy đủ.
            final nearbyCafes = searchResult.cafes
                .where((c) => c.totalGameBoxCount > 0)
                .toList();

            if (!isGpsEnabled) {
              emit(MatchmakingGpsDisabled(
                selectedGame: gameDetail.toBoardGameEntity(),
              ));
              return;
            }

            // Branch này trước đó có điều kiện logically-impossible
            // `outOfRadiusCafes.isNotEmpty && nearbyCafes.isEmpty`
            // (vì `outOfRadiusCafes` là subset của `nearbyCafes`). Khi
            // server thực sự trả quán out-of-radius (player ở ngoài
            // bán kính 15km), trả về `OutOfRadius` để UI hiển thị game
            // tương tự. Ngược lại, render danh sách bình thường (kể cả
            // những quán out-of-radius để user biết cần mở rộng bán kính).
            final hasInRadius =
                nearbyCafes.any((c) => (c.distanceMeters / 1000.0) <= 15);
            if (!hasInRadius && nearbyCafes.isNotEmpty) {
              final similarResult = await repository.getSimilarGames(
                gameId: gameId,
                latitude: latitude,
                longitude: longitude,
              );
              if (isClosed) return;
              similarResult.fold(
                (failure) => emit(
                  MatchmakingOutOfRadius(
                    selectedGame: gameDetail.toBoardGameEntity(),
                    similarGames: const [],
                  ),
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
                emptyResultMessage: searchResult.emptyResultMessage,
                alternativeSuggestions:
                    searchResult.alternativeSuggestions,
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

  /// Helper: thử `/api/cafes/nearby/me` trước (dùng vị trí lưu trên profile
  /// — chính xác với user thật). Nếu fail (vd: user chưa PUT location → 400),
  /// fallback `/api/cafes/nearby` với lat/lng truyền vào (public).
  ///
  /// Trả về `Either<Failure, NearbyCafesSearchResultEntity>` — không throw
  /// để caller có thể emit từ trong `Either.fold`.
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      _loadNearbyCafesWithFallback({
    required String gameId,
    required double latitude,
    required double longitude,
  }) async {
    final meResult = await repository.getNearbyCafesForCurrentUser(
      gameId: gameId,
      radiusKm: 50.0,
    );
    return meResult.fold(
      (failure) async {
        // Fallback sang `/nearby` với lat/lng tham số.
        return await repository.getNearbyCafesWithGameSearch(
          gameId: gameId,
          latitude: latitude,
          longitude: longitude,
        );
      },
      (data) async => Right(data),
    );
  }

  /// Fallback filter dựa trên `totalGameBoxCount` (Available + InUse) —
  /// server `/api/cafes/nearby?gameTemplateId=...` đã filter theo inventory
  /// rồi, nhưng defensive check vẫn giữ để bỏ qua response rỗng / dữ liệu
  /// cũ. Trước đây dùng `availableGameCount > 0` đã loại bỏ nhầm quán có
  /// hộp đang `InUse` → gây bug "không có quán" trên UI.
  List<CafeEntity> _filterCafesWithGame(
      List<CafeEntity> cafes, String gameId) {
    return cafes.where((cafe) => cafe.totalGameBoxCount > 0).toList();
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
  // Method `createLobby` đã bị xoá theo plan migrate Lobby sang
  // Reservation/BVC. Page `LobbyConfigPage` giờ gọi trực tiếp
  // `ReservationCubit.createQuote()` rồi push `LobbyQuotePage` để user
  // đặt cọc. `LobbyCreateSetupPage` (route trung gian cũ) đã bị xoá vì
  // bị chồng với `LobbyConfigPage`.

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
