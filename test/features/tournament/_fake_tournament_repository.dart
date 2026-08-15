// Test fixtures & fakes cho module Tournament.
//
// Cung cấp:
//   - FakeTournamentRepository: stand-in cho TournamentRepository, default
//     trả về danh sách rỗng. Test có thể inject danh sách / failure tuỳ ý.
//   - TournamentTestFixtures: tạo dữ liệu entity đúng schema backend để test.

import 'package:dartz/dartz.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/tournament/domain/entities/elo_history_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/my_elo_history_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/my_registration_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';
import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';

class FakeTournamentRepository implements TournamentRepository {
  List<TournamentEntity> openTournaments;
  List<MyRegistrationEntry> myRegistrations;
  MyEloHistoryResponse eloHistory;
  TournamentEntity? tournamentDetail;
  Map<String, List<TournamentParticipantEntity>> participants;
  Map<String, TournamentParticipantEntity> participantById;
  Map<String, List<TournamentMatchEntity>> matches;
  Map<String, TournamentMatchEntity> matchById;
  Failure? failure;
  Failure? registerFailure;

  MyWaitlistStatus myWaitlistStatus;
  List<TournamentWaitlistEntry> waitlistEntries;
  MySpectatorStatus mySpectatorStatus;
  List<TournamentSpectatorEntry> spectatorEntries;

  FakeTournamentRepository({
    List<TournamentEntity>? openTournaments,
    List<MyRegistrationEntry>? myRegistrations,
    MyEloHistoryResponse? eloHistory,
    this.tournamentDetail,
    Map<String, List<TournamentParticipantEntity>>? participants,
    Map<String, TournamentParticipantEntity>? participantById,
    Map<String, List<TournamentMatchEntity>>? matches,
    Map<String, TournamentMatchEntity>? matchById,
    this.failure,
    this.registerFailure,
    MyWaitlistStatus? myWaitlistStatus,
    List<TournamentWaitlistEntry>? waitlistEntries,
    MySpectatorStatus? mySpectatorStatus,
    List<TournamentSpectatorEntry>? spectatorEntries,
  }) : openTournaments = openTournaments ?? <TournamentEntity>[],
       myRegistrations = myRegistrations ?? <MyRegistrationEntry>[],
       eloHistory =
           eloHistory ??
           const MyEloHistoryResponse(
             userId: '',
             username: '',
             currentElo: 0,
             history: [],
           ),
       participants =
           participants ?? <String, List<TournamentParticipantEntity>>{},
       participantById =
           participantById ?? <String, TournamentParticipantEntity>{},
       matches = matches ?? <String, List<TournamentMatchEntity>>{},
       matchById = matchById ?? <String, TournamentMatchEntity>{},
       myWaitlistStatus =
           myWaitlistStatus ?? const MyWaitlistStatus(isInWaitlist: false),
       waitlistEntries = waitlistEntries ?? <TournamentWaitlistEntry>[],
       mySpectatorStatus =
           mySpectatorStatus ?? const MySpectatorStatus(isSpectating: false),
       spectatorEntries = spectatorEntries ?? <TournamentSpectatorEntry>[];

  void setFailure(Failure? newFailure) => failure = newFailure;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getOpenTournaments({
    String? gameTemplateId,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(openTournaments);
  }

  @override
  Future<Either<Failure, TournamentEntity>> getTournamentDetail(
    String id,
  ) async {
    if (failure != null) return Left(failure!);
    if (tournamentDetail != null) return Right(tournamentDetail!);
    return Right(TournamentTestFixtures.tournament(id: id, title: 'Giải $id'));
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
    String tournamentId,
    String matchId,
  ) async {
    if (failure != null) return Left(failure!);
    final existing = matchById[matchId];
    if (existing != null) return Right(existing);
    return Right(TournamentTestFixtures.match(id: matchId));
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
  Future<Either<Failure, List<MyRegistrationEntry>>> getMyRegistrations({
    String? status,
  }) async {
    if (failure != null) return Left(failure!);
    return Right(myRegistrations);
  }

  @override
  Future<Either<Failure, MyEloHistoryResponse>> getMyEloHistory() async {
    if (failure != null) return Left(failure!);
    return Right(eloHistory);
  }

  // ─── T-03: Waitlist ────────────────────────────────────────────────────

  Failure? waitlistJoinFailure;
  Failure? waitlistLeaveFailure;
  Failure? waitlistConfirmFailure;
  Failure? waitlistDeclineFailure;
  Failure? waitlistStatusFailure;
  Failure? waitlistListFailure;

  @override
  Future<Either<Failure, JoinWaitlistResult>> joinWaitlist(
    String tournamentId,
  ) async {
    if (waitlistJoinFailure != null) return Left(waitlistJoinFailure!);
    if (failure != null) return Left(failure!);
    return Right(
      JoinWaitlistResult(
        waitlistEntryId: 'entry-$tournamentId',
        tournamentId: tournamentId,
        tournamentName: 'Giải $tournamentId',
        userId: 'me',
        username: 'me',
        position: 1,
        joinedAt: DateTime.now(),
        status: WaitlistEntryStatus.waiting,
      ),
    );
  }

  @override
  Future<Either<Failure, List<TournamentWaitlistEntry>>> getWaitlist(
    String tournamentId, {
    int? page,
    int? pageSize,
  }) async {
    if (waitlistListFailure != null) return Left(waitlistListFailure!);
    if (failure != null) return Left(failure!);
    return Right(waitlistEntries);
  }

  @override
  Future<Either<Failure, MyWaitlistStatus>> getMyWaitlistStatus(
    String tournamentId,
  ) async {
    if (waitlistStatusFailure != null) return Left(waitlistStatusFailure!);
    if (failure != null) return Left(failure!);
    return Right(myWaitlistStatus);
  }

  @override
  Future<Either<Failure, void>> leaveWaitlist(String tournamentId) async {
    if (waitlistLeaveFailure != null) return Left(waitlistLeaveFailure!);
    if (failure != null) return Left(failure!);
    return const Right(null);
  }

  @override
  Future<Either<Failure, WaitlistActionResult>> confirmWaitlistOffer(
    String tournamentId,
  ) async {
    if (waitlistConfirmFailure != null) return Left(waitlistConfirmFailure!);
    if (failure != null) return Left(failure!);
    return Right(
      WaitlistActionResult(
        waitlistEntryId: 'entry-$tournamentId',
        tournamentId: tournamentId,
        status: WaitlistEntryStatus.promoted,
      ),
    );
  }

  @override
  Future<Either<Failure, WaitlistActionResult>> declineWaitlistOffer(
    String tournamentId,
  ) async {
    if (waitlistDeclineFailure != null) return Left(waitlistDeclineFailure!);
    if (failure != null) return Left(failure!);
    return Right(
      WaitlistActionResult(
        waitlistEntryId: 'entry-$tournamentId',
        tournamentId: tournamentId,
        status: WaitlistEntryStatus.cancelled,
      ),
    );
  }

  // ─── T-04: Spectator ──────────────────────────────────────────────────

  Failure? spectatorStartFailure;
  Failure? spectatorStopFailure;
  Failure? spectatorStatusFailure;
  Failure? spectatorListFailure;

  @override
  Future<Either<Failure, List<TournamentSpectatorEntry>>> getSpectators(
    String tournamentId,
  ) async {
    if (spectatorListFailure != null) return Left(spectatorListFailure!);
    if (failure != null) return Left(failure!);
    return Right(spectatorEntries);
  }

  @override
  Future<Either<Failure, MySpectatorStatus>> getMySpectatorStatus(
    String tournamentId,
  ) async {
    if (spectatorStatusFailure != null) return Left(spectatorStatusFailure!);
    if (failure != null) return Left(failure!);
    return Right(mySpectatorStatus);
  }

  @override
  Future<Either<Failure, TournamentSpectatorEntry>> startSpectating(
    String tournamentId,
  ) async {
    if (spectatorStartFailure != null) return Left(spectatorStartFailure!);
    if (failure != null) return Left(failure!);
    return Right(
      TournamentSpectatorEntry(
        id: 'sp-$tournamentId',
        tournamentId: tournamentId,
        tournamentTitle: 'Giải $tournamentId',
        userId: 'me',
        userName: 'me',
        joinedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> stopSpectating(String tournamentId) async {
    if (spectatorStopFailure != null) return Left(spectatorStopFailure!);
    if (failure != null) return Left(failure!);
    return const Right(null);
  }

  // Leaderboard đã tách ra feature riêng — không còn method trên
  // TournamentRepository.
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
      userId: 'user-$id',
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
      userId: 'user-1',
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

  /// MyRegistrationEntry khớp với response thật của
  /// `GET /tournaments/my-registrations`.
  static MyRegistrationEntry myRegistration({
    String id = 't1',
    String title = 'Splendor Summer Cup',
    String tournamentStatus = 'RegistrationOpen',
    String participantStatus = 'Registered',
    DateTime? startTime,
  }) {
    final s = startTime ?? _daysFromNow(7);
    return MyRegistrationEntry(
      tournamentId: id,
      title: title,
      cafeId: 'cafe-1',
      cafeName: 'Vietcold Cafe',
      startTime: s,
      tournamentStatus: tournamentStatus,
      participantId: 'p-$id',
      participantStatus: participantStatus,
      isWalkIn: false,
      walkInDisplayName: null,
      registeredAt: _daysFromNow(-1),
      checkedInAt: null,
      swissScore: 0,
      swissWins: 0,
      swissDraws: 0,
      swissLosses: 0,
      finalRank: null,
      initialElo: 1200,
      finalElo: 1200,
      eloDelta: 0,
    );
  }
}
