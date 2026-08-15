import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaderboard_kind.dart';
import '../entities/leaderboard_result_entity.dart';

/// Abstract repository cho leaderboard (BR §K-06).
abstract class LeaderboardRepository {
  /// Lấy top N entries theo [kind].
  ///
  /// - [top]: 1-100, default 50.
  /// - [offset]: ≥ 0, default 0.
  /// - `userRank` được backend tự động đính kèm nếu request có JWT và
  ///   viewer nằm trong top 1000.
  Future<Either<Failure, LeaderboardResultEntity>> fetchLeaderboard({
    required LeaderboardKind kind,
    int top = 50,
    int offset = 0,
  });
}
