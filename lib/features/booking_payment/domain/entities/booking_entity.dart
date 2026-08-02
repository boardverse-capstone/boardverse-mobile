import 'package:equatable/equatable.dart';

import '../enums/booking_status.dart';
import 'deposit_status_entity.dart';
import 'lobby_summary_entity.dart';

/// Domain entity — đơn đặt chỗ của Host tại một quán.
///
/// Mapping từ `BookingResponseDto` (xem `.agents/docs/apis_docs/booking.md`).
/// Backend không trả `userId` (lấy từ JWT); `memberIds` suy ra từ lobby
/// nếu cần hiển thị.
class BookingEntity extends Equatable {
  final String id;

  /// FK → Lobby. Có thể null cho walk-in booking (gap #3 — `POST /api/bookings`
  /// chấp nhận `lobbyId=null`).
  final String? lobbyId;

  final String cafeId;
  final String cafeName;

  /// FK → CafeTable. Bắt buộc khi tạo booking (backend validate).
  final String cafeTableId;
  final String? cafeTableName;

  final String gameId;
  final String gameName;

  /// UTC ISO 8601 từ backend — đã convert sang local khi map.
  final DateTime scheduledTime;
  final DateTime scheduleEndTime;

  /// Số ghế đặt (== tổng số thành viên, mỗi người 1 ghế theo BR-07).
  final int seatCount;
  final int playerQuantity;

  /// Danh sách id member thuộc lobby (cache từ `LobbyEntity.players`).
  final List<String> memberIds;

  /// Host ownership (lobby.hostId). Đối với walk-in, là chính player tạo.
  final String hostId;

  final BookingStatus status;

  /// Số tiền cọc server confirm (VND).
  final double depositAmount;

  /// Deadline cọc do server set (BR-06 ≤ 30 phút). Client chỉ render đếm ngược.
  final DateTime depositDeadline;

  /// Mã giao dịch trả về từ SePay (nullable cho tới khi `Paid`).
  final String? paymentRef;

  /// Chuỗi mã QR server cấp (trong `BookingResponseDto.verificationQRCode`).
  /// Staff POS quét chuỗi này để kích hoạt phiên chơi.
  final String verificationQrCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// ─── Fields mới (booking.md §179, gap #10) ───

  /// Thời điểm Staff POS check-in thành công.
  final DateTime? checkedInAt;

  /// Staff user id thực hiện check-in.
  final String? checkedInByUserId;

  /// Lobby snapshot nhúng trong BookingResponseDto (booking.md §179).
  /// Null cho walk-in booking.
  final LobbySummaryEntity? lobbySummary;

  /// ─── Fields refund (gap #11) ───

  /// Trạng thái đơn cọc (Pending/Paid/Refunded/Forfeited/Expired).
  /// Backend đã enrich vào BookingResponseDto.
  final DepositStatus? depositRefundStatus;

  /// Số tiền thực tế đã hoàn cho player (0 nếu Forfeited).
  final double? depositRefundAmount;

  /// ─── Fields walk-in (gap #3) ───

  /// `true` khi booking tạo không qua lobby (`lobbyId == null`).
  final bool isWalkIn;

  /// Mã nhóm cho booking walk-in (gom nhiều table cùng cafe).
  final String? bookingGroupCode;

  const BookingEntity({
    required this.id,
    required this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    required this.cafeTableId,
    this.cafeTableName,
    required this.gameId,
    required this.gameName,
    required this.scheduledTime,
    required this.scheduleEndTime,
    required this.seatCount,
    required this.playerQuantity,
    required this.memberIds,
    required this.hostId,
    required this.status,
    required this.depositAmount,
    required this.depositDeadline,
    this.paymentRef,
    required this.verificationQrCode,
    required this.createdAt,
    required this.updatedAt,
    this.checkedInAt,
    this.checkedInByUserId,
    this.lobbySummary,
    this.depositRefundStatus,
    this.depositRefundAmount,
    this.isWalkIn = false,
    this.bookingGroupCode,
  });

  /// Thời gian còn lại để hoàn tất cọc. Âm nếu đã quá hạn.
  Duration get remainingGraceTime =>
      depositDeadline.difference(DateTime.now());

  /// true nếu đã quá deadline cọc nhưng chưa được server xác nhận status đổi.
  bool get isLocallyExpired =>
      DateTime.now().isAfter(depositDeadline) &&
      status == BookingStatus.pendingDeposit;

  /// QR payload để truyền cho `qr_flutter` (alias cho `verificationQrCode`).
  String get qrPayload => verificationQrCode;

  /// `true` khi player có thể vote no-show (sau `checkedInAt + 30 phút`,
  /// trước `scheduleEndTime + 24 giờ`) — xem `booking-rating.md` §23.
  bool get canVoteNoShow {
    final c = checkedInAt;
    if (c == null) return false;
    final now = DateTime.now();
    final earliest = c.add(const Duration(minutes: 30));
    final latest = scheduleEndTime.add(const Duration(hours: 24));
    return now.isAfter(earliest) && now.isBefore(latest);
  }

  BookingEntity copyWith({
    String? lobbyId,
    String? cafeTableName,
    BookingStatus? status,
    DateTime? depositDeadline,
    String? paymentRef,
    DateTime? updatedAt,
    DateTime? checkedInAt,
    String? checkedInByUserId,
    LobbySummaryEntity? lobbySummary,
    DepositStatus? depositRefundStatus,
    double? depositRefundAmount,
  }) {
    return BookingEntity(
      id: id,
      lobbyId: lobbyId ?? this.lobbyId,
      cafeId: cafeId,
      cafeName: cafeName,
      cafeTableId: cafeTableId,
      cafeTableName: cafeTableName ?? this.cafeTableName,
      gameId: gameId,
      gameName: gameName,
      scheduledTime: scheduledTime,
      scheduleEndTime: scheduleEndTime,
      seatCount: seatCount,
      playerQuantity: playerQuantity,
      memberIds: memberIds,
      hostId: hostId,
      status: status ?? this.status,
      depositAmount: depositAmount,
      depositDeadline: depositDeadline ?? this.depositDeadline,
      paymentRef: paymentRef ?? this.paymentRef,
      verificationQrCode: verificationQrCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedInByUserId: checkedInByUserId ?? this.checkedInByUserId,
      lobbySummary: lobbySummary ?? this.lobbySummary,
      depositRefundStatus: depositRefundStatus ?? this.depositRefundStatus,
      depositRefundAmount: depositRefundAmount ?? this.depositRefundAmount,
      isWalkIn: isWalkIn,
      bookingGroupCode: bookingGroupCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        lobbyId,
        cafeId,
        cafeName,
        cafeTableId,
        cafeTableName,
        gameId,
        gameName,
        scheduledTime,
        scheduleEndTime,
        seatCount,
        playerQuantity,
        memberIds,
        hostId,
        status,
        depositAmount,
        depositDeadline,
        paymentRef,
        verificationQrCode,
        createdAt,
        updatedAt,
        checkedInAt,
        checkedInByUserId,
        lobbySummary,
        depositRefundStatus,
        depositRefundAmount,
        isWalkIn,
        bookingGroupCode,
      ];
}
