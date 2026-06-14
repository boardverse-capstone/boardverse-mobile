import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/deposit_entity.dart';
import '../entities/booking_qr_entity.dart';

abstract class BookingRepository {
  Future<Either<Failure, DepositEntity>> initiateDeposit({
    required String lobbyId,
    required double amount,
  });

  Future<Either<Failure, DepositEntity>> makeDeposit(String depositId);

  Future<Either<Failure, BookingQrEntity>> confirmBooking(String depositId);

  Stream<DepositEntity> watchDepositStatus(String depositId);

  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory();
}
