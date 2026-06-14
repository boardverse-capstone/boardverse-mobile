import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/board_game_entity.dart';
import '../domain/entities/cafe_entity.dart';
import '../domain/repositories/matchmaking_repository.dart';
import 'datasources/mock_matchmaking_datasource.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final MockMatchmakingDatasource _datasource;

  MatchmakingRepositoryImpl({MockMatchmakingDatasource? datasource})
      : _datasource = datasource ?? MockMatchmakingDatasource();

  @override
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final results = _datasource.searchBoardGames(
        query: query,
        category: category,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
      );
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tìm kiếm: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final game = MockMatchmakingDatasource.mockBoardGameDetail;
      return Right(game.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy thông tin game: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      var cafes = MockMatchmakingDatasource.mockCafeListWithGps.map((m) => m.toEntity()).toList();

      if (radiusKm < 15.0) {
        cafes = cafes.where((c) => c.distanceKm <= radiusKm).toList();
      }

      return Right(cafes);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy danh sách quán: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BoardGameEntity>>> getSimilarGames({
    required String gameId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final results = MockMatchmakingDatasource.mockSimilarGamesCarousel;
      return Right(results.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy game tương tự: ${e.toString()}'));
    }
  }
}
