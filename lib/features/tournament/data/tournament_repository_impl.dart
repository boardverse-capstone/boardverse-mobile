import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:boardverse_mobile/features/tournament/data/datasources/base/tournament_remote_datasource.dart';

/// Implementation of TournamentRepository.
class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDatasource _remoteDatasource;

  TournamentRepositoryImpl({required this._remoteDatasource});

  @override
  Future<Either<Failure, List<TournamentEntity>>> getOpenTournaments({
    String? gameTemplateId,
  }) async {
    try {
      final models = await _remoteDatasource.getOpenTournaments(
        gameTemplateId: gameTemplateId,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getUpcomingTournaments({
    String? gameTemplateId,
  }) async {
    try {
      final models = await _remoteDatasource.getUpcomingTournaments(
        gameTemplateId: gameTemplateId,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentDetail(
    String id,
  ) async {
    try {
      final model = await _remoteDatasource.getTournamentDetail(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(
    String id, {
    String? currentUserId,
  }) async {
    try {
      final models = await _remoteDatasource.getParticipants(id);
      final entities = models.map((m) {
        final isMe =
            currentUserId != null && m.oderId == currentUserId;
        return m.toEntity(isCurrentUser: isMe);
      }).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, TournamentParticipantEntity>> getParticipant(
    String tournamentId,
    String participantId, {
    String? currentUserId,
  }) async {
    try {
      final model = await _remoteDatasource.getParticipant(
        tournamentId,
        participantId,
      );
      final isMe = currentUserId != null && model.oderId == currentUserId;
      return Right(model.toEntity(isCurrentUser: isMe));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(
    String id,
  ) async {
    try {
      final models = await _remoteDatasource.getMatches(id);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatchesByRound(
    String id,
    int round,
  ) async {
    try {
      final models = await _remoteDatasource.getMatchesByRound(id, round);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, TournamentMatchEntity>> getMatchById(
    String matchId,
  ) async {
    try {
      final model = await _remoteDatasource.getMatchById(matchId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> register(String id) async {
    try {
      await _remoteDatasource.register(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unregister(String id) async {
    try {
      await _remoteDatasource.unregister(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getMyRegistrations({
    String? status,
  }) async {
    try {
      final models = await _remoteDatasource.getMyRegistrations(status: status);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EloHistoryEntity>>> getMyEloHistory() async {
    try {
      final models = await _remoteDatasource.getMyEloHistory();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard({
    int topCount = 100,
  }) async {
    try {
      final models = await _remoteDatasource.getLeaderboard(topCount: topCount);
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }
}
