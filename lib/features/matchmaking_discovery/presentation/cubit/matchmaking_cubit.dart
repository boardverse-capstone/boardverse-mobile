import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/board_game_entity.dart';
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
      (games) {
        _refreshPopularGameId(games);
        emit(
          MatchmakingSearchResults(
            games: games,
            query: query,
            category: category,
            minPlayers: minPlayers,
            maxPlayers: maxPlayers,
          ),
        );
      },
    );
  }

  /// Tìm kiếm với SearchFilterEntity (mở rộng)
  Future<void> searchWithFilter(SearchFilterEntity filter) async {
    emit(const MatchmakingLoading());

    final result = await repository.searchGames(filter);

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (games) {
        _refreshPopularGameId(games);
        emit(
          MatchmakingSearchResults(
            games: games,
            filter: filter,
          ),
        );
      },
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
            // Theo AC 2.1 của `cafe.md`, server đã filter `cafes` theo
            // `gameTemplateId` (quán có ít nhất 1 hộp game của `gameId`,
            // trạng thái Available hoặc InUse). Theo AC 3.1, quán vẫn hiển
            // thị khi tất cả hộp đang InUse (UI: "Chờ game ~X phút").
            //
            // Vì vậy filter phải dựa trên `totalGameBoxCount` (Available +
            // InUse) thay vì `availableGameCount` (chỉ Available) — trước
            // đây filter chỉ `availableGameCount > 0` đã loại bỏ nhầm quán
            // có hộp đang InUse → gây bug "không có quán" trên UI dù server
            // trả 200 đầy đủ.
            final nearbyCafes = searchResult.cafes
                .where((c) => c.totalGameBoxCount > 0)
                .toList();

            if (!isGpsEnabled) {
              emit(MatchmakingGpsDisabled(
                selectedGame: gameDetail.toBoardGameEntity(),
              ));
              return;
            }

            // Gộp tất cả trường hợp về `MatchmakingGameDetail` (kể cả khi
            // không có quán trong bán kính). State class này đã có sẵn
            // `isOutOfRadius` + `alternativeSuggestions` đủ để render UI
            // thống nhất, không cần state riêng `MatchmakingOutOfRadius`.
            //
            // Lý do thống nhất:
            // 1. Trước đây code tách thành `OutOfRadius` riêng + gọi thêm API
            //    `getSimilarGames(...)` để lấy game tương tự. Nhưng data
            //    này đã có sẵn trong `searchResult.alternativeSuggestions`
            //    từ API `/api/cafes/nearby` (AC 5.2). Gọi API riêng là
            //    duplicate + tăng latency.
            // 2. Case "có quán nhưng quá xa" (vd: 22.8km, xa hơn 15km) và
            //    case "không có quán nào" trước đây hiển thị 2 UI khác nhau:
            //    - Có quán xa → `_buildOutOfRadiusView` (icon to + message
            //      "Không có quán nào trong bán kính 15km" + carousel game
            //      tương tự). Khi `similarGames = []` (backend không gợi ý)
            //      thì carousel rỗng → UI "đề xuất lại chính game này" vô
            //      nghĩa.
            //    - Không có quán → `_buildGameDetailView` với empty state +
            //      alternatives (UI đẹp hơn, user thích).
            //    → Thống nhất về 1 UI giống case "không có quán".
            final hasInRadius =
                nearbyCafes.any((c) => (c.distanceMeters / 1000.0) <= 15);
            final isOutOfRadius =
                !hasInRadius; // Cả 2 case (có quán xa hoặc không có quán)

            emit(
              MatchmakingGameDetail(
                game: gameDetail,
                nearbyCafes: nearbyCafes,
                isGpsEnabled: isGpsEnabled,
                isOutOfRadius: isOutOfRadius,
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
      (games) {
        _refreshPopularGameId(games);
        emit(
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
        );
      },
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
///
/// `gameId` đã trở thành optional — backend không còn bắt buộc. Truyền
/// null nếu muốn lấy tất cả quán trong bán kính.
Future<void> loadNearbyCafesForCurrentUser({
  String? gameId,
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
      gameId: gameId ?? '',
      cafes: data.cafes,
      emptyResultMessage: data.emptyResultMessage,
      alternativeSuggestions: data.alternativeSuggestions,
    )),
  );
}

/// Lấy quán gần theo toạ độ — `GET /api/cafes/nearby?...`.
Future<void> loadNearbyCafesWithCoordinates({
  String? gameId,
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
      gameId: gameId ?? '',
      cafes: data.cafes,
      emptyResultMessage: data.emptyResultMessage,
      alternativeSuggestions: data.alternativeSuggestions,
    )),
  );
}

/// Reset state về [MatchmakingInitial] khi player ấn "Đổi game" từ
/// [LobbyCafeSelectionPage].
///
/// Lý do cần thiết:
///
/// - Trước khi reset, state có thể là [MatchmakingNearbyCafesLoaded] với
///   `gameId` của game cũ. Khi [LobbyCafeSelectionPage] rebuild sau khi
///   player back/forward, hàm `_initialLoad()` sẽ check
///   `state.gameId == widget.game.id` và nếu khác sẽ fetch lại — nhưng
///   giữa lúc đó UI sẽ hiển thị data sai trong 1 frame.
/// - Reset về [MatchmakingInitial] ép UI render shimmer loading cho tới
///   khi [loadNearbyCafesForCurrentUser] chính thức emit loaded state mới.
void resetNearbyCafesForGameSwitch() {
  if (isClosed) return;
  // Chỉ reset khi state hiện tại là related nearby state — tránh phá
  // vỡ state quan trọng khác (search results, game detail, ...).
  // Loading state không có class riêng (dùng chung MatchmakingLoading),
  // nhưng emit Initial khi đang Loading cũng an toàn — UI sẽ re-render
  // shimmer (initial state cũng render shimmer).
  if (state is MatchmakingNearbyCafesLoaded || state is MatchmakingLoading) {
    emit(const MatchmakingInitial());
  }
}

  /// Tìm kiếm quán cafe theo tên — `GET /api/cafes/search?name=...`.
  /// Dùng cho unified search page (cùng tab với boardgame search).
  Future<void> searchCafes({
    required String name,
    double? latitude,
    double? longitude,
    double radiusKm = 15.0,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.searchCafes(
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MatchmakingFailure(message: failure.message)),
      (data) => emit(MatchmakingCafeSearchResults(
        query: name,
        cafes: data.cafes,
        emptyResultMessage: data.emptyResultMessage,
        alternativeSuggestions: data.alternativeSuggestions,
      )),
    );
  }

/// Cafe tab — hiển thị quán có board game gần vị trí player.
///
/// Thuật toán (sau refactor `cafe.md`):
/// 1. Gọi trực tiếp `/api/cafes/nearby/me` KHÔNG cần `gameTemplateId`
///    (backend đã bỏ yêu cầu bắt buộc). Đơn giản hoá flow — không cần
///    pre-fetch popular game trước khi load cafe.
/// 2. Nếu trả về 0 quán nhưng có `alternativeSuggestions` không rỗng → thử
///    game được gợi ý có `nearbyCafeCount` cao nhất (thực tế chính là game
///    gần player nhất — đảm bảo user luôn thấy quán thay vì empty state).
/// 3. Nếu user đang nhập `name` thì switch sang `searchCafes` luôn.
///
/// Được bọc trong try/catch ở [loadCafesNearbyForCurrentUser] để đảm bảo
/// luôn emit state cuối cùng (kể cả failure) — tránh kẹt ở Loading.
Future<void> loadCafesNearbyForCurrentUser({
  String? name,
  String? preferredGameId,
  double radiusKm = 15.0,
}) async {
  try {
    await _loadCafesNearbyForCurrentUserImpl(
      name: name,
      preferredGameId: preferredGameId,
      radiusKm: radiusKm,
    );
  } catch (e, stack) {
    // Safety net: bất kỳ exception nào lọt qua cũng phải emit state để
    // UI không bị kẹt ở Loading. Trước đây nếu _resolveWithFallback
    // throw uncaught thì state Loading không bao giờ đổi → skeleton
    // xoay mãi.
    if (isClosed) return;
    emit(MatchmakingFailure(
      message: 'Lỗi không mong đợi khi tải danh sách quán: $e',
    ));
    // ignore: avoid_print
    print('loadCafesNearbyForCurrentUser error: $e\n$stack');
  }
}

Future<void> _loadCafesNearbyForCurrentUserImpl({
  String? name,
  String? preferredGameId,
  double radiusKm = 15.0,
}) async {
  final trimmedName = (name ?? '').trim();
  // Có query → dùng endpoint search.
  if (trimmedName.isNotEmpty) {
    return searchCafes(name: trimmedName, radiusKm: radiusKm);
  }

  emit(const MatchmakingLoading());

  // Backend đã bỏ yêu cầu bắt buộc `gameTemplateId` cho
  // `/api/cafes/nearby/me` — gọi thẳng endpoint, không cần pre-fetch
  // popular game. `preferredGameId` (nếu có) chỉ dùng cho fallback
  // alternativeSuggestions ở dưới.
  final firstResult = await repository.getNearbyCafesForCurrentUser(
    radiusKm: radiusKm,
  );

  if (isClosed) return;

  // Fallback nếu lần 1 trống — vẫn dùng `preferredGameId` (nếu page
  // truyền vào) hoặc `_popularGameId` cache để so sánh.
  final fallbackGameId =
      (preferredGameId != null && preferredGameId.isNotEmpty)
          ? preferredGameId
          : _popularGameId;
  final first = await _resolveWithFallback(
    firstResult: firstResult,
    primaryGameId: fallbackGameId,
    radiusKm: radiusKm,
  );
  if (first != null) {
    emit(first);
    return;
  }

  // Fallback cũng trả về cùng data → emit state từ firstResult nguyên thuỷ.
  firstResult.fold(
    (failure) => emit(MatchmakingFailure(message: failure.message)),
    (data) => emit(MatchmakingCafeSearchResults(
      query: '',
      cafes: data.cafes,
      emptyResultMessage: data.emptyResultMessage,
      alternativeSuggestions: data.alternativeSuggestions,
    )),
  );
}

  /// Cache "game ưu tiên" (rating cao nhất) — dùng cho tab Cafe khi cần
  /// `gameTemplateId` mà không muốn gọi lại API boardgames.
  ///
  /// Được set bởi [searchGames] khi state chuyển sang
  /// `MatchmakingSearchResults`, và đọc bởi
  /// [loadCafesNearbyForCurrentUser]. Cache này sống trong cubit instance
  /// (in-memory) — nếu cubit bị dispose hoặc refresh, giá trị sẽ về `null`.
  String? _popularGameId;

  /// Lấy game ID ưu tiên (rating cao nhất) từ cache cubit. Trả về `null`
  /// nếu chưa có dữ liệu boardgames.
  ///
  /// Cache này được set khi boardgame tab load thành công. Cafe tab dùng nó
  /// để không phải gọi lại API boardgames — tuân thủ constraint "Chạy bên
  /// tabs nào thì apis bên đó".
  String? pickPopularGameIdFromCache() => _popularGameId;

  /// Cập nhật cache popular game ID. Được gọi tự động bởi [searchGames]
  /// mỗi khi có kết quả boardgames hợp lệ.
  void _refreshPopularGameId(List<BoardGameEntity> games) {
    if (games.isEmpty) {
      _popularGameId = null;
      return;
    }
    final sorted = [...games]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    _popularGameId = sorted.first.id;
  }

/// Kết quả trả về từ [getNearbyCafesForCurrentUser] có thể rỗng khi quán
/// gần player không có sẵn game nào trùng `primaryGameId`. Trong trường hợp
/// đó, backend kèm `alternativeSuggestions` — mỗi suggestion có
/// `nearbyCafeCount`. Hàm này fallback sang game có nhiều quán nhất.
///
/// `primaryGameId` có thể `null` (Cafe tab giờ gọi API không kèm gameId) —
/// trong trường hợp đó, fallback vẫn chạy nếu server trả alternative.
///
/// Trả về `null` nếu không cần fallback (firstResult có data hoặc first
/// result success/failure không phải dạng "trống").
Future<MatchmakingCafeSearchResults?> _resolveWithFallback({
  required Either<Failure, NearbyCafesSearchResultEntity> firstResult,
  String? primaryGameId,
  required double radiusKm,
}) async {
  // Lấy data từ firstResult nếu success.
  NearbyCafesSearchResultEntity? firstData;
  firstResult.fold(
    (failure) => null,
    (data) => firstData = data,
  );

  // firstResult đã fail → để caller xử lý MatchmakingFailure.
  if (firstData == null) return null;

  // Có quán rồi hoặc không có alternative → không cần fallback.
  if (firstData!.cafes.isNotEmpty) return null;
  if (firstData!.alternativeSuggestions.isEmpty) return null;

  // Chọn suggestion có nearbyCafeCount cao nhất.
  final best = [...firstData!.alternativeSuggestions]
    ..sort((a, b) => b.nearbyCafeCount.compareTo(a.nearbyCafeCount));
  final bestGame = best.first;
  // Bỏ qua fallback nếu suggestion trùng `primaryGameId` đã thử.
  if (primaryGameId != null &&
      bestGame.gameTemplateId == primaryGameId) {
    return null;
  }
  if (bestGame.nearbyCafeCount <= 0) return null;

  final secondResult = await repository.getNearbyCafesForCurrentUser(
    gameId: bestGame.gameTemplateId,
    radiusKm: radiusKm,
  );
  if (isClosed) return null;

  return secondResult.fold(
    (failure) => null,
    (data) => MatchmakingCafeSearchResults(
      query: '',
      cafes: data.cafes,
      emptyResultMessage: data.emptyResultMessage,
      alternativeSuggestions: data.alternativeSuggestions,
      fallbackGameName: bestGame.gameName,
    ),
  );
}
}
