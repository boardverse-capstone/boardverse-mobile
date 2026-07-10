import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../entities/booking_history_entity.dart';
import '../entities/deposit_config_entity.dart';
import '../enums/payment_method.dart';

/// Domain interface — khoá giữa Presentation và Data.
///
/// `Either<Failure, T>` để presentation xử lý 2 nhánh rõ ràng.
/// Unit trả về từ `dartz` đại diện cho "không có giá trị trả về".
abstract class BookingRepository {
  /// Lấy cấu hình cọc của 1 quán — `GET /api/Cafes/{cafeId}/deposit-config`.
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  );

  /// Tạo đơn đặt chỗ — `POST /api/Bookings`.
  /// Server validate BR-05 (ghế trống) + BR-03 (cọc ≤ 50%).
  Future<Either<Failure, BookingEntity>> createBooking({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required double depositAmount,
    required PaymentMethod paymentMethod,
    required List<String> memberIds,
  });

  /// Lấy chi tiết booking — dùng cho resume + mở `BookingSuccessPage`.
  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  /// Gọi sau khi nhận `PaymentSuccess` từ gateway —
  /// `POST /api/Bookings/{id}/confirm`.
  Future<Either<Failure, BookingEntity>> confirmBookingPayment({
    required String bookingId,
    required String paymentRef,
  });

  /// Hủy đơn do Host — `POST /api/Bookings/{id}/cancel`
  /// với body `{ "reason": "..." }`.
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  });

  /// Polling mỗi 3s (sau này thay bằng WebSocket).
  Stream<BookingEntity> watchBookingStatus(String bookingId);

  /// Lịch sử booking của user — `GET /api/Bookings/history`.
  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory();

  /// Lấy các booking sắp tới (confirmed + checkedIn) của user.
  Future<Either<Failure, List<BookingEntity>>> getUpcomingBookings();

  // ─── Resume helpers ─────────────────────────────────────────────────

  /// Lưu id booking đang pending để resume sau khi kill app.
  Future<Either<Failure, Unit>> savePendingBookingId(String id);

  Future<Either<Failure, String?>> getPendingBookingId();

  Future<Either<Failure, Unit>> clearPendingBookingId();
}