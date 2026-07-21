// Test fixtures & fakes cho module Tournament.
//
// Cung cấp:
//   - FakeTournamentRepository: stand-in cho TournamentRepository, default
//     trả về danh sách rỗng. Test có thể inject danh sách / failure tuỳ ý.
//   - TournamentTestFixtures: tạo dữ liệu entity đúng schema backend để test.

import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';

class FakeTournamentRepository implements TournamentRepository {
  List<TournamentEntity> openTournaments;
  List<TournamentEntity> upcomingTournaments;
  List<TournamentEntity> myRegistrations;
  List<EloHistoryEntity> eloHistory;
  List<LeaderboardEntryEntity> leaderboard;
  TournamentEntity? tournamentDetail;
  Map<String, List<TournamentParticipantEntity>> participants;
  Map<String, TournamentParticipantEntity> participantById;
  Map<String, List<TournamentMatchEntity>> matches;
  Map<String, TournamentMatchEntity> matchById;
  Failure? failure;
  Failure? registerFailure;

  FakeTournamentRepository({
    List<TournamentEntity>? openTournaments,
    List<TournamentEntity>? upcomingTournaments,
    List<TournamentEntity>? myRegistrations,
    List<EloHistoryEntity>? eloHistory,
    List<LeaderboardEntryEntity>? leaderboard,
    this.tournamentDetail,
    Map<String, List<TournamentParticipantEntity>>? participants,
    Map<String, TournamentParticipantEntity>? participantById,
    Map<String, List<TournamentMatchEntity>>? matches,
    Map<String, TournamentMatchEntity>? matchById,
    this.failure,
    this.registerFailure,
  })  : openTournaments = openTournaments ?? <TournamentEntity>[],
        upcomingTournaments = upcomingTournaments ?? <TournamentEntity>[],
        myRegistrations = myRegistrations ?? <TournamentEntity>[],
        eloHistory = eloHistory ?? <EloHistoryEntity>[],
        leaderboard = leaderboard ?? <LeaderboardEntryEntity>[],
        participants = participants ?? <String, List<TournamentParticipantEntity>>{},
        participantById = participantById ?? <String, TournamentParticipantEntity>{},
        matches = matches ?? <String, List<TournamentMatchEntity>>{},
        matchById = matchById ?? <String, TournamentMatchEntity>{};

  void setFailure(Failure? newFailure) => failure = newFailure;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getOpenTournaments({
    String? gameTemplateId,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(openTournaments);
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getUpcomingTournaments({
    String? gameTemplateId,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(upcomingTournaments);
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentDetail(
    String id,
  ) async {
    if (failure != null) return Left(failure!);
    if (tournamentDetail != null) return Right(tournamentDetail!);
    return Right(
      TournamentTestFixtures.tournament(id: id, title: 'Giải $id'),
    );
  }

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(
    String id, {
    String? currentUserId,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(participants[id] ?? const []);
  }

  @override
  Future<Either<Failure, TournamentParticipantEntity>> getParticipant(
    String tournamentId,
    String participantId, {
    String? currentUserId,
  }) async {
    if (failure != null) return Left(failure!);
    final existing = participantById[participantId];
    if (existing != null) return Right(existing);
    return Right(
      TournamentTestFixtures.participant(
        id: participantId,
        tournamentId: tournamentId,
      ),
    );
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(
    String id,
  ) async {
    if (failure != null) return Left(failure!);
    return Right(matches[id] ?? const []);
  }

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatchesByRound(
    String id,
    int round,
  ) async {
    if (failure != null) return Left(failure!);
    final all = matches[id] ?? const <TournamentMatchEntity>[];
    return Right(all.where((m) => m.roundNumber == round).toList());
  }

  @override
  Future<Either<Failure, TournamentMatchEntity>> getMatchById(
    String matchId,
  ) async {
    if (failure != null) return Left(failure!);
    final existing = matchById[matchId];
    if (existing != null) return Right(existing);
    return Right(
      TournamentTestFixtures.match(id: matchId),
    );
  }

  @override
  Future<Either<Failure, void>> register(String id) async {
    if (registerFailure != null) return Left(registerFailure!);
    if (failure != null) return Left(failure!);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unregister(String id) async {
    if (failure != null) return Left(failure!);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TournamentEntity>>> getMyRegistrations({
    String? status,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(myRegistrations);
  }

  @override
  Future<Either<Failure, List<EloHistoryEntity>>> getMyEloHistory() async {
    if (failure != null) return Left(failure!);
    return Right(eloHistory);
  }

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard({
    int topCount = 100,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(leaderboard);
  }
}

/// Builders cho entity tests.
class TournamentTestFixtures {
  TournamentTestFixtures._();

  static DateTime _daysFromNow(int days) =>
      DateTime.now().add(Duration(days: days));

  static TournamentEntity tournament({
    String id = 't1',
    String title = 'Wingspan Season Opening',
    TournamentStatus status = TournamentStatus.registrationOpen,
    DateTime? startTime,
  }) {
    return TournamentEntity(
      id: id,
      title: title,
      cafeName: 'Cafe Láng Hạ',
      gameTemplateName: 'Wingspan',
      startTime: startTime ?? _daysFromNow(7),
      registrationDeadline: _daysFromNow(5),
      status: status,
      currentParticipants: 8,
      maxParticipants: 16,
      minKarmaRequirement: 0,
      registrationFee: null,
      prizePool: 1000000,
      description: 'Mô tả chi tiết của giải đấu test',
      organizerName: 'Quán Cafe Láng Hạ',
      roundDurationMinutes: 30,
      preliminaryRounds: 3,
      currentRound: 1,
      isUserRegistered: false,
      isUserCheckedIn: false,
    );
  }

  static TournamentParticipantEntity participant({
    String id = 'p1',
    String tournamentId = 't1',
    bool isCurrentUser = false,
  }) {
    return TournamentParticipantEntity(
      id: id,
      oderId: 'user-$id',
      displayName: 'Player $id',
      avatarUrl: null,
      elo: 1500,
      karma: 100,
      status: ParticipantStatus.checkedIn,
      swissScore: 0,
      prestigePoints: 0,
      finalRank: null,
      eloDelta: 0,
      isWalkIn: false,
      isCurrentUser: isCurrentUser,
    );
  }

  static TournamentMatchEntity match({String id = 'm1'}) {
    return TournamentMatchEntity(
      id: id,
      roundNumber: 1,
      isFinal: false,
      tableNumber: 1,
      status: MatchStatus.scheduled,
      winnerId: null,
      results: const [],
    );
  }

  static EloHistoryEntity eloHistory({
    String id = 'e1',
    int delta = 25,
    int initialElo = 1500,
  }) {
    return EloHistoryEntity(
      id: id,
      oderId: 'user-1',
      displayName: 'Player 1',
      tournamentTitle: 'Wingspan Season Opening',
      tournamentId: 't1',
      initialElo: initialElo,
      finalElo: initialElo + delta,
      delta: delta,
      playedAt: _daysFromNow(-3),
      rank: 1,
    );
  }

  static LeaderboardEntryEntity leaderboard({int rank = 1}) {
    return LeaderboardEntryEntity(
      rank: rank,
      oderId: 'user-$rank',
      displayName: 'Player Rank $rank',
      avatarUrl: null,
      globalElo: 2000 - rank * 25,
      karma: 500 - rank * 5,
      tournamentsPlayed: 25 - rank,
      tournamentsWon: 5,
    );
  }
}
