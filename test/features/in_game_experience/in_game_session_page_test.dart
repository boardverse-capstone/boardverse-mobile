import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/features/in_game_experience/data/in_game_repository_impl.dart';
import 'package:boardverse/features/in_game_experience/domain/repositories/in_game_repository.dart';
import 'package:boardverse/features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import 'package:boardverse/features/in_game_experience/presentation/pages/in_game_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InGameSessionPage', () {
    setUp(() {
      // Reset DI trước mỗi test để tránh state leak giữa các tests.
      if (sl.isRegistered<InGameRepository>()) {
        sl.unregister<InGameRepository>();
      }
      if (sl.isRegistered<InGameCubit>()) {
        sl.unregister<InGameCubit>();
      }
      sl.registerLazySingleton<InGameRepository>(() => InGameRepositoryImpl());
      sl.registerFactory<InGameCubit>(
        () => InGameCubit(repository: sl<InGameRepository>()),
      );
    });

    tearDown(() async {
      if (sl.isRegistered<InGameRepository>()) {
        final repo = sl<InGameRepository>();
        if (repo is InGameRepositoryImpl) {
          repo.dispose();
        }
        await sl.unregister<InGameRepository>();
      }
      if (sl.isRegistered<InGameCubit>()) {
        await sl.unregister<InGameCubit>();
      }
    });

    Widget wrap(Widget child) {
      return MaterialApp(
        home: BlocProvider<InGameCubit>(
          create: (_) => getIt<InGameCubit>(),
          child: child,
        ),
      );
    }

    testWidgets(
      'skipCheckIn=true không để page ở trạng thái InGameInitial trắng',
      (tester) async {
        // Đây là fix bug: trước đây khi skipCheckIn=true, page không gọi
        // checkIn nên state vẫn là InGameInitial → _buildBody render
        // SizedBox.shrink() → page trắng + mouse_tracker assertion.
        await tester.pumpWidget(
          wrap(
            const InGameSessionPage(
              bookingId: 'test-booking',
              cafeName: 'Test Cafe',
              gameName: 'Test Game',
              tableNumber: 5,
              skipCheckIn: true,
            ),
          ),
        );

        // Đợi cubit emit state mới.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));

        // Page phải render session view, không phải trắng.
        // Kiểm tra: text "Bàn số" xuất hiện → đã có session info.
        expect(find.text('Bàn số 5'), findsOneWidget);
      },
    );

    testWidgets('skipCheckIn=false gọi checkIn bình thường', (tester) async {
      await tester.pumpWidget(
        wrap(
          const InGameSessionPage(
            bookingId: 'test-booking',
            cafeName: 'Test Cafe',
            gameName: 'Test Game',
            tableNumber: 5,
            skipCheckIn: false,
          ),
        ),
      );

      // Loading xuất hiện trong lúc chờ checkIn.
      await tester.pump(const Duration(milliseconds: 50));

      // Sau khi checkIn xong → session view.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Bàn số 5'), findsOneWidget);
    });

    testWidgets(
      'cubit state ban đầu khi skipCheckIn=true emit InGameSessionActive',
      (tester) async {
        // Cubit được resolve từ BlocProvider cha (qua getIt factory).
        // Khi page mount với skipCheckIn=true → didChangeDependencies gọi
        // loadMockSession → state phải chuyển sang InGameSessionActive.
        // Verify bằng UI: nếu state là InGameInitial thì _buildBody trả
        // SizedBox.shrink() → text 'Bàn số' không xuất hiện → test fail.
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<InGameCubit>(
              create: (_) => getIt<InGameCubit>(),
              child: const InGameSessionPage(
                bookingId: 'test-booking',
                cafeName: 'Test Cafe',
                gameName: 'Test Game',
                tableNumber: 5,
                skipCheckIn: true,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));

        // State phải là InGameSessionActive → page render session view.
        // Đây là test quan trọng nhất — đảm bảo page KHÔNG bị trắng khi
        // skipCheckIn=true.
        expect(find.text('Bàn số 5'), findsOneWidget);
      },
    );
  });
}
