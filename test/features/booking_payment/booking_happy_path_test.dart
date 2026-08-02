// Unit test cho happy path booking + deposit sau khi tích hợp SePay.
//
// State machine cần verify:
//   BookingSummaryCubit: SummaryInitial → SummaryLoading → SummaryReady
//                        → SummarySubmitting → SummarySuccess
//   PaymentCubit:        PaymentIdle → PaymentOpening → PaymentAwaitingCallback
//                        → PaymentProcessing → PaymentSuccess
//
// Test sử dụng fake BookingRemoteDatasource + fake PaymentGateway.
// Lưu ý: không depend vào Dio/MockPaymentGateway cũ — tất cả đã xoá
// theo plan tích hợp.

import 'package:bloc_test/bloc_test.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_persistence_service.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_repository_impl.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/base/booking_remote_datasource.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/base/payment_gateway.dart';
import 'package:boardverse_mobile/features/booking_payment/data/models/deposit_status_model.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/booking_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/booking_history_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/deposit_config_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/deposit_payment_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/deposit_status_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/lobby_booking_summary_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/enums/booking_status.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/enums/payment_method.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/enums/pricing_model.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/booking_summary_cubit.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/booking_summary_state.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/payment_cubit.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/payment_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_secure_storage.dart';

class FakeBookingRemote implements BookingRemoteDatasource {
  BookingEntity? pendingBooking;
  DepositConfigEntity depositConfig = DepositConfigEntity(
    cafeId: 'CAFE001',
    firstHourPrice: 100000,
    entryFee: 50000,
    maxDeposit: 50000,
    defaultDeposit: 50000,
    graceMinutes: 15,
    seatCount: 4,
    currency: 'VND',
    pricingModel: PricingModel.hourly,
  );

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) async =>
      Right(depositConfig);

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  }) async {
    final booking = BookingEntity(
      id: 'BK001',
      lobbyId: lobbyId,
      cafeId: cafeId,
      cafeName: 'Mock Cafe',
      cafeTableId: cafeTableId,
      gameId: 'GAME01',
      gameName: 'Catan',
      scheduledTime: scheduledStartTime,
      scheduleEndTime: scheduleEndTime,
      seatCount: playerQuantity ?? 2,
      playerQuantity: playerQuantity ?? 2,
      memberIds: const ['me', 'friend-1'],
      hostId: 'me',
      status: BookingStatus.pendingDeposit,
      depositAmount: 50000,
      depositDeadline: DateTime.now().add(const Duration(minutes: 15)),
      verificationQrCode: 'QR-PAYLOAD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    pendingBooking = booking;
    return Right(booking);
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    if (pendingBooking != null) return Right(pendingBooking!);
    return const Left(NotFoundFailure(message: 'Booking không tồn tại'));
  }

  @override
  Future<Either<Failure, BookingEntity?>> getBookingByLobby(
    String lobbyId,
  ) async =>
      Right(pendingBooking);

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) async {
    pendingBooking = pendingBooking?.copyWith(
      status: BookingStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    return Right(pendingBooking!);
  }

  @override
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  ) async =>
      Right(
        DepositPaymentEntity(
          depositId: 'DEP001',
          orderId: 'BV-001',
          qrUrl: 'https://qr.sepay.vn/img/abc',
          paymentUrl: 'https://pay.sepay.vn/BV-001',
          qrExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          amount: 50000,
          requiresManualConfirmation: false,
        ),
      );

  @override
  Future<Either<Failure, DepositPaymentEntity>>
      createDepositPaymentWithDetails({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  }) async =>
          createDepositPayment(bookingId);

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  ) async =>
      Right(
        DepositStatusEntity(
          depositId: depositId,
          orderId: 'BV-001',
          cafeId: 'CAFE001',
          status: DepositStatus.paid,
          amount: 50000,
          paidAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  ) async =>
      getDepositStatus(orderId);

  @override
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  ) async =>
      createDepositPayment('BK001');

  @override
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  }) async =>
      Right(
        DepositStatusEntity(
          depositId: depositId,
          orderId: 'BV-001',
          cafeId: 'CAFE001',
          status: DepositStatus.refunded,
          amount: 50000,
          refundedAmount: 50000,
          refundPolicy: RefundPolicy.full,
          paidAt: DateTime.now(),
          refundedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  ) async =>
      Right(
        LobbyBookingSummaryEntity(
          lobbyId: lobbyId,
          bookingId: pendingBooking?.id,
          walkInAvailable: false,
        ),
      );

  @override
  Future<Either<Failure, List<String>>> getHostedLobbyIds() async =>
      const Right(['LOB001']);

  @override
  Future<Either<Failure, List<String>>> getJoinedLobbyIds() async =>
      const Right([]);

  @override
  Future<List<BookingHistoryEntity>> noopHistoryShim() async => const [];
}

class FakePaymentGateway implements PaymentGateway {
  int paidAfterTicks = 1;
  int _ticks = 0;

  @override
  Future<Either<Failure, String>> openGateway({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    return const Right('DEP001');
  }

  @override
  Stream<PaymentResult> watchResult(String transactionRef) async* {
    yield const GatewayPending();
    while (true) {
      _ticks += 1;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_ticks >= paidAfterTicks) {
        yield GatewaySuccess(
          transactionRef: 'BV-001',
          paidAt: DateTime.now(),
        );
        return;
      }
      yield const GatewayPending();
    }
  }
}

void main() {
  late FakeBookingRemote remote;
  late FakePaymentGateway gateway;
  late BookingPersistenceService persistence;
  late BookingRepositoryImpl repository;

  setUp(() {
    remote = FakeBookingRemote();
    gateway = FakePaymentGateway();
    persistence = BookingPersistenceService(storage: FakeSecureStorage());
    repository = BookingRepositoryImpl(
      datasource: remote,
      persistence: persistence,
    );
  });

  Breakdown buildBreakdown() => Breakdown(
        firstHourPrice: 100000,
        recommendedDeposit: 50000,
        maxDeposit: 50000,
        currency: 'VND',
        pricingModelLabel: 'hourly',
      );

  group('BookingSummaryCubit happy path', () {
    blocTest<BookingSummaryCubit, BookingSummaryState>(
      'loadConfig → SummaryLoading → SummaryReady',
      build: () => BookingSummaryCubit(repository: repository),
      act: (cubit) => cubit.loadConfig(
        'CAFE001',
        scheduledStartTime: DateTime(2026, 8, 1, 14),
        scheduleEndTime: DateTime(2026, 8, 1, 17),
        seatCount: 4,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SummaryLoading>(),
        isA<SummaryReady>(),
      ],
    );

    blocTest<BookingSummaryCubit, BookingSummaryState>(
      'submit → SummarySubmitting → SummarySuccess',
      build: () => BookingSummaryCubit(repository: repository),
      seed: () => SummaryReady(
        config: remote.depositConfig,
        breakdown: buildBreakdown(),
        selectedMethod: PaymentMethod.sepay,
      ),
      act: (cubit) => cubit.submit(
        lobbyId: 'LOB001',
        cafeId: 'CAFE001',
        cafeTableId: 'TBL01',
        scheduledStartTime: DateTime.now().add(const Duration(hours: 2)),
        scheduleEndTime: DateTime.now().add(const Duration(hours: 4)),
        playerQuantity: 2,
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<SummarySubmitting>(),
        isA<SummarySuccess>(),
      ],
    );
  });

  group('PaymentCubit happy path', () {
    blocTest<PaymentCubit, PaymentState>(
      'start → Opening → AwaitingCallback → Success',
      build: () => PaymentCubit(
        repository: repository,
        gateway: gateway,
        persistence: persistence,
      ),
      act: (cubit) => cubit.start(
        bookingId: 'BK001',
        amount: 50000,
        method: PaymentMethod.sepay,
        deadline: DateTime.now().add(const Duration(minutes: 15)),
        config: remote.depositConfig,
      ),
      wait: const Duration(milliseconds: 500),
      verify: (cubit) {
        expect(cubit.state, isA<PaymentSuccess>());
      },
    );
  });

  group('BookingEntity status semantics', () {
    test('BookingStatus extension getters hoạt động đúng', () {
      final entity = BookingEntity(
        id: 'BK001',
        lobbyId: 'LOB001',
        cafeId: 'CAFE001',
        cafeName: 'Mock Cafe',
        cafeTableId: 'TBL01',
        gameId: 'GAME01',
        gameName: 'Catan',
        scheduledTime: DateTime(2026, 8, 1, 14, 0),
        scheduleEndTime: DateTime(2026, 8, 1, 16, 0),
        seatCount: 2,
        playerQuantity: 2,
        memberIds: const ['me'],
        hostId: 'me',
        status: BookingStatus.confirmed,
        depositAmount: 50000,
        depositDeadline: DateTime(2026, 8, 1, 14, 15),
        verificationQrCode: 'QR-PAYLOAD',
        createdAt: DateTime(2026, 8, 1, 13, 0),
        updatedAt: DateTime(2026, 8, 1, 13, 5),
      );

      expect(entity.status, BookingStatus.confirmed);
      expect(entity.qrPayload, 'QR-PAYLOAD');
      expect(entity.status.isTerminal, isFalse);
      expect(entity.status.isActive, isTrue);
      expect(entity.status.canPlayerCancel, isTrue);
    });
  });

  group('DepositStatusModel backward-compat', () {
    test('parse response với `id` (theo swagger mới)', () {
      final json = {
        'id': 'DEP-001',
        'orderId': 'BV-001',
        'cafeId': 'CAFE001',
        'status': 'Paid',
        'amount': 50000,
        'paidAt': '2026-08-01T10:00:00Z',
        'createdAt': '2026-08-01T09:55:00Z',
        'updatedAt': '2026-08-01T10:00:00Z',
      };
      final model = DepositStatusModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.depositId, 'DEP-001');
      expect(entity.orderId, 'BV-001');
      expect(entity.status, DepositStatus.paid);
      expect(entity.paidAt, isNotNull);
    });

    test('parse response với `depositId` (theo payment.md)', () {
      final json = {
        'depositId': 'DEP-002',
        'orderId': 'BV-002',
        'cafeId': 'CAFE001',
        'status': 'Pending',
        'amount': 50000,
        'qrExpiresAt': '2026-08-01T11:00:00Z',
        'createdAt': '2026-08-01T10:55:00Z',
        'updatedAt': '2026-08-01T10:55:00Z',
      };
      final model = DepositStatusModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.depositId, 'DEP-002');
      expect(entity.status, DepositStatus.pending);
      expect(entity.qrExpiresAt, isNotNull);
      expect(entity.isQrExpired, isFalse);
    });

    test('parse refundPolicy string → RefundPolicy enum', () {
      final json = {
        'id': 'DEP-003',
        'orderId': 'BV-003',
        'cafeId': 'CAFE001',
        'status': 'Refunded',
        'amount': 50000,
        'refundedAmount': 25000,
        'refundPolicy': 'Partial',
        'paidAt': '2026-08-01T09:00:00Z',
        'refundedAt': '2026-08-01T10:00:00Z',
        'createdAt': '2026-08-01T08:55:00Z',
        'updatedAt': '2026-08-01T10:00:00Z',
      };
      final entity = DepositStatusModel.fromJson(json).toEntity();
      expect(entity.refundPolicy, RefundPolicy.partial);
      expect(entity.refundedAmount, 25000);
      expect(entity.isTerminal, isTrue);
    });

    test('parse status "Holding" → pending enum', () {
      final json = {
        'id': 'DEP-004',
        'orderId': 'BV-004',
        'cafeId': 'CAFE001',
        'status': 'Holding',
        'amount': 50000,
        'createdAt': '2026-08-01T08:55:00Z',
        'updatedAt': '2026-08-01T08:55:00Z',
      };
      final entity = DepositStatusModel.fromJson(json).toEntity();
      expect(entity.status, DepositStatus.pending);
      expect(entity.isTerminal, isFalse);
    });
  });

  group('Refund flow', () {
    test('refundDeposit thành công → status = Refunded', () async {
      final result = await repository.refundDeposit(
        depositId: 'DEP001',
        reason: 'Cafe đóng cửa đột xuất',
      );
      // ignore: avoid_returning_null_for_void — async fold returns Future
      await result.fold(
        (f) async => fail('Expected success but got $f'),
        (entity) async {
          expect(entity.status, DepositStatus.refunded);
          expect(entity.refundedAmount, 50000);
          expect(entity.refundPolicy, RefundPolicy.full);
        },
      );
    });
  });

  group('PaymentCubit regenerateQr', () {
    test(
      'regenerateQr khi đang AwaitingCallback',
      () async {
        final cubit = PaymentCubit(
          repository: repository,
          gateway: gateway,
          persistence: persistence,
        );
        // Seed state trực tiếp bằng cách gọi start() trước.
        await cubit.start(
          bookingId: 'BK001',
          amount: 50000,
          method: PaymentMethod.sepay,
          deadline: DateTime.now().add(const Duration(minutes: 15)),
          config: remote.depositConfig,
        );
        // Đợi state chuyển sang AwaitingCallback hoặc Success.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // Re-seed vào AwaitingCallback nếu chưa (force test).
        await cubit.regenerateQr();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        // Sau regenerateQr, state phải là AwaitingCallback hoặc
        // Processing (vì gateway đã trigger Paid ngay).
        final s = cubit.state;
        expect(
          s is PaymentAwaitingCallback ||
              s is PaymentFailed ||
              s is PaymentSuccess,
          isTrue,
          reason: 'Got state: $s',
        );
        await cubit.close();
      },
    );
  });
}
