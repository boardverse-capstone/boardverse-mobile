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
  /// Lấy danh sách reservations (phân trang, filter theo status/date/cafe).
  ///
  /// `GET /api/v1/reservations` — simple list. Dùng khi KHÔNG có
  /// gameName và date range (search thường).
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>> getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  });

  /// Tìm kiếm reservations theo tên game và/hoặc khoảng ngày.
  ///
  /// `GET /api/v1/reservations/search` — fuzzy search theo gameName + filter
  /// theo fromDate/toDate/status/cafeId. Dùng cho Player tra cứu lại lịch
  /// hẹn trong lịch sử (UI: trang Search trong tab Lịch hẹn).
  ///
  /// [gameName] - từ khóa tìm theo tên game (tùy chọn).
  /// [fromDate] / [toDate] - khoảng ngày chơi (inclusive).
  /// [statuses] - filter theo status (Holding/Confirmed/...).
  /// [cafeId] - filter theo cafe cụ thể.
  /// [hostedByMe] / [joinedByMe] - filter theo role của user.
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      searchReservations({
    String? gameName,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? statuses,
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

  /// Lấy tất cả reservation của user (Host + Member) cho màn hình "Lịch sử".
  ///
  /// `GET /api/v1/reservations/my` — endpoint mới (Sep 2026) gộp cả host
  /// lẫn member, có 2 summary count (`hostedCount` + `joinedCount`) để FE
  /// render 2 tab "Tôi tạo (N) | Tôi tham gia (M)" mà không cần filter
  /// client-side.
  ///
  /// Mỗi item có field `participationType` để FE phân biệt host vs member.
  ///
  /// Docs: `.agents/docs/apis_docs/reservation.md` §GET /my.
  Future<Either<Failure, MyReservationsResult>> getMyReservations({
    ReservationParticipationType? participationType,
    List<String>? statuses,
    String? cafeId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  });
}

/// Kết quả trả về từ `GET /api/v1/reservations/my`.
///
/// Bao gồm danh sách reservation + 2 summary count (hostedCount /
/// joinedCount) để render tab strip "Tôi tạo (N) | Tôi tham gia (M)".
///
/// Counts áp dụng cùng filter (statuses/cafeId/fromDate/toDate) nhưng
/// **độc lập với [participationType]** — khi user filter Host-only,
/// `joinedCount` vẫn count full Member để summary tab không đổi khi đổi
/// filter (theo API docs 2026-09-02).
class MyReservationsResult {
  final PaginatedResponse<ReservationEntity> paginated;
  final int hostedCount;
  final int joinedCount;

  const MyReservationsResult({
    required this.paginated,
    required this.hostedCount,
    required this.joinedCount,
  });

  /// Shortcut tới items.
  List<ReservationEntity> get items => paginated.items;
}
