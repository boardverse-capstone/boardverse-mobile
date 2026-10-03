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

/// Keywords trong error message cho biết lỗi liên quan đến việc
/// player chưa cập nhật vị trí của mình.
///
/// Backend `/api/cafes/nearby/me` trả 400 khi profile chưa có
/// `LastKnownLocation` — message thường chứa "location" hoặc "vị trí".
const _locationKeywords = ['location', 'vị trí', 'lastknownlocation'];

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
      (failure) => emit(_createFailure(failure)),
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
      (failure) => emit(_createFailure(failure)),
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

    // Luồng mới: dùng `GET /api/v1/board-games/{id}/active-cafes` —
    // chiều ngược của `/api/cafes/{cafeId}/active-games`.
    // Player hỏi "chơi game này ở đâu?" thay vì "quán nào gần tôi?".
    // Nếu truyền lat/lng → backend sort theo khoảng cách, ngược lại
    // sort theo tên A→Z.
    final activeCafesResult = await repository.getBoardGameActiveCafes(
      gameId,
      latitude: isGpsEnabled ? latitude : null,
      longitude: isGpsEnabled ? longitude : null,
    );

    if (isClosed) return;

    await gameResult.fold(
      (failure) async => emit(_createFailure(failure)),
      (gameDetail) async {
        if (gameDetail == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        await activeCafesResult.fold(
          (failure) async => emit(_createFailure(failure)),
          (searchResult) async {
            final activeCafes = searchResult.cafes;
            final emptyMsg = searchResult.emptyResultMessage;
            // **Source of truth ưu tiên cho `isSaved`** (build 2026-10-03+):
            // - 1. `gameDetail.isSaved` — endpoint `/board-games/{id}` luôn
            //   fetch mỗi lần mở trang chi tiết, không cache → đảm bảo
            //   freshness ngay cả khi user vừa save/unsave ở tab khác và
            //   quay lại trang này.
            // - 2. `searchResult.isSaved` (active-cafes) — fallback. Cached
            //   30s qua `CacheableRepository` nên có thể stale. Chỉ dùng
            //   khi detail thiếu field (backward compat với BE cũ).
            // - Default `false` khi cả 2 đều thiếu (user chưa login).
            final isSaved = gameDetail.isSaved || searchResult.isSaved;

            if (!isGpsEnabled) {
              emit(MatchmakingGpsDisabled(
                selectedGame: gameDetail.toBoardGameEntity(),
              ));
              return;
            }

            // Luồng mới: `nearbyCafes` (gần theo GPS) được thay thế bằng
            // `activeCafes` (quán có board game này trong kho, có thể ở
            // bất kỳ đâu). Vẫn giữ field `nearbyCafes` (rỗng) để không
            // vỡ các consumer khác (vd: [selectCafe], [canBookNow]).
            //
            // `isOutOfRadius` semantics mới: chỉ true khi `activeCafes` rỗng
            // → UI vẫn hiển thị empty state đúng kiểu.
            final isOutOfRadius = activeCafes.isEmpty;

            emit(
              MatchmakingGameDetail(
                game: gameDetail,
                nearbyCafes: const [],
                activeCafes: activeCafes,
                isGpsEnabled: isGpsEnabled,
                isOutOfRadius: isOutOfRadius,
                emptyResultMessage: emptyMsg,
                alternativeSuggestions: const [],
                isSaved: isSaved,
              ),
            );
          },
        );
      },
    );
  }

  /// Optimistic update trạng thái save/unsave cho board game hiện tại.
  ///
  /// Được gọi từ UI (icon bookmark trên header) sau khi `SavedGamesCubit`
  /// hoàn tất toggle API. Mục đích: header icon (ở `BoardGameDetailPage`)
  /// phản ánh đúng trạng thái ngay lập tức mà không cần re-fetch toàn bộ
  /// detail (gồm `getBoardGameDetails` + `getBoardGameActiveCafes`).
  ///
  /// No-op nếu state hiện tại không phải [MatchmakingGameDetail] (vd:
  /// user đã back ra khỏi page trước khi toggle hoàn tất).
  void setIsSaved({required String gameId, required bool isSaved}) {
    if (isClosed) return;
    final current = state;
    if (current is MatchmakingGameDetail && current.game.id == gameId) {
      emit(current.copyWith(isSaved: isSaved));
    }
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
      (failure) async => emit(_createFailure(failure)),
      (game) async {
        if (game == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        await cafesResult.fold(
          (failure) async => emit(_createFailure(failure)),
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

  /// Fallback filter dựa trên `totalGameBoxCount` (Available + InUse) —
  /// server `/api/cafes/nearby?gameTemplateId=...` đã filter theo inventory
  /// rồi, nhưng defensive check vẫn giữ để bỏ qua response rỗng / dữ liệu
  /// cũ. Trước đây dùng `availableGameCount > 0` đã loại bỏ nhầm quán có
  /// hộp đang `InUse` → gây bug "không có quán" trên UI.
  List<CafeEntity> _filterCafesWithGame(
      List<CafeEntity> cafes, String gameId) {
    return cafes.where((cafe) => cafe.totalGameBoxCount > 0).toList();
  }

  // ─── Cafe Active Games (for LobbyConfig game picker) ───────────────

  /// Load danh sách board game đang hoạt động tại một quán cafe cụ thể.
  /// Dùng khi player ấn "Đổi game" trên [LobbyConfigPage] để hiển thị
  /// chỉ game có sẵn tại quán đã chọn — thay vì toàn bộ game hệ thống.
  ///
  /// Gọi `GET /api/cafes/{cafeId}/active-games` — endpoint public, không cần
  /// token. Kết quả được emit qua state [MatchmakingCafeGamesLoaded] để
  /// [LobbyGamePickerSheet] hiển thị.
  ///
  /// Nếu `groupSize` được truyền, backend chỉ trả game có
  /// `minPlayers <= groupSize`. Đặt `availableOnly=true` nếu muốn chỉ
  /// trả game còn hộp trống (có thể đặt ngay).
  ///
  /// Lỗi (404 cafe không tồn tại, 500 server error) → emit
  /// [MatchmakingFailure] để UI hiển thị thông báo phù hợp.
  Future<void> loadCafeActiveGames(
    String cafeId, {
    int? groupSize,
    bool availableOnly = false,
  }) async {
    emit(const MatchmakingLoading());

    final result = await repository.getCafeActiveGames(
      cafeId,
      groupSize: groupSize,
      availableOnly: availableOnly,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(_createFailure(failure)),
      (games) => emit(MatchmakingCafeGamesLoaded(
        cafeId: cafeId,
        games: games,
      )),
    );
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
      (failure) => emit(_createFailure(failure)),
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
      (failure) async => emit(_createFailure(failure)),
      (detail) async {
        if (detail == null) {
          emit(const MatchmakingFailure(message: 'Không tìm thấy game'));
          return;
        }

        if (isClosed) return;
        await cafesEither.fold(
          (failure) async =>
              emit(_createFailure(failure)),
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
      (failure) => emit(_createFailure(failure)),
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
      (failure) => emit(_createFailure(failure)),
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
    (failure) => emit(_createFailure(failure)),
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
    (failure) => emit(_createFailure(failure)),
    (data) => emit(MatchmakingNearbyCafesLoaded(
      gameId: gameId ?? '',
      cafes: data.cafes,
      emptyResultMessage: data.emptyResultMessage,
      alternativeSuggestions: data.alternativeSuggestions,
    )),
  );
}

/// Lấy tất cả quán ACTIVE trên toàn hệ thống và filter client-side
  /// theo `city` — map vào `GET /api/cafes?pageSize=100`.
  ///
  /// **Lý do tồn tại:**
  /// - `/api/cafes/nearby/me` chỉ trả quán trong bán kính 15km (mặc định).
  ///   Nếu player ở tỉnh xa, không có quán nào trong bán kính → màn hình
  ///   `LobbyCafeSelectionPage` rỗng → không đặt được chỗ.
  /// - `/api/cafes/nearby` có thể truyền `radiusKm` lên 50, nhưng vẫn là
  ///   GPS-based — player muốn đặt ở TP khác (vd: đi công tác) vẫn khó.
  /// - Backend **không hỗ trợ filter `city`** (Swagger không có field city/
  ///   district/province trong CafeDto, chỉ có `address` free-form).
  ///
  /// **Giải pháp:** lấy full list ACTIVE rồi filter
  /// `cafe.address.contains(cityNormalized)` phía client.
  ///
  /// **Lưu ý quan trọng về `city`:**
  /// - Phải là `city` đã được resolve bởi backend (sau reverse-geocode),
  ///   không phải tự player nhập. Format backend trả về đã chuẩn hoá
  ///   (xem `PlayerLocationEntity.city`).
  /// - `city` có thể là `null` nếu backend chưa reverse-geocode được —
  ///   caller phải fallback về GPS flow và báo cho player (xem
  ///   `LobbyCafeSelectionPage._onCityFilterPressed`).
  ///
  /// Phát state [MatchmakingCafesByCityLoaded] với 2 trường hợp:
  /// - `cafes.isNotEmpty` → render list bình thường.
  /// - `cafes.isEmpty` → render empty state riêng (message khác với
  ///   nearby để player không bị nhầm "không có quán trong bán kính").
  Future<void> loadCafesByCity({
    required String city,
    required String cityDisplayName,
  }) async {
    final cityNormalized = city.trim().toLowerCase();
    if (cityNormalized.isEmpty) {
      // Defensive: caller phải check trước, nhưng nếu city rỗng → fail
      // sang empty state để UI không bị stuck ở Loading.
      emit(MatchmakingCafesByCityLoaded(
        city: cityNormalized,
        cityDisplayName: cityDisplayName,
        cafes: const [],
        totalActiveCafes: 0,
      ));
      return;
    }

    emit(const MatchmakingLoading());

    final result = await repository.getAllActiveCafes(pageSize: 100);

    if (isClosed) return;
    result.fold(
      (failure) => emit(_createFailure(failure)),
      (data) {
        final filtered = _filterCafesByCityToken(
          allCafes: data.cafes,
          cityToken: cityNormalized,
        );
        emit(MatchmakingCafesByCityLoaded(
          city: cityNormalized,
          cityDisplayName: cityDisplayName,
          cafes: filtered,
          totalActiveCafes: data.cafes.length,
        ));
      },
    );
  }

  /// Filter quán có `address` chứa token thành phố (case-insensitive).
  ///
  /// Hỗ trợ alias phổ biến ở Việt Nam (vd: "Hồ Chí Minh" ↔ "TP.HCM",
  /// "Ho Chi Minh City" ↔ "Sài Gòn") để tăng độ chính xác khi các quán
  /// nhập địa chỉ không đồng nhất. Nếu token là 1 thành phố "chuẩn"
  /// trong map alias → match theo cả alias.
  ///
  /// **Lưu ý quan trọng:** danh sách variant phải *symmetric* — bất kỳ
  /// biến thể nào backend có thể trả về (vd: `"TP.HCM"`,
  /// `"Ho Chi Minh City"`, `"Thành phố Hồ Chí Minh"`) đều phải có mặt
  /// trong list để reverse-lookup bên dưới phân giải được về full set.
  /// Thiếu 1 variant → miss các quán dùng variant đó trong `address`.
  ///
  /// Sort theo `name` A→Z (giống backend `GET /api/cafes`).
  List<CafeEntity> _filterCafesByCityToken({
    required List<CafeEntity> allCafes,
    required String cityToken,
  }) {
    // Map canonical → variants hay gặp trong `address` (backend không
    // chuẩn hoá format address nên mỗi quán nhập 1 kiểu — "Ho Chi Minh
    // City" (English), "Hồ Chí Minh" (VN có dấu), "TP.HCM" (viết tắt),
    // "Thành phố Hồ Chí Minh" (VN có prefix), "Sài Gòn" (tên cũ), ...
    const aliases = <String, List<String>>{
      'hồ chí minh': [
        'hồ chí minh', // VN có dấu
        'ho chi minh', // EN (substring match "ho chi minh city")
        'ho chi minh city', // EN đầy đủ
        'thành phố hồ chí minh', // VN có prefix "Thành phố"
        'thành phố ho chi minh',
        'tp. hồ chí minh',
        'tp hồ chí minh',
        'tp. ho chi minh',
        'tp ho chi minh',
        'tp.hcm',
        'tp hcm',
        'tp.hồ chí minh',
        'tp hồ chí minh',
        'hcmc',
        'sài gòn',
        'saigon',
      ],
      'hà nội': [
        'hà nội',
        'ha noi',
        'hn',
        'thành phố hà nội',
      ],
      'đà nẵng': ['đà nẵng', 'da nang'],
      'hải phòng': ['hải phòng', 'hai phong'],
      'cần thơ': ['cần thơ', 'can tho'],
      'bình dương': [
        'bình dương',
        'binh duong',
        'thủ dầu một',
        'thu dau mot',
      ],
    };

    // Reverse-lookup: bất kỳ variant nào cũng map về full set của
    // canonical (canonical + toàn bộ variants). Trước đây chỉ lookup
    // thẳng `aliases[cityToken]` — chỉ trúng khi token khớp ĐÚNG
    // canonical key. Khi backend trả `'TP.HCM'` / `'Ho Chi Minh City'` /
    // `'Thành phố Hồ Chí Minh'` thì miss → player chỉ thấy 1 phần nhỏ
    // quán, gây hiểu nhầm "BoardVerse chỉ có vài quán ở HCM".
    final aliasIndex = <String, Set<String>>{};
    for (final entry in aliases.entries) {
      final fullSet = <String>{entry.key, ...entry.value};
      aliasIndex[entry.key] = fullSet;
      for (final variant in entry.value) {
        aliasIndex[variant] = fullSet;
      }
    }

    // Fallback khi cityToken không khớp canonical nào: dùng chính token
    // làm matcher duy nhất (vẫn match được quán có địa chỉ chứa đúng
    // cụm đó, vd player ở Hạ Long → match "hạ long" trong address).
    final matchers = aliasIndex[cityToken] ?? <String>{cityToken};

    final filtered = allCafes.where((cafe) {
      final address = cafe.address.toLowerCase();
      return matchers.any((m) => address.contains(m));
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
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
      (failure) => emit(_createFailure(failure)),
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
    (failure) => emit(_createFailure(failure)),
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

  /// Tạo [MatchmakingFailure] với user-friendly message và flag
  /// `requiresLocationUpdate = true` nếu lỗi liên quan đến việc player
  /// chưa cập nhật vị trí.
  ///
  /// Logic:
  /// - Nếu là `BadRequestFailure` (400) và message chứa keyword location
  ///   → đây là lỗi "chưa có vị trí" → emit với `requiresLocationUpdate=true`
  /// - Các lỗi khác → message thân thiện với user
  MatchmakingFailure _createFailure(Failure failure) {
    final message = failure.message;
    final requiresLocation = _isLocationRelatedError(failure);

    // User-friendly message cho các loại lỗi phổ biến
    String friendlyMessage;
    if (requiresLocation) {
      friendlyMessage =
          'Bạn chưa cập nhật vị trí hiện tại. Vui lòng cập nhật vị trí để '
              'tìm quán cafe gần bạn.';
    } else if (failure is NetworkFailure) {
      friendlyMessage = 'Không có kết nối mạng. Vui lòng kiểm tra kết nối '
          'Internet và thử lại.';
    } else if (failure is ServerFailure &&
        failure.statusCode != null &&
        failure.statusCode! >= 500) {
      friendlyMessage =
          'Máy chủ đang bận. Vui lòng thử lại sau vài phút.';
    } else {
      // Fallback: sanitize technical messages
      friendlyMessage = _sanitizeErrorMessage(message);
    }

    return MatchmakingFailure(
      message: friendlyMessage,
      requiresLocationUpdate: requiresLocation,
      statusCode: failure is ServerFailure ? failure.statusCode : null,
    );
  }

  /// Kiểm tra xem lỗi có phải là do player chưa cập nhật vị trí không.
  ///
  /// Điều kiện:
  /// 1. `BadRequestFailure` (statusCode 400), VÀ
  /// 2. Message chứa keyword liên quan location
  bool _isLocationRelatedError(Failure failure) {
    if (failure is! BadRequestFailure) return false;
    final msg = failure.message.toLowerCase();
    return _locationKeywords.any((k) => msg.contains(k.toLowerCase()));
  }

  /// Sanitize technical error message thành message thân thiện với user.
  ///
  /// Loại bỏ:
  /// - Stack traces và technical details
  /// - Exception class names như "ServerException"
  /// - Raw HTTP status codes trong ngoặc vuông
  String _sanitizeErrorMessage(String message) {
    // Loại bỏ phần trong ngoặc vuông (VD: [400], [null])
    var sanitized = message.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();

    // Loại bỏ class names như "ServerException(message: ...)"
    if (sanitized.contains('Exception')) {
      sanitized = 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.';
    }

    // Giới hạn độ dài message
    if (sanitized.length > 150) {
      sanitized = '${sanitized.substring(0, 147)}...';
    }

    return sanitized.isEmpty
        ? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.'
        : sanitized;
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
