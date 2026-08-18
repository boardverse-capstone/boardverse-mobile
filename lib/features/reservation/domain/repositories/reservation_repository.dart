import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/paginated_response.dart';
import '../entities/entities.dart';

/// Repository interface cho reservation feature (BR §6)
///
/// Quản lý luồng:
/// - Quote: tính toán cọc (không tạo row)
/// - Confirm: atomic transaction (hold BVC + hold seat + hold game + create lobby)
/// - Cancel: hủy reservation theo policy
abstract class ReservationRepository {
  /// Lấy danh sách reservations (phân trang, filter theo status/date/cafe)
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>> getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  });

  /// Tạo quote cho reservation (không tạo DB row)
  ///
  /// [cafeId] - quán cần đặt
  /// [gameId] - game muốn chơi
  /// [playDate] - ngày chơi
  /// [timeSlot] - khung giờ
  /// [preferredStartTime] - giờ bắt đầu ưa thích (optional)
  /// [preferredEndTime] - giờ kết thúc ưa thích (optional)
  /// [isPrivate] - lobby private (bỏ qua cafe approval) hay public (cần cafe duyệt)
  /// [minPlayers], [maxPlayers] - số người
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    String? preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  });

  /// Confirm reservation - atomic transaction
  ///
  /// Thực hiện:
  /// 1. Validate lại quote
  /// 2. Kiểm tra available seats >= maxPlayers
  /// 3. Kiểm tra game copy còn
  /// 4. Trừ availableBalance, cộng heldBalance
  /// 5. Tạo Reservation (status = holding)
  /// 6. Tạo Lobby (status = pendingActivation)
  /// 7. Hold seats và game inventory
  /// 8. Publish lobby → status = open
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    String? preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  });

  /// Cancel reservation
  ///
  /// [reason] - lý do hủy (optional)
  /// Trả về số BVC được hoàn theo policy
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  });

  /// Lấy chi tiết reservation
  Future<Either<Failure, ReservationEntity>> getReservation(String reservationId);

  /// Lấy reservation theo id (alias cho getReservation để khớp plan).
  Future<Either<Failure, ReservationEntity>> getReservationDetail(
      String reservationId);

  /// Lấy danh sách reservation đang chờ cafe duyệt (cho Cafe Manager).
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getPendingCafeApprovals({
    String? cafeId,
    DateTime? playDate,
    int page = 1,
    int pageSize = 20,
  });

  /// Cafe approval cho lobby cần duyệt
  Future<Either<Failure, void>> cafeApproval({
    required String reservationId,
    required bool approve,
    String? reason,
  });

  /// Cancel reservation sau khi đã check-in (BR-REFUND-04/05)
  ///
  /// Áp dụng refund theo playedRatio:
  /// - playedRatio < 50%: 0% hoàn (forfeit 100%)
  /// - playedRatio >= 50%: 30% hoàn
  /// - playedRatio >= 90%: treated as on-time (0% hoàn)
  Future<Either<Failure, ReservationCancelAfterCheckinResult>>
      cancelAfterCheckin({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  });

  /// Kiểm tra xem có thể extend reservation không (BR-EXT-01..05)
  ///
  /// [extensionMinutes] - số phút muốn extend (1-120)
  /// Trả về thông tin về khả năng extend và thời gian mới
  Future<Either<Failure, ExtendAvailabilityResult>> checkExtendAvailability({
    required String reservationId,
    required int extensionMinutes,
  });

  /// Check-in bằng QR code (POS)
  ///
  /// [reservationCode] - mã 8-char alphanumeric từ QR code
  /// [cafeId] - CafeId của POS staff đang quét
  /// [activeSessionId] - POS session ID
  Future<Either<Failure, CheckInByCodeResult>> checkInByCode({
    required String reservationCode,
    required String cafeId,
    required String activeSessionId,
    required String idempotencyKey,
  });
}
