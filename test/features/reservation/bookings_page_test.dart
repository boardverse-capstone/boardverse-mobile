// Widget tests cho `BookingsPage`.
//
// Sau khi bỏ tab "Phòng chờ" (Aug 2026), `BookingsPage` chỉ render
// `ReservationSearchPanel` trực tiếp — không còn tab bar. Phòng chờ
// đã được dời sang `LobbiesPage` và có thể truy cập từ
// `ReservationDetailPage`.
//
// Mục tiêu test:
//   - Page title "LỊCH ĐẶT" hiển thị.
//   - Không còn tab bar.
//   - Reservation list render qua `ReservationSearchPanel`.
//   - Search bar + filter chips hoạt động.
//   - Empty state khi không có reservation.

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/network/paginated_response.dart';
import 'package:boardverse/core/navigation/pages/bookings_page.dart';
import 'package:boardverse/features/reservation/domain/entities/reservation_entity.dart'
    hide LobbyStatus;
import 'package:boardverse/features/reservation/domain/entities/reservation_quote_entity.dart';
import 'package:boardverse/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:boardverse/features/reservation/presentation/widgets/my_reservations_panel.dart';
import 'package:boardverse/features/reservation/presentation/widgets/reservation_card_skeleton.dart';

class _StubReservationRepository implements ReservationRepository {
  Either<Failure, List<ReservationEntity>> reservationsResult = const Right(
    <ReservationEntity>[],
  );

  /// Per-participation response — nếu set sẽ override `reservationsResult`
  /// cho Host vs Member (dùng để test khác biệt giữa 2 tab).
  Map<ReservationParticipationType, List<ReservationEntity>>? responsesByType;

  /// Completer cho response hiện tại — nếu set, stub sẽ block tới khi
  /// `completeWith(...)` được gọi. Cho phép test quan sát trạng thái
  /// `MyReservationsLoading` (skeleton) trước khi API "trả về".
  Completer<Either<Failure, MyReservationsResult>>? myReservationsGate;

  void stubReservations(List<ReservationEntity> data) {
    reservationsResult = Right(data);
  }

  /// Block lần `getMyReservations` tiếp theo cho tới khi gọi
  /// `completeMyReservations(...)` với kết quả mong muốn.
  void gateNextMyReservationsCall() {
    myReservationsGate = Completer<Either<Failure, MyReservationsResult>>();
  }

  void completeMyReservations(Either<Failure, MyReservationsResult> result) {
    myReservationsGate?.complete(result);
    myReservationsGate = null;
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

  /// Search dùng cùng stub data — chỉ cần implement để class không abstract.
  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
  searchReservations({
    String? gameName,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? statuses,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) =>
      getReservations(
        statuses: statuses,
        cafeId: cafeId,
        hostedByMe: hostedByMe,
        joinedByMe: joinedByMe,
        page: page,
        pageSize: pageSize,
      );

  // Unused stubs.
  @override
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  }) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  }) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservation(
    String reservationId,
  ) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationEntity>> getReservationDetail(
    String reservationId,
  ) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
  getPendingCafeApprovals({
    String? cafeId,
    DateTime? playDate,
    int page = 1,
    int pageSize = 20,
  }) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, void>> cafeApproval({
    required String reservationId,
    required bool approve,
    String? reason,
  }) async => const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ReservationCancelAfterCheckinResult>>
      cancelAfterCheckin({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, ExtendAvailabilityResult>> checkExtendAvailability({
    required String reservationId,
    required int extensionMinutes,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, CheckInByCodeResult>> checkInByCode({
    required String reservationCode,
    required String cafeId,
    required String activeSessionId,
    required String idempotencyKey,
  }) async =>
      const Left(NotFoundFailure(message: 'Not implemented'));

  @override
  Future<Either<Failure, MyReservationsResult>> getMyReservations({
    ReservationParticipationType? participationType,
    List<String>? statuses,
    String? cafeId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    // Nếu có gate → block cho tới khi test complete.
    if (myReservationsGate != null) {
      await myReservationsGate!.future;
    }

    // Nếu có response riêng theo participationType → dùng nó.
    final items = (participationType != null &&
            responsesByType != null &&
            responsesByType!.containsKey(participationType))
        ? responsesByType![participationType]!
        : reservationsResult.getOrElse(() => const <ReservationEntity>[]);

    return Right<Failure, MyReservationsResult>(
      MyReservationsResult(
        paginated: PaginatedResponse<ReservationEntity>(
          items: items,
          page: 1,
          pageSize: items.length,
          totalItems: items.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
        hostedCount: items.length,
        joinedCount: 0,
      ),
    );
  }
}

ReservationEntity _makeReservation({
  String id = 'r1',
  String gameName = 'Catan',
  ReservationStatus status = ReservationStatus.holding,
}) {
  final time = DateTime.now().add(const Duration(days: 2));
  return ReservationEntity(
    id: id,
    hostId: 'host-1',
    cafeId: 'cafe-1',
    cafeName: 'BoardGame Cafe',
    gameId: 'game-1',
    gameName: gameName,
    playDate: time,
    timeSlot: TimeSlot.evening,
    scheduledTime: time,
    recruitmentDeadline: time.subtract(const Duration(minutes: 20)),
    minPlayers: 4,
    maxPlayers: 6,
    depositRatePerPerson: 5,
    baseDeposit: 30,
    riskMultiplier: 1.0,
    minDepositApplied: 100000,
    finalDeposit: 100000,
    status: status,
    currentPlayers: 3,
    lobbyId: 'lobby-1',
    lobbyStatus: null,
    requiresCafeApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late _StubReservationRepository reservationRepo;

  setUp(() async {
    reservationRepo = _StubReservationRepository();

    final sl = GetIt.instance;
    if (sl.isRegistered<ReservationRepository>()) {
      await sl.unregister<ReservationRepository>();
    }
    sl.registerSingleton<ReservationRepository>(reservationRepo);
  });

  tearDown(() async {
    final sl = GetIt.instance;
    if (sl.isRegistered<ReservationRepository>()) {
      await sl.unregister<ReservationRepository>();
    }
  });

  Widget wrap() {
    return MaterialApp(
      home: Scaffold(
        body: const BookingsPage(),
      ),
    );
  }

  group('BookingsPage — single-page layout', () {
    testWidgets('hiển thị page title "LỊCH ĐẶT"', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(
        find.text('LỊCH ĐẶT'),
        findsOneWidget,
        reason: 'Page title "LỊCH ĐẶT" phải hiển thị',
      );
    });

    testWidgets('KHÔNG còn tab bar (đã bỏ tab Phòng chờ)', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      // Không còn widget Tab nào trong tree.
      expect(find.byType(Tab), findsNothing);
      // Không còn text "Phòng chờ" trong header.
      expect(find.text('Phòng chờ'), findsNothing);
    });

    testWidgets('render reservation list ngay khi mount', (tester) async {
      reservationRepo.stubReservations([
        _makeReservation(gameName: 'Wingspan'),
      ]);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Wingspan'),
        findsOneWidget,
        reason: 'Reservation phải render ở page LỊCH ĐẶT',
      );
    });

    testWidgets('hiển thị tab strip Chủ phòng / Thành viên', (tester) async {
      reservationRepo.stubReservations([
        _makeReservation(gameName: 'Wingspan'),
      ]);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab labels (uppercase, bold) — phân biệt Host vs Member bằng màu.
      expect(find.text('CHỦ PHÒNG'), findsOneWidget,
          reason: 'Phải có tab "CHỦ PHÒNG"');
      expect(find.text('THÀNH VIÊN'), findsOneWidget,
          reason: 'Phải có tab "THÀNH VIÊN"');
      // Filter chips — chỉ còn status/date (search theo tên game đã được
        // dời sang trang Search riêng).
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Từ ngày'), findsOneWidget);
      expect(find.text('Đến ngày'), findsOneWidget);
    });

    testWidgets('hiển thị empty state "Chưa có lịch hẹn do bạn tạo" khi không có reservation',
        (tester) async {
      reservationRepo.stubReservations(const []);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MyReservationsPanel dùng empty state khác (Host-specific).
      expect(
        find.textContaining('CHƯA CÓ LỊCH HẸN DO BẠN TẠO'),
        findsOneWidget,
      );
    });

    testWidgets(
        'chỉ hiển thị tab CHỦ PHÒNG và THÀNH VIÊN mà không có count badge',
        (tester) async {
      reservationRepo.stubReservations([
        _makeReservation(id: 'r1', gameName: 'Wingspan'),
        _makeReservation(id: 'r2', gameName: 'Splendor'),
      ]);

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tab strip vẫn render cả 2 label — không có count number riêng.
      expect(find.text('CHỦ PHÒNG'), findsOneWidget);
      expect(find.text('THÀNH VIÊN'), findsOneWidget);
    });

    testWidgets(
        'chuyển tab sang THÀNH VIÊN → hiển thị shimmer skeleton ngay lập tức, '
        'không hiển thị items của tab cũ trong lúc chờ API',
        (tester) async {
      // Stub: tab Host trả về 1 reservation, tab Member sẽ bị gate (block).
      reservationRepo.responsesByType = {
        ReservationParticipationType.host: [
          _makeReservation(id: 'r-host', gameName: 'Wingspan'),
        ],
        ReservationParticipationType.member: const [],
      };

      await tester.pumpWidget(wrap());
      // Pump cho tới khi panel render xong Host list.
      await tester.pump(const Duration(milliseconds: 100));

      // Sanity: Host tab đang hiển thị reservation "Wingspan".
      expect(find.text('Wingspan'), findsOneWidget,
          reason: 'Initial state phải hiển thị Host reservation');

      // Gate response cho tab Member để quan sát Loading state.
      reservationRepo.gateNextMyReservationsCall();

      // Bấm sang tab THÀNH VIÊN.
      await tester.tap(find.text('THÀNH VIÊN'));
      // Pump 1 frame để xử lý tap + emit Loading state.
      await tester.pump();

      // Sau khi switch tab, panel KHÔNG được show items của Host cũ
      // mà phải hiển thị shimmer skeleton (`ReservationCardSkeleton`).
      expect(
        find.text('Wingspan'),
        findsNothing,
        reason: 'Không được render items của tab cũ khi đang chờ API tab mới',
      );
      expect(
        find.byType(ReservationCardSkeleton),
        findsWidgets,
        reason: 'Phải hiển thị shimmer skeleton ngay khi switch tab',
      );

      // Complete response cho Member → empty list → empty state.
      reservationRepo.completeMyReservations(
        const Right<Failure, MyReservationsResult>(
          MyReservationsResult(
            paginated: PaginatedResponse<ReservationEntity>(
              items: <ReservationEntity>[],
              page: 1,
              pageSize: 0,
              totalItems: 0,
              totalPages: 1,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
            hostedCount: 1,
            joinedCount: 0,
          ),
        ),
      );

      // Pump cho tới khi API resolve + AnimatedSwitcher fade xong.
      // Dùng `pumpAndSettle` để chờ fade-out skeleton hoàn tất (220ms).
      await tester.pumpAndSettle();

      // Sau khi API trả về: skeleton biến mất, Member empty state hiện ra.
      expect(
        find.byType(ReservationCardSkeleton),
        findsNothing,
        reason: 'Skeleton phải biến mất sau khi API resolve',
      );
      expect(
        find.textContaining('CHƯA THAM GIA LỊCH HẸN NÀO'),
        findsOneWidget,
        reason: 'Empty state cho tab Member phải hiển thị sau khi load xong',
      );
    });

    testWidgets(
        'tab indicator highlight chuyển sang tab mới ngay khi tap, '
        'không cần đợi API trả về',
        (tester) async {
      reservationRepo.responsesByType = {
        ReservationParticipationType.host: [
          _makeReservation(id: 'r-host', gameName: 'Wingspan'),
        ],
        ReservationParticipationType.member: const [],
      };

      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(milliseconds: 100));

      // Gate response để cubit stuck ở Loading.
      reservationRepo.gateNextMyReservationsCall();

      // Trước khi tap: tab CHỦ PHÒNG phải đang active (màu cam).
      // Tìm widget RoleTab và kiểm tra isActive của nó.
      final roleTabsBefore = tester
          .widgetList<RoleTab>(find.byType(RoleTab))
          .toList();
      expect(roleTabsBefore.length, 2);
      final hostTabBefore = roleTabsBefore.firstWhere(
        (t) => t.type == ReservationParticipationType.host,
      );
      final memberTabBefore = roleTabsBefore.firstWhere(
        (t) => t.type == ReservationParticipationType.member,
      );
      expect(hostTabBefore.isActive, isTrue,
          reason: 'Tab Host đang active ban đầu');
      expect(memberTabBefore.isActive, isFalse);

      // Tap sang Member.
      await tester.tap(find.text('THÀNH VIÊN'));
      await tester.pump();

      // Sau khi tap: dù API chưa trả về, tab Member đã phải active.
      final roleTabsAfter = tester
          .widgetList<RoleTab>(find.byType(RoleTab))
          .toList();
      final hostTabAfter = roleTabsAfter.firstWhere(
        (t) => t.type == ReservationParticipationType.host,
      );
      final memberTabAfter = roleTabsAfter.firstWhere(
        (t) => t.type == ReservationParticipationType.member,
      );
      expect(memberTabAfter.isActive, isTrue,
          reason:
              'Tab Member phải active NGAY khi tap, không đợi API trả về');
      expect(hostTabAfter.isActive, isFalse,
          reason: 'Tab Host phải mất active khi tap sang Member');

      // Cleanup: complete gate để test kết thúc sạch.
      reservationRepo.completeMyReservations(
        const Right<Failure, MyReservationsResult>(
          MyReservationsResult(
            paginated: PaginatedResponse<ReservationEntity>(
              items: <ReservationEntity>[],
              page: 1,
              pageSize: 0,
              totalItems: 0,
              totalPages: 1,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
            hostedCount: 1,
            joinedCount: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}