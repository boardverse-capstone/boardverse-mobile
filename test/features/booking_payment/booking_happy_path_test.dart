// Smoke test happy path cho booking_payment module.
//
// Verify toàn bộ state machine:
//   SummaryInitial -> SummaryLoading -> SummaryReady
//   -> SummarySubmitting -> SummarySuccess
//   -> PaymentIdle -> PaymentOpening -> PaymentAwaitingCallback
//   -> PaymentProcessing -> PaymentSuccess
//
// Sử dụng MockBookingRemoteDatasource + MockPaymentGateway thật
// (successAfterTicks = 1 để test nhanh).

import 'package:bloc_test/bloc_test.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_persistence_service.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_repository_impl.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/mock/mock_booking_remote_datasource.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/mock/mock_payment_gateway.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/enums/payment_method.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/booking_summary_cubit.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/booking_summary_state.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/payment_cubit.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/payment_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_secure_storage.dart';

void main() {
  late MockBookingRemoteDatasource remote;
  late MockPaymentGateway gateway;
  late BookingPersistenceService persistence;
  late BookingRepositoryImpl repository;

  setUp(() {
    remote = MockBookingRemoteDatasource();
    gateway = MockPaymentGateway(successAfterTicks: 1);
    persistence = BookingPersistenceService(
      storage: FakeSecureStorage(),
    );
    repository = BookingRepositoryImpl(
      datasource: remote,
      persistence: persistence,
    );
  });

  group('BookingSummaryCubit happy path', () {
    blocTest<BookingSummaryCubit, BookingSummaryState>(
      'loadConfig -> SummaryLoading -> SummaryReady',
      build: () => BookingSummaryCubit(repository: repository),
      act: (cubit) => cubit.loadConfig('CAFE001'),
      expect: () => [
        isA<SummaryLoading>(),
        isA<SummaryReady>(),
      ],
    );

    test('submit tạo booking pendingDeposit và lưu resume id', () async {
      final cubit = BookingSummaryCubit(repository: repository);
      await cubit.loadConfig('CAFE001');
      expect(cubit.state, isA<SummaryReady>());

      await cubit.submit(
        cafeId: 'CAFE001',
        gameId: 'GAME001',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        seatCount: 4,
        memberIds: const ['u1', 'u2', 'u3', 'u4'],
      );

      expect(cubit.state, isA<SummarySuccess>());
      final success = cubit.state as SummarySuccess;
      expect(success.bookingId, isNotEmpty);
      expect(success.depositAmount, greaterThan(0));
      expect(success.deadline.isAfter(DateTime.now()), isTrue);

      // Verify persistence đã lưu pending id.
      final saved = await persistence.getPendingBookingId();
      expect(saved, equals(success.bookingId));
    });
  });

  group('PaymentCubit happy path (mock gateway success)', () {
    blocTest<PaymentCubit, PaymentState>(
      'start mở gateway -> AwaitingCallback -> Processing -> Success',
      build: () => PaymentCubit(repository: repository, gateway: gateway),
      act: (cubit) async {
        // Tạo booking trước để có bookingId thật.
        final created = await repository.createBooking(
          cafeId: 'CAFE001',
          gameId: 'GAME001',
          scheduledTime: DateTime.now().add(const Duration(hours: 2)),
          seatCount: 4,
          depositAmount: 50000,
          paymentMethod: PaymentMethod.sandboxMock,
          memberIds: const ['u1'],
        );
        final booking =
            created.getOrElse(() => throw Exception('create failed'));
        final configResult = await repository.getDepositConfig('CAFE001');
        final config =
            configResult.getOrElse(() => throw Exception('config failed'));

        await cubit.start(
          bookingId: booking.id,
          amount: booking.depositAmount,
          method: PaymentMethod.sandboxMock,
          deadline: booking.depositDeadline,
          config: config,
        );
      },
      wait: const Duration(seconds: 3),
      expect: () => [
        isA<PaymentOpening>(),
        isA<PaymentAwaitingCallback>(),
        isA<PaymentProcessing>(),
        isA<PaymentSuccess>(),
      ],
    );
  });

  group('Repository persistence', () {
    test('confirmBookingPayment xoá pending id sau khi CONFIRMED', () async {
      final created = await repository.createBooking(
        cafeId: 'CAFE001',
        gameId: 'GAME001',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        seatCount: 2,
        depositAmount: 50000,
        paymentMethod: PaymentMethod.sandboxMock,
        memberIds: const ['host', 'p2'],
      );
      final booking =
          created.getOrElse(() => throw Exception('create failed'));

      expect(await persistence.getPendingBookingId(), equals(booking.id));

      await repository.confirmBookingPayment(
        bookingId: booking.id,
        paymentRef: 'MOCKTX123',
      );

      // Sau khi CONFIRMED → persistence được clear.
      expect(await persistence.getPendingBookingId(), isNull);
    });

    test('cancelBookingByPlayer xoá pending id', () async {
      final created = await repository.createBooking(
        cafeId: 'CAFE001',
        gameId: 'GAME001',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        seatCount: 2,
        depositAmount: 50000,
        paymentMethod: PaymentMethod.sandboxMock,
        memberIds: const ['host'],
      );
      final booking =
          created.getOrElse(() => throw Exception('create failed'));

      expect(await persistence.getPendingBookingId(), equals(booking.id));

      await repository.cancelBookingByPlayer(
        bookingId: booking.id,
        reason: 'Đổi kế hoạch',
      );

      expect(await persistence.getPendingBookingId(), isNull);
    });
  });
}
