import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/booking_entity.dart';
import '../domain/entities/booking_history_entity.dart';
import '../domain/entities/deposit_config_entity.dart';
import '../domain/enums/booking_status.dart';
import '../domain/enums/payment_method.dart';
import '../domain/repositories/booking_repository.dart';
import 'booking_persistence_service.dart';
import 'datasources/base/booking_remote_datasource.dart';
import 'datasources/mock/mock_booking_remote_datasource.dart';

/// Triển khai `BookingRepository` — orchestrate giữa datasource
/// (mock/remote) và persistence service (secure storage cho resume).
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDatasource _datasource;
  final BookingPersistenceService _persistence;

  BookingRepositoryImpl({
    required this._datasource,
    required this._persistence,
  });

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) =>
      _datasource.getDepositConfig(cafeId);

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required double depositAmount,
    required PaymentMethod paymentMethod,
    required List<String> memberIds,
  }) async {
    final result = await _datasource.createBooking(
      cafeId: cafeId,
      gameId: gameId,
      scheduledTime: scheduledTime,
      seatCount: seatCount,
      depositAmount: depositAmount,
      paymentMethod: paymentMethod,
      memberIds: memberIds,
    );

    // Resume: chỉ lưu khi vẫn ở trạng thái pendingDeposit.
    return await result.fold(
      (failure) async => Left<Failure, BookingEntity>(failure),
      (booking) async {
        if (booking.status == BookingStatus.pendingDeposit) {
          await _persistence.savePendingBookingId(booking.id);
        }
        return Right<Failure, BookingEntity>(booking);
      },
    );
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) =>
      _datasource.getBookingById(id);

  @override
  Future<Either<Failure, BookingEntity>> confirmBookingPayment({
    required String bookingId,
    required String paymentRef,
  }) async {
    final result = await _datasource.confirmBookingPayment(
      bookingId: bookingId,
      paymentRef: paymentRef,
    );
    return await result.fold(
      (failure) async => Left<Failure, BookingEntity>(failure),
      (booking) async {
        if (booking.status.isTerminal ||
            booking.status == BookingStatus.confirmed) {
          await _persistence.clearPendingBookingId();
        }
        return Right<Failure, BookingEntity>(booking);
      },
    );
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) async {
    final result = await _datasource.cancelBookingByPlayer(
      bookingId: bookingId,
      reason: reason,
    );
    return await result.fold(
      (failure) async => Left<Failure, BookingEntity>(failure),
      (booking) async {
        await _persistence.clearPendingBookingId();
        return Right<Failure, BookingEntity>(booking);
      },
    );
  }

  @override
  Stream<BookingEntity> watchBookingStatus(String bookingId) =>
      _datasource.watchBookingStatus(bookingId);

  @override
  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory() =>
      _datasource.getBookingHistory();

  @override
  Future<Either<Failure, List<BookingEntity>>> getUpcomingBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final list = (_datasource as MockBookingRemoteDatasource).getUpcomingBookings();
      return Right(list.map((m) => m.toEntity()).toList());
    } catch (_) {
      return const Right([]);
    }
  }

  // ─── Resume helpers ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> savePendingBookingId(String id) async {
    try {
      await _persistence.savePendingBookingId(id);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Không thể lưu booking id: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingBookingId() async {
    try {
      final id = await _persistence.getPendingBookingId();
      return Right(id);
    } catch (e) {
      return Left(CacheFailure(message: 'Không thể đọc booking id: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearPendingBookingId() async {
    try {
      await _persistence.clearPendingBookingId();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Không thể xoá booking id: $e'));
    }
  }
}