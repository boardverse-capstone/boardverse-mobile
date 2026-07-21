import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/match_consensus_entity.dart';

/// Abstraction cho tầng Data của module Match (Elo consensus).
///
/// Hai implementation:
/// - `MockMatchResultRemoteDatasource` (chạy local, consensus mô phỏng).
/// - `RealMatchResultRemoteDatasource` (gọi `/api/v1/matches/*` qua Dio).
///
/// Switch theo `AppConfig.useMockMatchData` ở tầng DI.
abstract class MatchResultRemoteDatasource {
  /// GET /api/v1/matches/results/lobbies/{lobbyId} — xem consensus hiện tại.
  Future<Either<Failure, MatchConsensusEntity>> getMatchResult(String lobbyId);

  /// POST /api/v1/matches/results — gửi / cập nhật kết quả của chính user.
  /// Trả về snapshot consensus + (nếu Finalized) `matchHistoryId` + `eloUpdates`.
  Future<Either<Failure, MatchSubmissionResultEntity>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  });

  /// Tuỳ chọn: poll consensus mỗi vài giây để nhận update từ member khác.
  /// Ở real backend, spec hiện chưa rõ có push realtime qua /hubs/lobby
  /// hay qua `/hubs/match` riêng — Phase sau sẽ xác nhận và cập nhật.
  /// Hiện giữ `Stream` để UI có thể refresh.
  Stream<MatchConsensusEntity> watchMatchResult(String lobbyId);
}
