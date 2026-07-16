import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/board_game_detail_entity.dart';
import '../domain/entities/board_game_entity.dart';
import '../domain/entities/cafe_entity.dart';
import '../domain/entities/game_play_configuration_entity.dart';
import '../domain/entities/game_play_navigation_entity.dart';
import '../domain/entities/nearby_cafes_search_result_entity.dart';
import '../domain/entities/seat_availability_entity.dart';
import '../domain/entities/search_filter_entity.dart';
import '../domain/entities/game_category_entity.dart';
import '../domain/repositories/matchmaking_repository.dart';
import 'datasources/base/matchmaking_datasource.dart';

/// Repository implementation sử dụng DataSource Abstraction Pattern
/// Khi backend sẵn sàng, chỉ cần inject MatchmakingRemoteDatasource vào
class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final MatchmakingDatasource datasource;

  MatchmakingRepositoryImpl({required this.datasource});

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
      final results = await datasource.searchGames(filter);
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tìm kiếm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> searchGames(
      SearchFilterEntity filter) async {
    try {
      final results = await datasource.searchGames(filter);
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tìm kiếm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getAllGames() async {
    try {
      final results = await datasource.getAllGames();
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy danh sách game: ${e.toString()}'));
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
      return Left(ServerFailure(
          message: 'Lỗi tìm kiếm phân trang: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BoardGameDetailEntity?>> getBoardGameDetails(
      String id) async {
    try {
      final detail = await datasource.getBoardGameDetails(id);
      return Right(detail?.toEntity());
    } catch (e) {
      return Left(ServerFailure(
          message: 'Lỗi lấy chi tiết game: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id) async {
    try {
      final game = await datasource.getGameById(id);
      return Right(game?.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy thông tin game: ${e.toString()}'));
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
      return Left(ServerFailure(message: 'Lỗi lấy game tương tự: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<GameCategoryEntity>>> getGameCategories() async {
    try {
      final results = await datasource.getGameCategories();
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy danh mục game: ${e.toString()}'));
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
      return Left(ServerFailure(message: 'Lỗi lấy danh sách quán: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesWithGameSearch({
    required String gameId,
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
      return Left(ServerFailure(
          message: 'Lỗi tìm quán gần: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesForCurrentUser({
    required String gameId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await datasource.getNearbyCafesForCurrentUser(
        gameTemplateId: gameId,
        radiusKm: radiusKm,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure(
          message: 'Lỗi tìm quán gần (me): ${e.toString()}'));
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
      return Left(ServerFailure(message: 'Lỗi lấy danh sách quán: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CafeEntity?>> getCafeById(String id) async {
    try {
      final cafe = await datasource.getCafeById(id);
      return Right(cafe?.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy thông tin quán: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getCafeGames(
      String cafeId) async {
    try {
      final results = await datasource.getCafeGames(cafeId);
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy games của quán: ${e.toString()}'));
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
      return Left(ServerFailure(message: 'Lỗi lấy thông tin ghế: ${e.toString()}'));
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
      return Left(ServerFailure(message: 'Lỗi kiểm tra ghế: ${e.toString()}'));
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
      return Left(ServerFailure(
          message: 'Lỗi lấy cấu hình chơi: ${e.toString()}'));
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
      return Left(ServerFailure(
          message: 'Lỗi điều hướng chế độ chơi: ${e.toString()}'));
    }
  }
}
