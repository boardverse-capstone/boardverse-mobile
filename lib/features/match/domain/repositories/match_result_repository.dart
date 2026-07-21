import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/match_consensus_entity.dart';

/// Abstraction ở tầng domain cho module Match (Elo consensus).
///
/// Implementation duy nhất là `MatchResultRepositoryImpl`, được DI bind
/// theo cờ `AppConfig.useMockMatchData` (mock vs real). UI bind qua repo.
/// MVP scope: chỉ cần `getMatchResult` + `submitMatchResult`. Realtime
/// stream để UI refresh khi member khác submit — ở real backend nên verify
/// realtime channel (xem code Phase 2 comment).
abstract class MatchResultRepository {
  Future<Either<Failure, MatchConsensusEntity>> getMatchResult(String lobbyId);

  Future<Either<Failure, MatchSubmissionResultEntity>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  });

  Stream<MatchConsensusEntity> watchMatchResult(String lobbyId);
}
