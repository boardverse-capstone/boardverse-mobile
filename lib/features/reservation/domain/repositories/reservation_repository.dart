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

  /// Tạo quote cho reservation (không tạo DB row).
  ///
  /// **BR-NEW-15 (2026-08-18):** Backend đã BỎ `timeSlot` khỏi request body
  /// của `POST /api/v1/reservations/quote`. FE phải gửi `preferredStartTime`
  /// + `preferredEndTime` để xác định khung giờ chơi (cả 2 REQUIRED — xem
  /// swagger.json `ReservationQuoteRequestDto` line 27806).
  ///
  /// Server tự suy ra `timeSlot` từ cặp giờ này và trả về kèm
  /// `scheduledStartTime`/`scheduledEndTime` trong response. Nếu
  /// `preferredStartTime`/`preferredEndTime` không hợp lệ (ngoài giờ mở
  /// cửa của cafe / quá sát giờ hiện tại) → backend trả 400.
  ///
  /// [cafeId] - quán cần đặt
  /// [gameId] - game muốn chơi
  /// [playDate] - ngày chơi
  /// [preferredStartTime] - giờ bắt đầu dự kiến `HH:mm:ss` (required)
  /// [preferredEndTime] - giờ kết thúc dự kiến `HH:mm:ss` (required)
  /// [isPrivate] - lobby private (bỏ qua cafe approval) hay public (cần cafe duyệt)
  /// [minPlayers], [maxPlayers] - số người
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  });

  /// Confirm reservation - atomic transaction.
  ///
  /// **BR-NEW-15 (2026-08-18):** Confirm cũng đã bỏ `timeSlot` — chỉ verify
  /// lại `preferredStartTime`/`preferredEndTime` khớp với quote đã lưu và
  /// kiểm tra `expectedFinalDeposit` khớp server.
  ///
  /// Thực hiện:
  /// 1. Validate lại quote (verify `expectedFinalDeposit` khớp BR §XVII.2)
  /// 2. Kiểm tra available seats >= maxPlayers
  /// 3. Kiểm tra game copy còn
  /// 4. Trừ availableBalance, cộng heldBalance
  /// 5. Tạo Reservation (status = holding)
  /// 6. Tạo Lobby (status = pendingActivation → open sau khi commit)
  /// 7. Hold seats và game inventory
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
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
