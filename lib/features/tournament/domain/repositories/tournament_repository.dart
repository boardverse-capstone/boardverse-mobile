import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/tournament_entity.dart';
import '../entities/tournament_participant_entity.dart';
import '../entities/tournament_match_entity.dart';
import '../entities/elo_history_entity.dart';
import '../entities/leaderboard_entity.dart';

/// Abstract repository interface for tournament operations.
abstract class TournamentRepository {
  /// Lấy danh sách giải đang mở đăng ký.
  Future<Either<Failure, List<TournamentEntity>>> getOpenTournaments({
    String? gameTemplateId,
  });

  /// Lấy danh sách giải sắp diễn ra (chưa mở đăng ký).
  Future<Either<Failure, List<TournamentEntity>>> getUpcomingTournaments({
    String? gameTemplateId,
  });

  /// Chi tiết giải đấu.
  Future<Either<Failure, TournamentEntity>> getTournamentDetail(String id);

  /// Danh sách participants.
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(
    String id, {
    String? currentUserId,
  });

  /// Chi tiết 1 participant trong giải.
  Future<Either<Failure, TournamentParticipantEntity>> getParticipant(
    String tournamentId,
    String participantId, {
    String? currentUserId,
  });

  /// Danh sách tất cả matches.
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(String id);

  /// Matches theo round.
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatchesByRound(
    String id,
    int round,
  );

  /// Chi tiết 1 match.
  Future<Either<Failure, TournamentMatchEntity>> getMatchById(String matchId);

  /// Đăng ký tham gia giải.
  Future<Either<Failure, void>> register(String id);

  /// Rút lui khỏi giải.
  Future<Either<Failure, void>> unregister(String id);

  /// Giải của tôi (đã đăng ký).
  Future<Either<Failure, List<TournamentEntity>>> getMyRegistrations({
    String? status,
  });

  /// Lịch sử Elo của tôi.
  Future<Either<Failure, List<EloHistoryEntity>>> getMyEloHistory();

  /// Bảng xếp hạng.
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard({
    int topCount = 100,
  });
}
