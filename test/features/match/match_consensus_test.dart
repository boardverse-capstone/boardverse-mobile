// Test cho Match (Elo consensus) module — Task 4.
//
// Verify:
// - Mock consensus state machine: Draw-all / 1-Win+N-Loss → Finalized
// - Conflict rule: reject khi submit quá nhiều lần vượt requiredCount
// - 409 rejection sau khi Finalized
// - Cubit load → Loaded, submit → refetch, submit sau Finalized → Failure.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse_mobile/features/match/data/datasources/base/match_result_remote_datasource.dart';
import 'package:boardverse_mobile/features/match/data/datasources/mock/mock_match_result_remote_datasource.dart';
import 'package:boardverse_mobile/features/match/data/match_result_repository_impl.dart';
import 'package:boardverse_mobile/features/match/domain/entities/match_consensus_entity.dart';
import 'package:boardverse_mobile/features/match/presentation/cubit/match_result_cubit.dart';

MatchResultCubit _makeCubit() => MatchResultCubit(
      repository: MatchResultRepositoryImpl(
        remote: MockMatchResultRemoteDatasource(),
      ),
    );

void main() {
  group('MockMatchResultRemoteDatasource — consensus state machine', () {
    late MatchResultRemoteDatasource ds;

    setUp(() {
      ds = MockMatchResultRemoteDatasource();
      MockMatchResultRemoteDatasource.resetState(
        'lobby_test_consensus',
      );
      MockMatchResultRemoteDatasource.resetState('lobby_test_after_finalized');
    });

    test('initial state — AwaitingSubmissions với 0 submit', () async {
      const lobbyId = 'lobby_test_consensus';
      final res = await ds.getMatchResult(lobbyId);
      res.fold(
        (_) => fail('expected Right'),
        (c) {
          expect(c.consensusStatus, MatchConsensusStatus.awaitingSubmissions);
          expect(c.submittedCount, 0);
          expect(c.requiredCount, 4);
        },
      );
    });

    test('tất cả Draw → Finalized (Draw rule AC 4.2)', () async {
      const lobbyId = 'lobby_test_consensus';
      for (var i = 0; i < 4; i++) {
        final r = await ds.submitMatchResult(
          lobbyId: lobbyId,
          outcome: MatchOutcome.draw,
        );
        expect(r.isRight(), isTrue, reason: 'submit $i should succeed');
      }
      // Submit lần 5 → Left vì vượt requiredCount.
      final oversubmit = await ds.submitMatchResult(
        lobbyId: lobbyId,
        outcome: MatchOutcome.draw,
      );
      expect(oversubmit.isLeft(), isTrue);

      final after = await ds.getMatchResult(lobbyId);
      after.fold(
        (_) => fail('expected Right'),
        (c) {
          expect(c.consensusStatus, MatchConsensusStatus.finalized);
          expect(c.submittedCount, 4);
        },
      );
    });

    test('1 Win + 3 Loss → Finalized (Win/Loss rule AC 4.2)', () async {
      const lobbyId = 'lobby_test_consensus';
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.win);
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.loss);
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.loss);
      final last = await ds.submitMatchResult(
        lobbyId: lobbyId,
        outcome: MatchOutcome.loss,
      );
      expect(last.isRight(), isTrue);
      final after = await ds.getMatchResult(lobbyId);
      after.fold(
        (_) => fail('expected Right'),
        (c) => expect(c.consensusStatus, MatchConsensusStatus.finalized),
      );
    });

    test('2 Win + 2 Loss → Conflict', () async {
      const lobbyId = 'lobby_test_consensus';
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.win);
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.win);
      await ds.submitMatchResult(lobbyId: lobbyId, outcome: MatchOutcome.loss);
      final last = await ds.submitMatchResult(
        lobbyId: lobbyId,
        outcome: MatchOutcome.loss,
      );
      expect(last.isRight(), isTrue);
      final after = await ds.getMatchResult(lobbyId);
      after.fold(
        (_) => fail('expected Right'),
        (c) {
          expect(c.consensusStatus, MatchConsensusStatus.conflict);
          expect(c.conflictReason, isNotNull);
        },
      );
    });

    test('submit khi đã Finalized → Left Failure', () async {
      const lobby2 = 'lobby_test_after_finalized';
      for (var i = 0; i < 4; i++) {
        await ds.submitMatchResult(lobbyId: lobby2, outcome: MatchOutcome.draw);
      }
      final oversubmit = await ds.submitMatchResult(
        lobbyId: lobby2,
        outcome: MatchOutcome.win,
      );
      expect(oversubmit.isLeft(), isTrue);
    });
  });

  group('MatchResultCubit — flow', () {
    blocTest<MatchResultCubit, MatchResultState>(
      'loadMatchResult → Loaded',
      build: _makeCubit,
      act: (c) async {
        await c.loadMatchResult('lobby_001');
      },
      expect: () => [
        isA<MatchResultLoading>(),
        isA<MatchResultLoaded>(),
      ],
    );

    blocTest<MatchResultCubit, MatchResultState>(
      'submit 4 Draw → emit Finalized cuối cùng',
      build: _makeCubit,
      act: (c) async {
        await c.loadMatchResult('lobby_finalize_test');
        for (var i = 0; i < 4; i++) {
          await c.submitMatchResult(
            lobbyId: 'lobby_finalize_test',
            outcome: MatchOutcome.draw,
          );
        }
      },
      skip: 0,
      verify: (cubit) {
        expect(cubit.state, isA<MatchResultFinalized>());
      },
    );
  });
}
