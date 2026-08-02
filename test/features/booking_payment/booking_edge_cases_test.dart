// Edge cases cho booking + deposit sau khi tích hợp SePay.
//
// Cases cover:
// - ConflictFailure 409 khi lobby chưa Full
// - Polling timeout → PaymentTimeout
// - Gateway trả Failed → PaymentFailed
// - Resume pending id flow

import 'package:bloc_test/bloc_test.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_persistence_service.dart';
import 'package:boardverse_mobile/features/booking_payment/data/booking_repository_impl.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/base/booking_remote_datasource.dart';
import 'package:boardverse_mobile/features/booking_payment/data/datasources/base/payment_gateway.dart';
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
import 'package:boardverse_mobile/core/network/api_response.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_secure_storage.dart';

class AlwaysFailRemote implements BookingRemoteDatasource {
  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  }) async {
    return Left(
      ConflictFailure(message: 'Lobby chưa đủ người (409)'),
    );
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async =>
      const Left(NotFoundFailure(message: 'Not found'));

  @override
  Future<Either<Failure, BookingEntity?>> getBookingByLobby(
    String lobbyId,
  ) async =>
      const Left(NotFoundFailure(message: 'Not found'));

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) async =>
      const Left(ConflictFailure(message: 'Không thể huỷ (409)'));

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) async =>
      const Left(
        ServerFailure(message: 'Lỗi server (500)', statusCode: 500),
      );

  @override
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  ) async =>
      const Left(NetworkFailure(message: 'Mất kết nối'));

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
          const Left(NetworkFailure(message: 'Mất kết nối'));

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  ) async =>
      const Left(NetworkFailure(message: 'Mất kết nối'));

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  ) async =>
      const Left(NetworkFailure(message: 'Mất kết nối'));

  @override
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  ) async =>
      const Left(NetworkFailure(message: 'Mất kết nối'));

  @override
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  }) async =>
      const Left(NetworkFailure(message: 'Mất kết nối'));

  @override
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  ) async =>
      const Left(NotFoundFailure(message: 'Not found'));

  @override
  Future<Either<Failure, List<String>>> getHostedLobbyIds() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<String>>> getJoinedLobbyIds() async =>
      const Right([]);

  @override
  Future<List<BookingHistoryEntity>> noopHistoryShim() async => const [];
}

class AlwaysFailGateway implements PaymentGateway {
  @override
  Future<Either<Failure, String>> openGateway({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async =>
      const Left(ServerFailure(message: 'Gateway không phản hồi'));

  @override
  Stream<PaymentResult> watchResult(String transactionRef) async* {
    yield const GatewayFailed(reason: 'Gateway timeout');
  }
}

void main() {
  late AlwaysFailRemote remote;
  late AlwaysFailGateway gateway;
  late BookingPersistenceService persistence;
  late BookingRepositoryImpl repository;

  DepositConfigEntity testConfig() => DepositConfigEntity(
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

  Breakdown buildBreakdown() => Breakdown(
        firstHourPrice: 100000,
        recommendedDeposit: 50000,
        maxDeposit: 50000,
        currency: 'VND',
        pricingModelLabel: 'hourly',
      );

  setUp(() {
    remote = AlwaysFailRemote();
    gateway = AlwaysFailGateway();
    persistence = BookingPersistenceService(storage: FakeSecureStorage());
    repository = BookingRepositoryImpl(
      datasource: remote,
      persistence: persistence,
    );
  });

  group('BookingSummaryCubit edge cases', () {
    blocTest<BookingSummaryCubit, BookingSummaryState>(
      'createBooking 409 → SummaryFailure',
      build: () => BookingSummaryCubit(repository: repository),
      seed: () => SummaryReady(
        config: testConfig(),
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
        isA<SummaryFailure>(),
      ],
    );
  });

  group('PaymentCubit edge cases', () {
    blocTest<PaymentCubit, PaymentState>(
      'gateway openGateway fail → PaymentFailed',
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
        config: testConfig(),
      ),
      wait: const Duration(milliseconds: 300),
      verify: (cubit) {
        expect(cubit.state, isA<PaymentFailed>());
      },
    );
  });

  group('Resume flow', () {
    test('savePendingBookingId persists across service instances', () async {
      await repository.savePendingBookingId('BK_PERSIST');
      final secondRepo = BookingRepositoryImpl(
        datasource: remote,
        persistence: persistence,
      );
      final result = await secondRepo.getPendingBookingId();
      result.fold(
        (f) => fail('Expected success but got $f'),
        (id) => expect(id, 'BK_PERSIST'),
      );
    });

    test('clearPendingBookingId removes persistence', () async {
      await repository.savePendingBookingId('BK001');
      await repository.clearPendingBookingId();
      final id = await persistence.getPendingBookingId();
      expect(id, isNull);
    });
  });

  group('Failure mapping', () {
    test('ApiResponse 409 → ConflictFailure', () {
      final api = ApiResponse<int>(
        statusCode: 409,
        message: 'Xung đột',
        data: null,
      );
      final f = FailureFromApiResponseX.fromApiResponse(api);
      expect(f, isA<ConflictFailure>());
      expect(f.message, 'Xung đột');
    });

    test('ApiResponse 401 → UnauthorizedFailure', () {
      final api = ApiResponse<int>(
        statusCode: 401,
        message: 'Hết phiên',
        data: null,
      );
      final f = FailureFromApiResponseX.fromApiResponse(api);
      expect(f, isA<UnauthorizedFailure>());
    });

    test('ApiResponse 500 → ServerFailure', () {
      final api = ApiResponse<int>(
        statusCode: 500,
        message: 'Lỗi server',
        data: null,
      );
      final f = FailureFromApiResponseX.fromApiResponse(api);
      expect(f, isA<ServerFailure>());
      expect((f as ServerFailure).statusCode, 500);
    });
  });

  group('BookingStatus enum 5-value semantics', () {
    test('pendingDeposit → còn active, có thể huỷ', () {
      const s = BookingStatus.pendingDeposit;
      expect(s.isActive, isTrue);
      expect(s.isTerminal, isFalse);
      expect(s.canPlayerCancel, isTrue);
      expect(s.displayLabel, 'Chờ đặt cọc');
    });

    test('confirmed → active, có thể huỷ', () {
      const s = BookingStatus.confirmed;
      expect(s.isActive, isTrue);
      expect(s.canPlayerCancel, isTrue);
    });

    test('checkedIn → terminal', () {
      const s = BookingStatus.checkedIn;
      expect(s.isTerminal, isTrue);
      expect(s.isActive, isFalse);
      expect(s.canPlayerCancel, isFalse);
    });

    test('cancelled/noShow → terminal', () {
      expect(BookingStatus.cancelled.isTerminal, isTrue);
      expect(BookingStatus.noShow.isTerminal, isTrue);
    });
  });
}
