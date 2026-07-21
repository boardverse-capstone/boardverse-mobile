import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../domain/entities/match_consensus_entity.dart';
import '../domain/repositories/match_result_repository.dart';
import 'datasources/base/match_result_remote_datasource.dart';

/// Triển khai [MatchResultRepository] dùng chung cho cả 2 mode (mock / remote).
///
/// Mode được quyết định bởi DI:
/// - `AppConfig.useMockMatchData = true`  → MockMatchResultRemoteDatasource
/// - `AppConfig.useMockMatchData = false` → RealMatchResultRemoteDatasource
///
/// Repository không tự switch — chỉ delegate xuống datasource đã inject.
class MatchResultRepositoryImpl implements MatchResultRepository {
  MatchResultRepositoryImpl({required MatchResultRemoteDatasource remote})
      : _remote = remote;

  final MatchResultRemoteDatasource _remote;

  @override
  Future<Either<Failure, MatchConsensusEntity>> getMatchResult(
    String lobbyId,
  ) =>
      _remote.getMatchResult(lobbyId);

  @override
  Future<Either<Failure, MatchSubmissionResultEntity>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) =>
      _remote.submitMatchResult(lobbyId: lobbyId, outcome: outcome);

  @override
  Stream<MatchConsensusEntity> watchMatchResult(String lobbyId) =>
      _remote.watchMatchResult(lobbyId);
}
