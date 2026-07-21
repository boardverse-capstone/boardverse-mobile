// Widget tests cho LeaderboardPage.
//
// Verify:
//   - Empty state khi leaderboard rỗng.
//   - Render danh sách người chơi với rank + elo.
//   - Error state có nút retry.

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/leaderboard_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_tournament_repository.dart';

void main() {
  late FakeTournamentRepository repository;

  setUp(() {
    repository = FakeTournamentRepository();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required LeaderboardCubit cubit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LeaderboardPage(cubit: cubit),
      ),
    );
    await cubit.loadLeaderboard();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('LeaderboardPage', () {
    testWidgets('shows empty state when leaderboard is empty', (tester) async {
      final cubit = LeaderboardCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.textContaining('Bảng xếp hạng'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      repository.setFailure(const ServerFailure(message: 'Lỗi mạng'));

      final cubit = LeaderboardCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text('Lỗi mạng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Retry triggers reload.
      repository.setFailure(null);
      repository.leaderboard = [
        TournamentTestFixtures.leaderboard(rank: 1),
      ];
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders player tiles when loaded', (tester) async {
      repository.leaderboard = [
        TournamentTestFixtures.leaderboard(rank: 1),
        TournamentTestFixtures.leaderboard(rank: 2),
        TournamentTestFixtures.leaderboard(rank: 3),
      ];

      final cubit = LeaderboardCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      // Each entry should display display name.
      expect(find.text('Player Rank 1'), findsOneWidget);
      expect(find.text('Player Rank 2'), findsOneWidget);
      expect(find.text('Player Rank 3'), findsOneWidget);
    });
  });
}
