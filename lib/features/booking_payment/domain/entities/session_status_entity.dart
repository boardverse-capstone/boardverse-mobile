import 'package:equatable/equatable.dart';

import 'session_member_entity.dart';

/// Kết quả trả về từ `GET /api/bookings/{bookingId}/session-status`
/// (xem `.agents/docs/apis_docs/booking.md` §191-227 — gap #8).
///
/// Player (lobby member đã check-in) gọi để xem realtime ActiveSession status,
/// đặc biệt khi Staff thực hiện partial-checkout cho 1-2 người về sớm.
class SessionStatusEntity extends Equatable {
  final String bookingId;

  /// ActiveSession id (Guid). Null nếu chưa có session nào được mở.
  final String? activeSessionId;

  /// `Active` / `Paid` / `Cancelled`.
  final String sessionStatus;

  /// Thời điểm Staff mở session (POS check-in thành công).
  final DateTime? startedAt;

  /// Số phút đã trôi qua kể từ `startedAt`.
  final int currentDurationMinutes;

  /// Trạng thái các thành viên trong session.
  final List<SessionMemberEntity> members;

  /// Bill ước tính cuối cùng cho phần còn lại của session.
  final EstimatedBillEntity? estimatedFinalBill;

  const SessionStatusEntity({
    required this.bookingId,
    this.activeSessionId,
    required this.sessionStatus,
    this.startedAt,
    required this.currentDurationMinutes,
    required this.members,
    this.estimatedFinalBill,
  });

  @override
  List<Object?> get props => [
        bookingId,
        activeSessionId,
        sessionStatus,
        startedAt,
        currentDurationMinutes,
        members,
        estimatedFinalBill,
      ];
}

/// Hóa đơn ước tính cuối cùng cho phần còn lại của session.
///
/// Mirror `BookingSessionStatusDto.estimatedFinalBill` (xem `booking.md` §222).
class EstimatedBillEntity extends Equatable {
  final double subtotal;
  final double penalty;

  /// Phần cọc đã áp dụng (BR-09 — lưu ý: backend BR-09 = "không trừ cọc"
  /// nhưng DTO trả về field này để mobile hiển thị).
  final double depositApplied;

  final double total;

  const EstimatedBillEntity({
    required this.subtotal,
    required this.penalty,
    required this.depositApplied,
    required this.total,
  });

  @override
  List<Object?> get props => [subtotal, penalty, depositApplied, total];
}
