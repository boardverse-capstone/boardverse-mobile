import 'package:dartz/dartz.dart';

import 'package:boardverse/core/error/exceptions.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/my_elo_history_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/my_registration_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';
import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:boardverse/features/tournament/data/datasources/base/tournament_remote_datasource.dart';

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
    // Lấy totalRounds từ tournament detail (cần cho formattedSwissScore).
    // Nếu lỗi ở detail call thì vẫn fallback trả participants không kèm
    // totalRounds (số Swiss score thuần vẫn hợp lệ).
    int? totalRounds;
    try {
      final detailResult = await _remoteDatasource.getTournamentDetail(id);
      totalRounds = detailResult.toEntity().totalRounds;
    } catch (_) {
      totalRounds = null;
    }

    try {
      final models = await _remoteDatasource.getParticipants(id);
      final entities = models.map((m) {
        final isMe = currentUserId != null && m.userId == currentUserId;
        return m.toEntity(isCurrentUser: isMe, totalRounds: totalRounds);
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
      // totalRounds optional: nếu fetch detail lỗi thì bỏ qua, hiển thị
      // swiss score thuần.
      int? totalRounds;
      try {
        final detail = await _remoteDatasource.getTournamentDetail(
          tournamentId,
        );
        totalRounds = detail.toEntity().totalRounds;
      } catch (_) {
        totalRounds = null;
      }
      final isMe = currentUserId != null && model.userId == currentUserId;
      return Right(
        model.toEntity(isCurrentUser: isMe, totalRounds: totalRounds),
      );
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
    String tournamentId,
    String matchId,
  ) async {
    try {
      final model = await _remoteDatasource.getMatchById(tournamentId, matchId);
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
  Future<Either<Failure, List<MyRegistrationEntry>>> getMyRegistrations({
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
  Future<Either<Failure, MyEloHistoryResponse>> getMyEloHistory() async {
    try {
      final model = await _remoteDatasource.getMyEloHistory();
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ─── T-03: Tournament Waitlist ──────────────────────────────────────────

  @override
  Future<Either<Failure, JoinWaitlistResult>> joinWaitlist(
      String tournamentId) async {
    try {
      final model = await _remoteDatasource.joinWaitlist(tournamentId);
      return Right(
        JoinWaitlistResult(
          waitlistEntryId: model.id ?? model.waitlistEntryId ?? '',
          tournamentId: model.tournamentId,
          tournamentName: model.tournamentName ?? '',
          userId: model.userId,
          username: model.username ?? '',
          position: model.position,
          joinedAt: model.joinedAt,
          status: WaitlistEntryStatusX.fromApi(model.status),
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TournamentWaitlistEntry>>> getWaitlist(
    String tournamentId, {
    int? page,
    int? pageSize,
  }) async {
    try {
      final models = await _remoteDatasource.getWaitlist(
        tournamentId,
        page: page,
        pageSize: pageSize,
      );
      final entities = models
          .map((m) => m.toEntity(fallbackTournamentName: ''))
          .toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, MyWaitlistStatus>> getMyWaitlistStatus(
      String tournamentId) async {
    try {
      final model = await _remoteDatasource.getMyWaitlistStatus(tournamentId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveWaitlist(String tournamentId) async {
    try {
      await _remoteDatasource.leaveWaitlist(tournamentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, WaitlistActionResult>> confirmWaitlistOffer(
      String tournamentId) async {
    try {
      final model =
          await _remoteDatasource.confirmWaitlistOffer(tournamentId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, WaitlistActionResult>> declineWaitlistOffer(
      String tournamentId) async {
    try {
      final model =
          await _remoteDatasource.declineWaitlistOffer(tournamentId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // ─── T-04: Tournament Spectator ────────────────────────────────────────

  @override
  Future<Either<Failure, List<TournamentSpectatorEntry>>> getSpectators(
      String tournamentId) async {
    try {
      final models = await _remoteDatasource.getSpectators(tournamentId);
      final entities = models
          .map((m) => m.toEntity(fallbackTournamentTitle: ''))
          .toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, MySpectatorStatus>> getMySpectatorStatus(
      String tournamentId) async {
    try {
      final model = await _remoteDatasource.getMySpectatorStatus(tournamentId);
      final entry = model.model?.toEntity(fallbackTournamentTitle: '');
      return Right(
        MySpectatorStatus(
          isSpectating: model.isSpectating,
          entry: entry,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, TournamentSpectatorEntry>> startSpectating(
      String tournamentId) async {
    try {
      final model = await _remoteDatasource.startSpectating(tournamentId);
      return Right(model.toEntity(fallbackTournamentTitle: ''));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> stopSpectating(String tournamentId) async {
    try {
      await _remoteDatasource.stopSpectating(tournamentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  // Leaderboard đã tách ra feature riêng — xem `lib/features/leaderboard/`.
}
