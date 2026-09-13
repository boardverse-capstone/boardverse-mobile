import 'package:dartz/dartz.dart';

import '../../../core/cache/cacheable_repository.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../domain/entities/board_game_detail_entity.dart';
import '../domain/entities/board_game_entity.dart';
import '../domain/entities/cafe_detail_entity.dart';
import '../domain/entities/cafe_entity.dart';
import '../domain/entities/game_play_configuration_entity.dart';
import '../domain/entities/game_play_navigation_entity.dart';
import '../domain/entities/nearby_cafes_search_result_entity.dart';
import '../domain/entities/seat_availability_entity.dart';
import '../domain/entities/search_filter_entity.dart';
import '../domain/entities/game_category_entity.dart';
import '../domain/repositories/matchmaking_repository.dart';
import 'datasources/base/matchmaking_datasource.dart';
import 'models/board_game_model.dart';
import 'models/nearby_cafes_search_result_model.dart';

/// Repository implementation sử dụng DataSource Abstraction Pattern
/// Khi backend sẵn sàng, chỉ cần inject MatchmakingRemoteDatasource vào
///
/// Extends [CacheableRepository] để dedupe các GET endpoint được gọi từ
/// nhiều màn hình khác nhau (vd `searchBoardGames` từ SearchPage +
/// LobbyHubPage, `getNearbyCafesForCurrentUser` từ BoardGameDetailPage +
/// LobbyCafeSelectionPage + SearchPage). TTL mặc định 30 giây.
class MatchmakingRepositoryImpl extends CacheableRepository
    implements MatchmakingRepository {
  final MatchmakingDatasource datasource;

  MatchmakingRepositoryImpl({required this.datasource})
      : super(defaultTtl: const Duration(seconds: 30));

  // ─── Board Games ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    try {
      final filter = SearchFilterEntity(
        query: query,
        category: category,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
      );
      // Cache key theo từng filter signature để dedupe các lần gọi cùng
      // tham số trong vòng 30s (vd SearchPage và LobbyHubPage mở cùng lúc
      // khi user switch tab Discovery).
      final models = await cache<List<BoardGameModel>>(
        'search-board-games:${filter.cacheKey}',
        () => datasource.searchGames(filter),
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm kiếm'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> searchGames(
      SearchFilterEntity filter) async {
    try {
      final models = await cache<List<BoardGameModel>>(
        'search-games:${filter.cacheKey}',
        () => datasource.searchGames(filter),
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm kiếm'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getAllGames() async {
    try {
      final models = await cache<List<BoardGameModel>>(
        'all-games',
        () => datasource.getAllGames(),
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy danh sách game'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGamesPaged({
    String? query,
    List<String>? categoryIds,
    int? playerCount,
    List<DurationRange>? durationRanges,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final results = await datasource.getBoardGamesPaged(
        search: query,
        categoryIds: categoryIds,
        playerCount: playerCount,
        durationRanges: durationRanges,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm kiếm phân trang'));
    }
  }

  @override
  Future<Either<Failure, BoardGameDetailEntity?>> getBoardGameDetails(
      String id) async {
    try {
      final detail = await datasource.getBoardGameDetails(id);
      return Right(detail?.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy chi tiết game'));
    }
  }

  @override
  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id) async {
    try {
      final game = await datasource.getGameById(id);
      return Right(game?.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy thông tin game'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getSimilarGames({
    required String gameId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final results = await datasource.getSimilarGames(gameId);
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy game tương tự'));
    }
  }

  @override
  Future<Either<Failure, List<GameCategoryEntity>>> getGameCategories() async {
    try {
      final results = await datasource.getGameCategories();
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy danh mục game'));
    }
  }

  // ─── Cafes ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    try {
      final results = await datasource.getNearbyCafesWithGame(
        gameId: gameId,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy danh sách quán'));
    }
  }

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesWithGameSearch({
    String? gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await datasource.getNearbyCafesSearch(
        gameTemplateId: gameId,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm quán gần'));
    }
  }

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesForCurrentUser({
    String? gameId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      // Cache key: chỉ theo radius (gameId optional — null khi Cafe tab
      // gọi thẳng, các params khác default ổn định).
      final key =
          'cafes-nearby-me:${gameId ?? '_'}:$radiusKm:$pageNumber:$pageSize';
      final result = await cache<NearbyCafesSearchResultModel>(
        key,
        () => datasource.getNearbyCafesForCurrentUser(
          gameTemplateId: gameId,
          radiusKm: radiusKm,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm quán gần'));
    }
  }

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>> searchCafes({
    required String name,
    double? latitude,
    double? longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      // Search-by-name cache key chỉ theo query name (lat/lng optional).
      final key = 'cafes-search:${name.toLowerCase().trim()}';
      final result = await cache<NearbyCafesSearchResultModel>(
        key,
        () => datasource.searchCafes(
          name: name,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi tìm kiếm quán'));
    }
  }

  @override
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    try {
      final results = await datasource.getNearbyCafes(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy danh sách quán'));
    }
  }

  @override
  Future<Either<Failure, CafeDetailEntity?>> getCafeById(String id) async {
    try {
      final cafe = await datasource.getCafeById(id);
      return Right(cafe?.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy thông tin quán'));
    }
  }

  @override
  Future<Either<Failure, CafeDetailEntity?>> getCafeDetail(String id) async {
    try {
      final cafe = await datasource.getCafeById(id);
      return Right(cafe?.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy chi tiết quán'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getCafeGames(
      String cafeId) async {
    try {
      final results = await datasource.getCafeGames(cafeId);
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy games của quán'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getCafeActiveGames(
    String cafeId, {
    String? categoryId,
    int? groupSize,
    bool availableOnly = false,
    String? searchTerm,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    try {
      // Cache key theo cafe + filter params để dedupe khi gọi lại cùng quán.
      final cacheKey =
          'cafe-active-games:$cafeId:${categoryId ?? '_'}:${groupSize ?? '_'}:'
          '$availableOnly:${searchTerm ?? '_'}:${sortBy ?? '_'}:$pageSize';
      final models = await cache<List>(
        cacheKey,
        () => datasource.getCafeActiveGames(
          cafeId,
          categoryId: categoryId,
          groupSize: groupSize,
          availableOnly: availableOnly,
          searchTerm: searchTerm,
          sortBy: sortBy,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      );
      // `cache` returns raw List; cast back to the datasource return type.
      // ignore: avoid_dynamic_calls
      final cafeModels = models.cast<dynamic>().map((m) => m as dynamic).toList();
      // ignore: avoid_dynamic_calls
      return Right(cafeModels.map((m) => m.toEntity() as BoardGameEntity).toList());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy games của quán'));
    }
  }

  // ─── Seat Availability ─────────────────────────────────────────────

  @override
  Future<Either<Failure, SeatAvailabilityEntity>> getSeatAvailability({
    required String cafeId,
    required DateTime timeSlot,
  }) async {
    try {
      final result = await datasource.getSeatAvailability(
        cafeId: cafeId,
        timeSlot: timeSlot,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy thông tin ghế'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkSeatsAvailable({
    required String cafeId,
    required int requiredSeats,
    required DateTime timeSlot,
  }) async {
    try {
      final result = await datasource.checkSeatsAvailable(
        cafeId: cafeId,
        requiredSeats: requiredSeats,
        timeSlot: timeSlot,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi kiểm tra ghế'));
    }
  }

  // ─── Play Configuration & Navigation (API mới) ──────────────────────

  @override
  Future<Either<Failure, GamePlayConfigurationEntity>>
      getGamePlayConfiguration(String gameId) async {
    try {
      final result = await datasource.getGamePlayConfiguration(gameId);
      if (result == null) {
        return const Left(
            ServerFailure(message: 'Không tìm thấy cấu hình chơi'));
      }
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi lấy cấu hình chơi'));
    }
  }

  @override
  Future<Either<Failure, GamePlayNavigationEntity>> resolvePlayNavigation({
    required String gameId,
    required PlayMode mode,
  }) async {
    try {
      final result = await datasource.resolvePlayNavigation(
        gameId: gameId,
        mode: mode,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e, 'Lỗi điều hướng chế độ chơi'));
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Chuyển đổi exception từ datasource sang Failure với statusCode đúng.
  ///
  /// Đảm bảo `BadRequestFailure` được trả về khi backend trả 400,
  /// giúp `MatchmakingCubit._isLocationRelatedError()` nhận biết được
  /// lỗi "chưa cập nhật vị trí" để hiển thị UI thân thiện.
  Failure _mapExceptionToFailure(Object error, String fallbackContext) {
    if (error is ServerException) {
      // Trích xuất statusCode từ ServerException.message dạng "[400] message"
      final msg = error.message;
      int? statusCode;

      // Parse "[statusCode] message" pattern
      final match = RegExp(r'\[(\d+)\]').firstMatch(msg);
      if (match != null) {
        statusCode = int.tryParse(match.group(1)!);
      }

      // Trích xuất message thực từ backend (sau "[statusCode] ")
      String backendMessage = msg;
      if (match != null) {
        backendMessage = msg.substring(match.end).trim();
        if (backendMessage.isEmpty) {
          backendMessage = msg;
        }
      }

      // Trả về Failure type đúng theo statusCode
      switch (statusCode) {
        case 400:
          return BadRequestFailure(message: backendMessage);
        case 401:
          return UnauthorizedFailure(message: backendMessage);
        case 403:
          return ForbiddenFailure(message: backendMessage);
        case 404:
          return NotFoundFailure(message: backendMessage);
        case 409:
          return ConflictFailure(message: backendMessage);
        case 429:
          return RateLimitFailure(message: backendMessage);
        default:
          return ServerFailure(
            message: '$fallbackContext: $backendMessage',
            statusCode: statusCode,
          );
      }
    } else if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    } else if (error is CacheException) {
      return CacheFailure(message: error.message);
    } else {
      // Fallback cho exception không xác định
      return ServerFailure(message: '$fallbackContext: ${error.toString()}');
    }
  }
}
