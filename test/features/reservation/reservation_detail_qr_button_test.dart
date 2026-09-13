// Widget tests cho QR Check-in button + "Vào phòng chờ" button trong
// `ReservationDetailPage` (BR §21A.7 + BR §5.3).
//
// Mục tiêu test:
// 1. Reservation chưa check-in + chưa terminal → hiển thị button
//    "Quét QR check-in".
// 2. Reservation đã check-in → KHÔNG hiển thị button QR (hiển thị
//    "Phiên chơi của tôi" + "Vào phòng chờ").
// 3. Reservation terminal (cancelled/completed/...) → KHÔNG hiển thị.
// 4. Lobby tồn tại + viewable → hiển thị "Vào phòng chờ" (kể cả khi đã
//    check-in, vẫn cho phép navigate về lobby).
// 5. Lobby terminal (closed/timeoutFailed/dissolved/...) → KHÔNG hiển thị
//    button "Vào phòng chờ".
//
// Sử dụng mocktail (transitive dep) để stub các repository.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/lobby_management/domain/repositories/lobby_repository.dart';
import 'package:boardverse/features/reservation/domain/entities/entities.dart';
import 'package:boardverse/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:boardverse/features/reservation/presentation/cubit/reservation_detail_cubit.dart';
import 'package:boardverse/features/reservation/presentation/pages/reservation_detail_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockReservationRepository extends Mock
    implements ReservationRepository {}

class _MockLobbyRepository extends Mock implements LobbyRepository {}

void main() {
  late _MockReservationRepository reservationRepo;
  late _MockLobbyRepository lobbyRepo;

  setUpAll(() async {
    // Khởi tạo intl locale data cho DateFormat trong _TimeCard (dùng 'vi').
    await initializeDateFormatting('vi');
  });

  setUp(() {
    reservationRepo = _MockReservationRepository();
    lobbyRepo = _MockLobbyRepository();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ReservationRepository>()) {
      getIt.unregister<ReservationRepository>();
    }
    if (getIt.isRegistered<LobbyRepository>()) {
      getIt.unregister<LobbyRepository>();
    }
    if (getIt.isRegistered<ReservationDetailCubit>()) {
      getIt.unregister<ReservationDetailCubit>();
    }
    getIt.registerFactory<ReservationRepository>(() => reservationRepo);
    getIt.registerFactory<LobbyRepository>(() => lobbyRepo);
  });
  group('ReservationDetailPage — QR Check-in button', () {
    /// Reservation mặc định — chưa check-in, status confirmed (active).
    ReservationEntity buildReservation({
      ReservationStatus status = ReservationStatus.confirmed,
      DateTime? checkedInAt,
      String? lobbyId,
      LobbyStatus? lobbyStatus,
    }) {
      final now = DateTime.now();
      return ReservationEntity(
        id: 'res-1',
        hostId: 'host-1',
        cafeId: 'cafe-1',
        cafeName: 'BoardVerse Cafe',
        gameId: 'game-1',
        gameName: 'Catan',
        playDate: now.add(const Duration(days: 1)),
        timeSlot: TimeSlot.evening,
        scheduledTime: now.add(const Duration(days: 1, hours: 2)),
        minPlayers: 2,
        maxPlayers: 4,
        finalDeposit: 50000,
        status: status,
        currentPlayers: 2,
        lobbyId: lobbyId,
        lobbyStatus: lobbyStatus,
        createdAt: now,
        canCancel: true,
        checkedInAt: checkedInAt,
      );
    }

    /// Pump page với cubit được tạo từ GetIt (đã stub ở setUp).
    Future<void> pumpPageWithStubCubit(
      WidgetTester tester,
      ReservationEntity reservation,
    ) async {
      when(
        () => reservationRepo.getReservation(any()),
      ).thenAnswer((_) async => Right(reservation));
      when(() => lobbyRepo.getLobbyById(any())).thenAnswer(
        (_) async => const Left(NotFoundFailure(message: 'not found')),
      );

      // Set large surface size để ListView có đủ không gian hiển thị tất cả
      // buttons mà không cần scroll.
      await tester.binding.setSurfaceSize(const Size(800, 2000));

      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailPage(reservation: reservation),
        ),
      );
      // Pump 2 lần để cubit fetch + lobby enrich complete.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'Reservation confirmed (chưa check-in) → hiển thị button "Quét QR check-in"',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.confirmed,
          checkedInAt: null,
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Quét QR check-in'), findsOneWidget);
      },
    );

    testWidgets(
      'Reservation holding (chưa xác nhận) → VẪN hiển thị button QR',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.holding,
          checkedInAt: null,
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Quét QR check-in'), findsOneWidget);
      },
    );

    testWidgets(
      'Reservation đã check-in → KHÔNG hiển thị button QR (hiển thị "Phiên chơi của tôi")',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.checkedIn,
          checkedInAt: DateTime.now(),
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Phiên chơi của tôi'),
          find.byType(ListView),
          const Offset(0, -300),
        );

        expect(find.text('Phiên chơi của tôi'), findsOneWidget);
        expect(find.text('Quét QR check-in'), findsNothing);
      },
    );

    testWidgets(
      'Reservation terminal (cancelledByPlayer) → KHÔNG hiển thị button QR',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.cancelledByPlayer,
          checkedInAt: null,
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          find.byType(ListView),
          const Offset(0, -300),
        );

        expect(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          findsOneWidget,
        );
        expect(find.text('Quét QR check-in'), findsNothing);
      },
    );

    testWidgets(
      'Reservation terminal (completed) → KHÔNG hiển thị button QR',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.completed,
          checkedInAt: null,
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          find.byType(ListView),
          const Offset(0, -300),
        );

        expect(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          findsOneWidget,
        );
        expect(find.text('Quét QR check-in'), findsNothing);
      },
    );

    testWidgets(
      'Reservation terminal (expired) → KHÔNG hiển thị button QR',
      (tester) async {
        final reservation = buildReservation(
          status: ReservationStatus.expired,
          checkedInAt: null,
        );

        await pumpPageWithStubCubit(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          find.byType(ListView),
          const Offset(0, -300),
        );

        expect(
          find.text('Đơn đặt chỗ này đã kết thúc'),
          findsOneWidget,
        );
        expect(find.text('Quét QR check-in'), findsNothing);
      },
    );
  });

  group('ReservationDetailPage — "Vào phòng chờ" button', () {
    ReservationEntity buildReservation({
      required LobbyStatus lobbyStatus,
      DateTime? checkedInAt,
      ReservationStatus status = ReservationStatus.confirmed,
    }) {
      final now = DateTime.now();
      return ReservationEntity(
        id: 'res-1',
        hostId: 'host-1',
        cafeId: 'cafe-1',
        cafeName: 'BoardVerse Cafe',
        gameId: 'game-1',
        gameName: 'Catan',
        playDate: now.add(const Duration(days: 1)),
        timeSlot: TimeSlot.evening,
        scheduledTime: now.add(const Duration(days: 1, hours: 2)),
        minPlayers: 2,
        maxPlayers: 4,
        finalDeposit: 50000,
        status: status,
        currentPlayers: 2,
        lobbyId: 'lobby-12345678',
        lobbyStatus: lobbyStatus,
        createdAt: now,
        canCancel: true,
        checkedInAt: checkedInAt,
      );
    }

    Future<void> pumpPage(
      WidgetTester tester,
      ReservationEntity reservation,
    ) async {
      when(
        () => reservationRepo.getReservation(any()),
      ).thenAnswer((_) async => Right(reservation));
      when(() => lobbyRepo.getLobbyById(any())).thenAnswer(
        (_) async => const Left(NotFoundFailure(message: 'not found')),
      );

      await tester.binding.setSurfaceSize(const Size(800, 2200));
      await tester.pumpWidget(
        MaterialApp(
          home: ReservationDetailPage(reservation: reservation),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'Lobby open + chưa check-in → hiển thị CẢ "Quét QR check-in" và "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.open,
          checkedInAt: null,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Quét QR check-in'), findsOneWidget);
        expect(find.text('Vào phòng chờ'), findsOneWidget);
      },
    );

    testWidgets(
      'Lobby inProgress + đã check-in → KHÔNG hiển thị QR, hiển thị CẢ "Phiên chơi của tôi" VÀ "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.inProgress,
          checkedInAt: DateTime.now(),
          status: ReservationStatus.checkedIn,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Phiên chơi của tôi'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Phiên chơi của tôi'), findsOneWidget);
        expect(find.text('Vào phòng chờ'), findsOneWidget);
        expect(find.text('Quét QR check-in'), findsNothing);
      },
    );

    testWidgets(
      'Lobby closed (terminal) → KHÔNG hiển thị "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.closed,
        );
        await pumpPage(tester, reservation);

        // Vẫn còn "Quét QR check-in" vì reservation chưa terminal.
        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Quét QR check-in'), findsOneWidget);
        expect(find.text('Vào phòng chờ'), findsNothing);
      },
    );

    testWidgets(
      'Lobby timeoutFailed (terminal) → KHÔNG hiển thị "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.timeoutFailed,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Quét QR check-in'), findsOneWidget);
        expect(find.text('Vào phòng chờ'), findsNothing);
      },
    );

    testWidgets(
      'Lobby dissolved (terminal) → KHÔNG hiển thị "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.dissolved,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Vào phòng chờ'), findsNothing);
      },
    );

    testWidgets(
      'Lobby rejectedByCafe (terminal) → KHÔNG hiển thị "Vào phòng chờ"',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.rejectedByCafe,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Vào phòng chờ'), findsNothing);
      },
    );

    testWidgets(
      'Lobby pendingCafeApproval → KHÔNG hiển thị "Vào phòng chờ" (handled riêng qua PendingCafeApprovalPage)',
      (tester) async {
        final reservation = buildReservation(
          lobbyStatus: LobbyStatus.pendingCafeApproval,
        );
        await pumpPage(tester, reservation);

        await tester.dragUntilVisible(
          find.text('Quét QR check-in'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        // Trạng thái pendingCafeApproval không phải terminal → KHÔNG show
        // "Vào phòng chờ" (vì sẽ dùng PendingCafeApprovalPage riêng — không
        // thuộc phạm vi của button này).
        expect(find.text('Vào phòng chờ'), findsNothing);
      },
    );
  });
}
