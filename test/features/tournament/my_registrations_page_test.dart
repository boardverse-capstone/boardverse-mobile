// Widget tests cho MyRegistrationsPage.
//
// Verify:
//   - Empty state hiển thị đúng với filter "Tất cả".
//   - Filtered empty state hiển thị đúng với filter cụ thể.
//   - Tournament cards render dữ liệu từ repository.
//   - Filter chip tap → cubit.applyFilter được gọi.

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/my_registrations_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/my_registrations_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/my_registrations_page.dart';
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
    required MyRegistrationsCubit cubit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MyRegistrationsPage(cubit: cubit),
      ),
    );
    // Trigger initial load (production code does this in BlocProvider.create,
    // but here we inject the cubit directly so we have to call it ourselves).
    await cubit.loadMyRegistrations();
    // Allow cubit & cubit.loadMyRegistrations() to settle, but pump (not
    // pumpAndSettle) so we don't loop forever on Shimmer animations.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('MyRegistrationsPage', () {
    testWidgets('shows error state with retry on failure', (tester) async {
      repository.setFailure(const ServerFailure(message: 'Mạng không ổn'));

  final cubit = MyRegistrationsCubit(repository: repository);
  await pumpPage(tester, cubit: cubit);

  expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
  expect(find.text('Mạng không ổn'), findsOneWidget);
  expect(find.text('Thử lại'), findsOneWidget);

  // Tap retry → empty list state.
  repository.setFailure(null);
  await tester.tap(find.text('Thử lại'));
  // Use pump, not pumpAndSettle — Shimmer animations would loop forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  expect(find.text('Chưa có giải đấu'), findsOneWidget);
});

    testWidgets('shows empty state for all filter when list is empty',
        (tester) async {
      final cubit = MyRegistrationsCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Chưa có giải đấu'), findsOneWidget);
      expect(
        find.text('Bạn chưa đăng ký giải đấu nào.'),
        findsOneWidget,
      );
    });

    testWidgets('renders tournament cards when loaded', (tester) async {
      repository.myRegistrations = [
        TournamentTestFixtures.tournament(
          id: 't1',
          title: 'Wingspan Cup',
          status: TournamentStatus.ongoing,
        ),
        TournamentTestFixtures.tournament(
          id: 't2',
          title: 'Catan Masters',
          status: TournamentStatus.completed,
        ),
      ];

      final cubit = MyRegistrationsCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      expect(find.text('Wingspan Cup'), findsOneWidget);
      expect(find.text('Catan Masters'), findsOneWidget);
      expect(find.text('8/16'), findsNWidgets(2));
    });

    testWidgets('switching filter chip triggers reload', (tester) async {
      final cubit = MyRegistrationsCubit(repository: repository);
      await pumpPage(tester, cubit: cubit);

      // The first filter chip is "Tất cả" — tap "Hoàn thành" inside the chip list.
      final finder = find.text('Hoàn thành');
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.currentFilter, MyRegistrationsFilter.completed);
      expect(
        find.text('Không có giải đấu nào ở trạng thái "Hoàn thành".'),
        findsOneWidget,
      );
    });
  });
}
