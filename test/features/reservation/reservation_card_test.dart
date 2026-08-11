// Widget tests cho `ReservationCard` — card reservation theo neo-brutalism
// style hiển thị trong tab "Lịch đặt" của `BookingsPage`.
//
// Mục tiêu test:
// 1. Render đầy đủ thông tin: game name, cafe, time, slot, players, status.
// 2. Status label theo đúng variant (active/holding/terminal).
// 3. Sắp xếp active trước, mới nhất trước (verified trong test sắp xếp).

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/network/paginated_response.dart';
import 'package:boardverse_mobile/features/reservation/domain/entities/entities.dart';
import 'package:boardverse_mobile/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:boardverse_mobile/features/reservation/presentation/pages/reservation_list_page.dart';
import 'package:boardverse_mobile/features/reservation/presentation/widgets/reservation_card.dart';

class _StubReservationRepository implements ReservationRepository {
  Either<Failure, List<ReservationEntity>> reservationsResult =
      const Right(<ReservationEntity>[]);

  void stubReservations(List<ReservationEntity> data) {
    reservationsResult = Right(data);
  }

  void stubFailure(String message) {
    reservationsResult = Left(ServerFailure(message: message));
  }

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) async {
    return reservationsResult.fold(
      (l) => Left<Failure, PaginatedResponse<ReservationEntity>>(l),
      (r) => Right<Failure, PaginatedResponse<ReservationEntity>>(
        PaginatedResponse<ReservationEntity>(
          items: r,
          page: 1,
          pageSize: r.length,
          totalItems: r.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    );
  }

  // Unused stubs - chỉ cần implement để class không lỗi abstract.
  @override
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservation(
          String reservationId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservationDetail(
          String reservationId) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getPendingCafeApprovals({
    String? cafeId,
    DateTime? playDate,
    int page = 1,
    int pageSize = 20,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> cafeApproval({
    required String reservationId,
    required bool approve,
    String? reason,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));
}

ReservationEntity _makeReservation({
  String id = 'r1',
  String gameName = 'Catan',
  String cafeName = 'BoardGame Cafe A',
  ReservationStatus status = ReservationStatus.holding,
  LobbyStatus? lobbyStatus,
  DateTime? scheduledTime,
  int currentPlayers = 3,
  int maxPlayers = 6,
  int finalDeposit = 100000,
}) {
  final time = scheduledTime ?? DateTime.now().add(const Duration(days: 2));
  return ReservationEntity(
    id: id,
    hostId: 'host-1',
    cafeId: 'cafe-1',
    cafeName: cafeName,
    gameId: 'game-1',
    gameName: gameName,
    playDate: time,
    timeSlot: TimeSlot.evening,
    scheduledTime: time,
    recruitmentDeadline: time.subtract(const Duration(minutes: 20)),
    minPlayers: 4,
    maxPlayers: maxPlayers,
    depositRatePerPerson: 5,
    baseDeposit: 30,
    riskMultiplier: 1.0,
    minDepositApplied: 100000,
    finalDeposit: finalDeposit,
    status: status,
    currentPlayers: currentPlayers,
    lobbyStatus: lobbyStatus,
    requiresCafeApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('ReservationCard', () {
    testWidgets('render đầy đủ thông tin cho holding reservation',
        (tester) async {
      final r = _makeReservation();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(reservation: r),
          ),
        ),
      );

      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('BoardGame Cafe A'), findsOneWidget);
      // 3/6 người
      expect(find.text('3/6'), findsOneWidget);
      // Phiên tối
      expect(find.textContaining('Phiên tối'), findsOneWidget);
      // Cọc label
      expect(find.textContaining('100000 BVC'), findsOneWidget);
    });

    testWidgets('status "HOẠT ĐỘNG" xuất hiện khi reservation active',
        (tester) async {
      final r = _makeReservation(
        status: ReservationStatus.holding,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(reservation: r),
          ),
        ),
      );
      expect(find.text('HOẠT ĐỘNG'), findsOneWidget);
      expect(find.text('Đang giữ chỗ'), findsOneWidget);
    });

    testWidgets('status "Chờ quán duyệt" khi lobby pendingCafeApproval',
        (tester) async {
      final r = _makeReservation(
        status: ReservationStatus.holding,
        lobbyStatus: LobbyStatus.pendingCafeApproval,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(reservation: r),
          ),
        ),
      );
      expect(find.text('Chờ quán duyệt'), findsOneWidget);
    });

    testWidgets('KHÔNG hiển thị "HOẠT ĐỘNG" khi reservation terminal',
        (tester) async {
      final r = _makeReservation(
        status: ReservationStatus.cancelledByPlayer,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(reservation: r),
          ),
        ),
      );
      expect(find.text('HOẠT ĐỘNG'), findsNothing);
      expect(find.text('Hủy bởi người dùng'), findsOneWidget);
    });

    testWidgets('onTap callback được gọi khi tap card', (tester) async {
      var taps = 0;
      final r = _makeReservation();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: r,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ReservationCard));
      expect(taps, 1);
    });
  });

  group('ReservationListView — sắp xếp + state', () {
    /// Wrapper dùng trong test. `ReservationListPage` tự tạo BlocProvider,
    /// nhưng để test với stub repository phải đăng ký cubit qua GetIt
    /// (xem pattern của `friends_page_test.dart`).
    Future<void> pumpWithStub(
      WidgetTester tester,
      _StubReservationRepository repo,
    ) async {
      // ReservationListPage dùng sl<ReservationRepository>(), nên cần
      // đăng ký repo trong GetIt trước khi pump.
      final sl = GetIt.instance;
      if (sl.isRegistered<ReservationRepository>()) {
        await sl.unregister<ReservationRepository>();
      }
      sl.registerSingleton<ReservationRepository>(repo);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReservationListPage(),
          ),
        ),
      );
      // 2 pumps để cho phép async cubit load xong.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('active reservation hiển thị trước terminal', (tester) async {
      final repo = _StubReservationRepository();
      final completed = _makeReservation(
        id: 'r-old',
        gameName: 'OldGame',
        scheduledTime: DateTime.now().subtract(const Duration(days: 5)),
        status: ReservationStatus.completed,
      );
      final active = _makeReservation(
        id: 'r-new',
        gameName: 'NewGame',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        status: ReservationStatus.holding,
      );
      // Thứ tự đầu vào: completed trước, active sau.
      repo.stubReservations([completed, active]);

      await pumpWithStub(tester, repo);

      // Active phải xuất hiện trước completed trong DOM.
      final inactiveIdx = tester.getTopLeft(find.text('OldGame')).dy;
      final activeIdx = tester.getTopLeft(find.text('NewGame')).dy;
      expect(activeIdx < inactiveIdx, isTrue,
          reason: 'Active reservation phải hiển thị trước terminal');
    });

    testWidgets('render empty state khi không có reservation', (tester) async {
      final repo = _StubReservationRepository();
      repo.stubReservations(const []);

      await pumpWithStub(tester, repo);

      expect(find.textContaining('Bạn chưa tạo đơn reservation nào'),
          findsOneWidget);
    });

    testWidgets('render error state với retry button khi API fail',
        (tester) async {
      final repo = _StubReservationRepository();
      repo.stubFailure('Lỗi mạng');

      await pumpWithStub(tester, repo);

      expect(find.text('Lỗi mạng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}