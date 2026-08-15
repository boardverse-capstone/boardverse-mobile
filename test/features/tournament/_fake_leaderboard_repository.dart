// Test fixtures & fakes cho module Leaderboard.
//
//   - FakeLeaderboardRepository: stand-in cho LeaderboardRepository, default
//     trả về danh sách rỗng. Test có thể inject danh sách / failure tuỳ ý.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/leaderboard/domain/entities/gamer_tier.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_entry_entity.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_result_entity.dart';
import 'package:boardverse/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:dartz/dartz.dart';

class FakeLeaderboardRepository implements LeaderboardRepository {
  List<LeaderboardEntryEntity> entries = const [];
  Failure? failure;

  void setFailure(Failure? newFailure) => failure = newFailure;

  /// Empty result helper.
  static LeaderboardResultEntity emptyResult() => LeaderboardResultEntity(
        entries: const [],
        offset: 0,
        limit: 50,
        totalCount: 0,
        generatedAt: DateTime(2026),
      );

  /// Sample entry helper — chỉ để test, không phản ánh đầy đủ schema.
  static LeaderboardEntryEntity entry({
    int rank = 1,
    String name = 'Player 1',
    int? elo,
  }) {
    return LeaderboardEntryEntity(
      rank: rank,
      userId: 'user-$rank',
      username: 'user_$rank',
      displayName: name,
      avatarUrl: null,
      globalElo: elo ?? 2000 - rank * 25,
      level: 30 - rank,
      gamerTier: GamerTier.gold,
    );
  }

  @override
  Future<Either<Failure, LeaderboardResultEntity>> fetchLeaderboard({
    required LeaderboardKind kind,
    int top = 50,
    int offset = 0,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(LeaderboardResultEntity(
      entries: entries,
      offset: offset,
      limit: top,
      totalCount: entries.length,
      generatedAt: DateTime.now(),
    ));
  }
}
