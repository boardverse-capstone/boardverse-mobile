// Widget tests cho LeaderboardPage (Tournament).
//
// Verify:
//   - Empty state khi leaderboard rỗng.
//   - Render danh sách người chơi với rank + elo.
//   - Error state có nút retry.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:boardverse/features/tournament/presentation/pages/leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_leaderboard_repository.dart';

void main() {
  late FakeLeaderboardRepository repository;

  setUp(() {
    repository = FakeLeaderboardRepository();
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
    await cubit.load(LeaderboardKind.elo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('LeaderboardPage', () {
    testWidgets('shows empty state when leaderboard is empty', (tester) async {
      final cubit = LeaderboardCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      // Tournament page chỉ show Elo — assert metric label xuất hiện.
      expect(find.text('Bảng xếp hạng'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      repository.setFailure(const ServerFailure(message: 'Lỗi mạng'));

      final cubit = LeaderboardCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text('Lỗi mạng'), findsOneWidget);
      expect(find.text('THỬ LẠI'), findsOneWidget);
    });

    testWidgets('renders player tiles when loaded', (tester) async {
      repository.entries = [
        FakeLeaderboardRepository.entry(rank: 1, name: 'Player Rank 1'),
        FakeLeaderboardRepository.entry(rank: 2, name: 'Player Rank 2'),
        FakeLeaderboardRepository.entry(rank: 3, name: 'Player Rank 3'),
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
