import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/booking_history_entity.dart';
import '../../../domain/entities/deposit_config_entity.dart';
import '../../../domain/entities/deposit_payment_entity.dart';
import '../../../domain/entities/deposit_status_entity.dart';
import '../../../domain/entities/lobby_booking_summary_entity.dart';

/// Interface tầng Data — abstraction giữa Repository và Remote API.
///
/// Triển khai duy nhất hiện tại: `BookingRemoteDatasourceImpl` (Dio).
/// Mock đã bị xoá theo plan tích hợp.
abstract class BookingRemoteDatasource {
  // ─── Booking CRUD ─────────────────────────────────────────────────
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  );

  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  });

  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  Future<Either<Failure, BookingEntity?>> getBookingByLobby(String lobbyId);

  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  });

  // ─── Payments (SePay) ────────────────────────────────────────────
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  );

  /// Variant cho [payment.md] one-step shape — gửi kèm `cafeId, lobbyId,
  /// scheduledStartTime, seatCount, amount` để backend tự tạo deposit
  /// mới + return payment URL. Một số backend versions theo swagger lại
  /// dùng 2-step (`bookingId` + `depositId`) — implementation hiện tại
  /// gộp cả hai thành optional params.
  Future<Either<Failure, DepositPaymentEntity>> createDepositPaymentWithDetails({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  });

  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  );

  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  );

  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  );

  /// `POST /api/payments/booking-deposit/refund` — hoàn cọc theo policy.
  /// Chỉ Manager/Admin.
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  });

  // ─── Helpers ─────────────────────────────────────────────────────
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  );

  /// `GET /api/v1/lobbies/hosted` — lobbies do user này host.
  Future<Either<Failure, List<String>>> getHostedLobbyIds();

  /// `GET /api/v1/lobbies/joined` — lobbies user đang tham gia.
  Future<Either<Failure, List<String>>> getJoinedLobbyIds();

  /// Hook để re-export `BookingPersistenceService` qua abstraction khi cần.
  Future<List<BookingHistoryEntity>> noopHistoryShim();
}
