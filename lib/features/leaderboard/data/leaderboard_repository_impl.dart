import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../domain/entities/leaderboard_kind.dart';
import '../domain/entities/leaderboard_result_entity.dart';
import '../domain/repositories/leaderboard_repository.dart';
import 'datasources/leaderboard_remote_datasource.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDatasource remote;

  LeaderboardRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, LeaderboardResultEntity>> fetchLeaderboard({
    required LeaderboardKind kind,
    int top = 50,
    int offset = 0,
  }) async {
    try {
      final response = await remote.fetch(
        kind: kind,
        top: top,
        offset: offset,
      );
      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
