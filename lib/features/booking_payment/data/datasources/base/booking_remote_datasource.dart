import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/booking_history_entity.dart';
import '../../../domain/entities/deposit_config_entity.dart';
import '../../../domain/enums/payment_method.dart';

/// Interface tầng Data — abstraction giữa Repository và Remote API.
///
/// Hai implementation:
/// - `MockBookingRemoteDatasource` (chạy local, không cần backend)
/// - `BookingRemoteDatasourceImpl` (gọi Dio thật, dùng khi có backend)
abstract class BookingRemoteDatasource {
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  );

  Future<Either<Failure, BookingEntity>> createBooking({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required double depositAmount,
    required PaymentMethod paymentMethod,
    required List<String> memberIds,
  });

  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  Future<Either<Failure, BookingEntity>> confirmBookingPayment({
    required String bookingId,
    required String paymentRef,
  });

  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  });

  Stream<BookingEntity> watchBookingStatus(String bookingId);

  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory();
}