// Widget tests cho TournamentDetailPage (3 tabs).
//
// Verify:
//   - 3 tabs được render (Thông tin / Người tham gia / Bàn đấu).
//   - Info tab hiển thị tournament title.
//   - Participants tab hiển thị danh sách participants.
//   - Matches tab hiển thị rounds + matches.

import 'dart:typed_data';

import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/data/datasources/tournament_remote_datasource_impl.dart';
import 'package:boardverse_mobile/features/tournament/data/models/elo_history_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/match_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/participant_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/my_registration_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/tournament_model.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/tournament_detail_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_tournament_repository.dart';

void main() {
  late FakeTournamentRepository repository;

  setUp(() {
    repository = FakeTournamentRepository();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required TournamentDetailCubit cubit,
    String tournamentId = 't1',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: TournamentDetailPage(tournamentId: tournamentId, cubit: cubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('renders 3 tabs when data loaded', (tester) async {
    repository.tournamentDetail = TournamentTestFixtures.tournament(id: 't1');
    final cubit = TournamentDetailCubit(repository: repository);
    await cubit.loadDetail('t1');

    await pumpDetail(tester, cubit: cubit);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thông tin'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Người tham gia'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Bàn đấu'), findsAtLeastNWidgets(1));
  });

  testWidgets('info tab shows tournament title', (tester) async {
    repository.tournamentDetail = TournamentTestFixtures.tournament(
      id: 't1',
      title: 'Wingspan Premium Cup',
    );
    final cubit = TournamentDetailCubit(repository: repository);
    await cubit.loadDetail('t1');

    await pumpDetail(tester, cubit: cubit);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Wingspan Premium Cup'), findsAtLeastNWidgets(1));
  });

  testWidgets('participants tab lists participants', (tester) async {
    repository.tournamentDetail = TournamentTestFixtures.tournament(id: 't1');
    repository.participants = {
      't1': [
        TournamentTestFixtures.participant(id: 'p1'),
        TournamentTestFixtures.participant(id: 'p2'),
      ],
    };
    final cubit = TournamentDetailCubit(repository: repository);
    await cubit.loadDetail('t1');

    await pumpDetail(tester, cubit: cubit);
    await tester.pump(const Duration(milliseconds: 300));

    // Tap "Người tham gia" tab — match the tab label which has count suffix.
    await tester.tap(find.text('Người tham gia (2)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Player p1'), findsOneWidget);
    expect(find.text('Player p2'), findsOneWidget);
  });

  testWidgets('matches tab lists rounds', (tester) async {
    repository.tournamentDetail = TournamentTestFixtures.tournament(id: 't1');
    repository.matches = {
      't1': [TournamentTestFixtures.match(id: 'm1')],
    };
    final cubit = TournamentDetailCubit(repository: repository);
    await cubit.loadDetail('t1');

    await pumpDetail(tester, cubit: cubit);
    await tester.pump(const Duration(milliseconds: 300));

    // Tap "Bàn đấu" tab — match the tab label which has count suffix.
    await tester.tap(find.text('Bàn đấu (1)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Vòng 1'), findsAtLeastNWidgets(1));
  });

  test('participant model preserves half-point Swiss scores', () {
    final model = TournamentParticipantModel.fromJson({
      'id': 'p1',
      'userId': 'u1',
      'displayName': 'Player 1',
      'swissScore': 2.5,
      'status': 'checked_in',
    });

    expect(model.swissScore, 2.5);
    expect(model.toEntity().status, ParticipantStatus.checkedIn);
  });

  test(
      'participant model reads username + walkInDisplayName + currentElo from player-facing payload',
      () {
    // Payload này khớp với response thật của GET /tournaments/{id}/participants
    // (xem README): backend trả `username`, `walkInDisplayName`,
    // `currentElo` — không phải `displayName` / `finalElo`.
    final json = {
      'id': 'a0f2ef9d-6c45-469c-a5b3-775df391b25d',
      'tournamentId': 'e60821ac-12b1-4b6f-9921-ff56cadd52e7',
      'userId': '14acc364-e60e-49b5-9399-7e3c9a823407',
      'username': 'player5',
      'avatarUrl': null,
      'walkInDisplayName': null,
      'walkInPhoneNumber': null,
      'isWalkIn': false,
      'joinedRoundNumber': 1,
      'registeredAt': '2026-08-06T04:59:44.205876Z',
      'karmaAtRegistration': 100,
      'status': 'Registered',
      'totalPrestigePoints': 0,
      'totalCardsBought': 0,
      'finalRank': null,
      'initialElo': 1200,
      'currentElo': 1250, // đã có Elo update sau vài round
      'eloDelta': 50,
      'finalElo': 1200,
      'swissWins': 2,
      'swissDraws': 0,
      'swissLosses': 0,
      'swissScore': 2.0,
      'isWaitlisted': false,
      'waitlistPosition': null,
    };

    final model = TournamentParticipantModel.fromJson(json);
    final entity = model.toEntity();

    expect(entity.userId, '14acc364-e60e-49b5-9399-7e3c9a823407');
    expect(entity.displayName, 'player5');
    expect(entity.elo, 1250); // currentElo, không phải finalElo
    expect(entity.karma, 100);
    expect(entity.eloDelta, 50);
    expect(entity.isWalkIn, false);
  });

  test('participant model prefers walkInDisplayName over username for walk-ins',
      () {
    final json = {
      'id': 'walkin-1',
      'userId': null,
      'username': null,
      'walkInDisplayName': 'Khách vãng lai #42',
      'walkInPhoneNumber': '0901234567',
      'isWalkIn': true,
      'karmaAtRegistration': 0,
      'status': 'Registered',
      'currentElo': 1500,
      'initialElo': 1500,
      'finalElo': 1500,
      'eloDelta': 0,
    };

    final model = TournamentParticipantModel.fromJson(json);
    expect(model.displayName, 'Khách vãng lai #42');
    expect(model.userId, '');
    expect(model.isWalkIn, true);
  });

  test('tournament model reads registeredCount + currentUserRegistered', () {
    // Payload khớp response GET /tournaments/open (xem README).
    final json = {
      'id': 'e60821ac-12b1-4b6f-9921-ff56cadd52e7',
      'cafeId': 'a477d3e6-9653-4be6-8f32-0c41ffc98be1',
      'cafeName': 'Vietcold Cafe',
      'title': 'Giải Đấu Splendor Mùa Hè 2026',
      'gameTemplateId': '44444444-4444-4444-4444-444444444444',
      'gameName': 'Splendor',
      'startTime': '2026-08-10T09:00:00Z',
      'registrationDeadline': '2026-08-09T18:00:00Z',
      'maxParticipants': 32,
      'minParticipants': 8,
      'roundDurationMinutes': 60,
      'totalRounds': 4,
      'preliminaryRounds': 3,
      'finalistCount': 4,
      'minKarmaRequirement': 50,
      'status': 'RegistrationOpen',
      'registeredCount': 3, // ← field này trước đây model không đọc
      'checkedInCount': 0,
      'currentUserRegistered': true, // ← field này trước đây model không đọc
    };

    final model = TournamentModel.fromJson(json);
    final entity = model.toEntity();

    expect(entity.currentParticipants, 3);
    expect(entity.maxParticipants, 32);
    expect(entity.isUserRegistered, true);
  });

  test('match model accepts numeric and aliased payload fields', () {
    final model = TournamentMatchModel.fromJson({
      'matchId': 'm1',
      'round': 2.0,
      'table': '3',
      'matchStatus': 'OnGoing',
    });

    expect(model.id, 'm1');
    expect(model.roundNumber, 2);
    expect(model.tableNumber, 3);
  });

  test('detail merges current participant registration state', () async {
    repository.tournamentDetail = TournamentTestFixtures.tournament(id: 't1');
    repository.participants = {
      't1': [TournamentTestFixtures.participant(id: 'p1', isCurrentUser: true)],
    };
    final cubit = TournamentDetailCubit(repository: repository);

    await cubit.loadDetail('t1', currentUserId: 'user-p1');

    final loaded = cubit.state as TournamentDetailLoaded;
    expect(loaded.tournament.isUserRegistered, isTrue);
    expect(loaded.tournament.isUserCheckedIn, isTrue);
  });

  test(
    'detail datasource rejects successful envelope with null data',
    () async {
      final dio = Dio()..httpClientAdapter = _NullEnvelopeAdapter();
      final datasource = TournamentRemoteDatasourceImpl(dio: dio);

      expect(
        () => datasource.getTournamentDetail('t1'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Không có dữ liệu',
          ),
        ),
      );
    },
  );

  // ─── Regression tests for new field-shape parsing ─────────────────
  // Bug: GET /tournaments/my-registrations returns a FLAT shape (mixed
  // tournament + participant) with field name `tournamentStatus` (not
  // `status`), and missing `registrationDeadline`, `maxParticipants`, …
  // Previously the model tried to parse it as TournamentResponseDto and
  // threw "Tournament response is missing registrationDeadline".
  test('myRegistration model parses flat backend payload', () {
    final json = {
      'tournamentId': 'e60821ac-12b1-4b6f-9921-ff56cadd52e7',
      'title': 'Giải Đấu Splendor Mùa Hè 2026 - BoardVerse POS',
      'cafeId': 'a477d3e6-9653-4be6-8f32-0c41ffc98be1',
      'cafeName': 'Vietcold Cafe',
      'startTime': '2026-08-10T09:00:00Z',
      'tournamentStatus': 'RegistrationOpen',
      'participantId': '9dc65d21-e71b-4a80-bf48-67a601e672af',
      'participantStatus': 'Registered',
      'isWalkIn': false,
      'walkInDisplayName': null,
      'registeredAt': '2026-08-06T07:00:55.706771Z',
      'checkedInAt': null,
      'swissScore': 0,
      'swissWins': 1,
      'swissDraws': 0,
      'swissLosses': 0,
      'finalRank': null,
      'initialElo': 1200,
      'finalElo': 1200,
      'eloDelta': 0,
    };

    final model = MyRegistrationModel.fromJson(json);
    final entity = model.toEntity();

    expect(entity.tournamentId, 'e60821ac-12b1-4b6f-9921-ff56cadd52e7');
    expect(entity.title, contains('Splendor'));
    expect(entity.cafeName, 'Vietcold Cafe');
    expect(entity.tournamentStatus, 'RegistrationOpen');
    expect(entity.participantStatus, 'Registered');
    expect(entity.isWalkIn, false);
    expect(entity.eloDelta, 0);
  });

  // Bug: GET /tournaments/my-elo-history returns an OBJECT wrapper
  // { userId, username, currentElo, history: [...] }, not an array.
  // Previously the datasource tried to unwrap it as a list and threw
  // "Response không đúng định dạng envelope (expected array)".
  test('myEloHistory response model parses wrapped object', () {
    final json = {
      'userId': '092bbcf3-e729-43b5-8913-898961babc99',
      'username': 'jonny',
      'currentElo': 1200,
      'history': [
        {
          'tournamentId': '12b3b43d-aa47-48f4-82c9-efea66320844',
          'tournamentTitle': 'Splendor Mở Rộng 1',
          'gameTemplateName': 'Splendor',
          'tournamentDate': '2026-08-01T09:00:00Z',
          'eloBefore': 1200,
          'eloAfter': 1200,
          'eloDelta': 0,
          'finalRank': null,
          'tournamentStatus': 'RegistrationClosed',
        },
      ],
    };

    final model = MyEloHistoryResponseModel.fromJson(json);
    final entity = model.toEntity();

    expect(entity.username, 'jonny');
    expect(entity.currentElo, 1200);
    expect(entity.history, hasLength(1));
    expect(entity.history.first.initialElo, 1200);
    expect(entity.history.first.finalElo, 1200);
    expect(entity.history.first.tournamentTitle, 'Splendor Mở Rộng 1');
    expect(entity.history.first.delta, 0);
    expect(
      entity.history.first.tournamentStatus,
      'RegistrationClosed',
    );
  });

  test('myEloHistory handles empty history array', () {
    final model = MyEloHistoryResponseModel.fromJson({
      'userId': 'u1',
      'username': 'jonny',
      'currentElo': 1500,
      'history': [],
    });
    final entity = model.toEntity();
    expect(entity.history, isEmpty);
    expect(entity.currentElo, 1500);
  });
}

class _NullEnvelopeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"statusCode":200,"message":"Không có dữ liệu","data":null}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
