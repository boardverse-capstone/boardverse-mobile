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
import 'package:boardverse_mobile/features/tournament/data/models/match_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/participant_model.dart';
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
