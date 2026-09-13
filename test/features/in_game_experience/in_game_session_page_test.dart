import 'package:dio/dio.dart';
import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/features/in_game_experience/data/datasources/player_session_remote_datasource.dart';
import 'package:boardverse/features/in_game_experience/data/models/player_session_model.dart';
import 'package:boardverse/features/in_game_experience/data/models/extend_session_model.dart';
import 'package:boardverse/features/in_game_experience/data/models/pay_session_model.dart';
import 'package:boardverse/features/in_game_experience/data/models/session_history_model.dart';
import 'package:boardverse/features/in_game_experience/data/models/split_bill_model.dart';
import 'package:boardverse/features/in_game_experience/data/in_game_repository_impl.dart';
import 'package:boardverse/features/in_game_experience/domain/repositories/in_game_repository.dart';
import 'package:boardverse/features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import 'package:boardverse/features/in_game_experience/presentation/pages/in_game_session_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple stub datasource for testing
class StubPlayerSessionRemoteDatasource implements PlayerSessionRemoteDatasource {
  @override
  final Dio dio;

  StubPlayerSessionRemoteDatasource() : dio = Dio();

  @override
  Future<PlayerSessionModel> getCurrentSession() async {
    throw PlayerSessionNotFoundException();
  }

  @override
  Future<ExtendSessionResponseModel> extendSession(int minutes) async {
    throw PlayerSessionNotFoundException();
  }

  @override
  Future<PaySessionResponseModel> paySession(String sessionId) async {
    throw PlayerSessionNotFoundException();
  }

  @override
  Future<SessionHistoryResponseModel> getSessionHistory({
    int limit = 20,
    DateTime? beforePaidAt,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    throw PlayerSessionNotFoundException();
  }

  @override
  Future<SplitBillSessionModel> getSplitBillSession() async {
    throw PlayerSessionNotFoundException(
        message: 'Không tìm thấy phiên chơi để chia bill.');
  }

  @override
  Future<MemberPaymentInfoModel> getMyMemberPaymentInfo() async {
    throw PlayerSessionNotFoundException(
        message: 'Không tìm thấy thông tin thanh toán của bạn.');
  }
}

void main() {
  group('InGameSessionPage', () {
    setUp(() {
      // Reset DI trước mỗi test để tránh state leak giữa các tests.
      if (sl.isRegistered<PlayerSessionRemoteDatasource>()) {
        sl.unregister<PlayerSessionRemoteDatasource>();
      }
      if (sl.isRegistered<InGameRepository>()) {
        sl.unregister<InGameRepository>();
      }
      if (sl.isRegistered<InGameCubit>()) {
        sl.unregister<InGameCubit>();
      }

      // Register stub datasource
      sl.registerLazySingleton<PlayerSessionRemoteDatasource>(
        () => StubPlayerSessionRemoteDatasource(),
      );
      sl.registerLazySingleton<InGameRepository>(
        () => InGameRepositoryImpl(
          playerSessionDatasource: sl<PlayerSessionRemoteDatasource>(),
        ),
      );
      sl.registerFactory<InGameCubit>(
        () => InGameCubit(repository: sl<InGameRepository>()),
      );
    });

    tearDown(() async {
      if (sl.isRegistered<PlayerSessionRemoteDatasource>()) {
        await sl.unregister<PlayerSessionRemoteDatasource>();
      }
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
        await tester.pumpWidget(
          wrap(
            const InGameSessionPage(
              bookingId: 'test-booking',
              cafeName: 'Test Cafe',
              gameName: 'Test Game',
              tableNumber: 5,
              skipCheckIn: true,
              useApiSession: true,
            ),
          ),
        );

        // Đợi cubit emit state mới.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 600));

        // Page phải render "Không có phiên chơi" thay vì trắng
        expect(find.text('Không có phiên chơi'), findsOneWidget);
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
            useApiSession: true,
          ),
        ),
      );

      // Loading xuất hiện trong lúc chờ checkIn.
      await tester.pump(const Duration(milliseconds: 50));

      // Stub datasource throw PlayerSessionNotFoundException → repository
      // checkIn() fallback về _createMockSession('test-booking') tạo ra
      // cafeName='Board Game Hub District 1' → page emit InGameSessionActive
      // → render _buildLegacySessionView (KHÔNG phải "Không có phiên chơi").
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Board Game Hub District 1'), findsOneWidget);
    });
  });
}
