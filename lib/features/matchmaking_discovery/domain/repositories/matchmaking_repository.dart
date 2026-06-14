import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/board_game_entity.dart';
import '../entities/cafe_entity.dart';

abstract class MatchmakingRepository {
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  });

  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id);

  Future<Either<Failure, List<CafeEntity>>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  Future<Either<Failure, List<BoardGameEntity>>> getSimilarGames({
    required String gameId,
    required double latitude,
    required double longitude,
  });
}
