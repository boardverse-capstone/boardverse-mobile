import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../entities/booking_history_entity.dart';
import '../entities/booking_rating_submission_entity.dart';
import '../entities/cafe_availability_entity.dart';
import '../entities/cafe_booking_summary_entity.dart';
import '../entities/cafe_table_entity.dart';
import '../entities/deposit_config_entity.dart';
import '../entities/deposit_payment_entity.dart';
import '../entities/deposit_status_entity.dart';
import '../entities/lobby_booking_summary_entity.dart';
import '../entities/no_show_vote_result_entity.dart';
import '../entities/rating_status_entity.dart';
import '../entities/session_status_entity.dart';

/// Domain interface — khoá giữa Presentation và Data.
///
/// `Either<Failure, T>` để presentation xử lý 2 nhánh rõ ràng.
/// `Unit` từ `dartz` đại diện cho "không có giá trị trả về".
abstract class BookingRepository {
  // ─── Booking CRUD ─────────────────────────────────────────────────

  /// Lấy cấu hình cọc của 1 quán — `GET /api/Cafes/{cafeId}/deposit-config`.
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  );

  /// Tạo đơn đặt chỗ — `POST /api/bookings`.
  ///
  /// Yêu cầu lobby đã ở `Full` (server check 409 nếu chưa đủ người) HOẶC
  /// `lobbyId == null` cho walk-in flow (gap #3).
  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  });

  /// Lấy các bàn phù hợp rồi để client chọn bàn đầu tiên theo strategy
  /// `single_default` khi lobby chưa gắn sẵn `cafeTableId`.
  Future<Either<Failure, List<CafeTableEntity>>> getAvailableTables({
    required String cafeId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    required int seatCount,
  });

  /// Khảo sát capacity tổng quát + slot thay thế (gap #2).
  Future<Either<Failure, CafeAvailabilityEntity>> getCafeAvailability({
    required String cafeId,
    required DateTime startTime,
    required DateTime endTime,
    int? seatCount,
    String? gameTemplateId,
  });

  /// Lấy chi tiết booking — `GET /api/bookings/{id}`.
  Future<Either<Failure, BookingEntity>> getBookingById(String id);

  /// Lấy booking theo lobby — `GET /api/bookings/lobby/{lobbyId}`.
  /// Trả null data khi lobby chưa có booking.
  Future<Either<Failure, BookingEntity?>> getBookingByLobby(String lobbyId);

  /// Hủy đơn do host — `DELETE /api/bookings/{id}?reason=...`.
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  });

  // ─── BookingDeposit ───────────────────────────────────────────────

  /// Tạo đơn cọc + QR — `POST /api/payments/booking-deposit`.
  /// Shape tối thiểu (chỉ bookingId). Lưu `pendingBookingId` +
  /// `pendingDepositId` để resume flow khi kill app.
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  );

  /// Variant đầy đủ theo `payment.md` one-step: kèm `cafeId, lobbyId,
  /// scheduledStartTime, seatCount, amount` để backend tự tạo deposit
  /// mới (hoặc fallback về 2-step nếu backend version cũ chỉ chấp nhận
  /// `bookingId` + `depositId`).
  Future<Either<Failure, DepositPaymentEntity>>
      createDepositPaymentWithDetails({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  });

  /// Polling `GET /api/payments/booking-deposit/{id}` mỗi 3 giây.
  /// Stream emit ít nhất 1 lần rồi đóng khi status terminal.
  Stream<Either<Failure, DepositStatusEntity>> pollDepositStatus(
    String depositId, {
    Duration interval = const Duration(seconds: 3),
  });

  /// Lấy trạng thái đơn cọc 1 lần — `GET /api/payments/booking-deposit/{id}`.
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  );

  /// Tạo lại QR khi QR cũ hết hạn — `POST /api/payments/booking-deposit/{id}/regenerate-qr`.
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  );

  /// Tra theo `OrderId` (`BV...`) — `GET /api/payments/booking-deposit/by-order/{orderId}`.
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  );

  /// Hoàn cọc — `POST /api/payments/booking-deposit/refund`.
  /// Chỉ Manager/Admin — Player hiện chỉ thấy status `Refunded` qua polling.
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  });

  // ─── NoShow vote + Cross-rating (gap #4, #5) ─────────────────────

  /// Ghi nhận vote vắng mặt (gap #4).
  Future<Either<Failure, NoShowVoteResultEntity>> submitNoShowVote({
    required String bookingId,
    required List<String> absentMemberIds,
    DateTime? votedAt,
  });

  /// Submit cross-rating cho nhiều thành viên (gap #5).
  Future<Either<Failure, RatingSubmissionResultEntity>> submitRatings(
    BookingRatingSubmissionEntity submission,
  );

  /// Trạng thái rating của voter hiện tại (gap #5).
  Future<Either<Failure, RatingStatusEntity>> getRatingStatus(
    String bookingId,
  );

  // ─── Session realtime (gap #8) ───────────────────────────────────

  /// Lấy realtime session status (ai về sớm + bill ước tính).
  Future<Either<Failure, SessionStatusEntity>> getSessionStatus(
    String bookingId,
  );

  // ─── Cafe view cho Player (gap #14) ──────────────────────────────

  /// Danh sách booking summary theo cafe (Player view rút gọn).
  Future<Either<Failure, List<CafeBookingSummaryEntity>>> getBookingsForCafe(
    String cafeId,
  );

  // ─── Lifecycle helpers ───────────────────────────────────────────

  /// Lấy tổng hợp (hosted + joined) booking cho player hiện tại.
  ///
  /// Dùng 2 endpoint `GET /api/v1/lobbies/hosted` + `GET /api/v1/lobbies/joined`,
  /// sau đó với mỗi lobby gọi `GET /api/bookings/lobby/{lobbyId}` để lấy
  /// booking detail. Trả về cùng cấu trúc `UpcomingAndHistory` để UI
  /// không cần đổi widget.
  Future<Either<Failure, UpcomingAndHistory>> loadAllForUser();

  /// Trợ giúp cho `LobbyPage` — kiểm tra lobby đã có booking chưa để
  /// biết nên tạo booking mới (luồng thủ công) hay gọi thẳng
  /// `createDepositPayment` (luồng A auto-booking).
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  );

  // ─── Resume helpers ──────────────────────────────────────────────

  /// Lưu id booking đang pending để resume nếu kill app.
  Future<Either<Failure, Unit>> savePendingBookingId(String id);

  /// Lưu id deposit đang pending (sau khi tạo QR) để resume SePay flow.
  Future<Either<Failure, Unit>> savePendingDepositId(String id);

  Future<Either<Failure, String?>> getPendingBookingId();

  Future<Either<Failure, String?>> getPendingDepositId();

  Future<Either<Failure, Unit>> clearPendingBookingId();

  Future<Either<Failure, Unit>> clearPendingDepositId();
}

/// Dữ liệu trả về cho UI lịch sử — chia 2 bucket: upcoming + history.
class UpcomingAndHistory {
  final List<BookingEntity> upcoming;
  final List<BookingHistoryEntity> history;

  const UpcomingAndHistory({
    required this.upcoming,
    required this.history,
  });
}
