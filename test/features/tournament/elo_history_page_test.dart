// Widget tests cho EloHistoryPage.
//
// Verify:
//   - Empty state khi lịch sử trống.
//   - Render summary card với Elo hiện tại + delta.
//   - Render chart title + lịch sử chi tiết items.
//   - Error state có nút retry.

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/elo_history_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/elo_history_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/elo_history_page.dart';
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
    required EloHistoryCubit cubit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EloHistoryPage(cubit: cubit),
      ),
    );
    await cubit.loadEloHistory();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('EloHistoryPage', () {
    testWidgets('shows empty state when history is empty', (tester) async {
      final cubit = EloHistoryCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Chưa có lịch sử Elo'), findsOneWidget);
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      repository.setFailure(const ServerFailure(message: 'Mất kết nối'));

      final cubit = EloHistoryCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
      expect(find.text('Mất kết nối'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Retry → empty state.
      repository.setFailure(null);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Chưa có lịch sử Elo'), findsOneWidget);
    });

    testWidgets('shows summary card + chart + history items', (tester) async {
      repository.eloHistory = [
        TournamentTestFixtures.eloHistory(id: 'e1', delta: 30, initialElo: 1500),
        TournamentTestFixtures.eloHistory(
          id: 'e2',
          delta: -15,
          initialElo: 1530,
        ),
        TournamentTestFixtures.eloHistory(
          id: 'e3',
          delta: 20,
          initialElo: 1515,
        ),
      ];

      final cubit = EloHistoryCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      // Summary card
      expect(find.text('Elo hiện tại'), findsOneWidget);

      // Chart section
      expect(find.text('Biểu đồ Elo'), findsOneWidget);

      // Detailed history (reversed = newest first)
      expect(find.text('Lịch sử chi tiết'), findsOneWidget);
    });

    testWidgets('handles empty history gracefully', (tester) async {
      final cubit = EloHistoryCubit(repository: repository);
      await cubit.loadEloHistory();
      expect(cubit.state, isA<EloHistoryLoaded>());
      final loaded = cubit.state as EloHistoryLoaded;
      expect(loaded.history, isEmpty);
      expect(loaded.currentElo, 0);
    });
  });
}
