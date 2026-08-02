import 'package:equatable/equatable.dart';

/// Trạng thái đơn cọc từ backend `BookingDepositResponseDto`.
///
/// Không trùng với `BookingStatus` — đơn cọc là resource riêng (track
/// thanh toán SePay), booking gắn với nó qua `bookingId`.
enum DepositStatus {
  /// Server vừa tạo đơn cọc, QR còn hiệu lực (≤ 5 phút BR-06).
  pending,

  /// SePay webhook xác nhận thanh toán thành công.
  paid,

  /// Manager/Admin đã hoàn cọc.
  refunded,

  /// Policy = None → cọc bị forfeit.
  forfeited,

  /// QR hết hạn (5 phút trôi qua) — server release ghế.
  expired,
}

/// Extension kiểm tra trạng thái refund để render banner trên UI.
extension DepositStatusX on DepositStatus {
  /// `true` khi UI nên hiển thị banner hoàn cọc/tịch thu.
  bool get isRefundRelevant =>
      this == DepositStatus.refunded || this == DepositStatus.forfeited;
}

/// Kết quả refund theo `DepositRefundPolicy` (BR-18) từ backend.
enum RefundPolicy {
  /// Hoàn 100% `Amount` — quán huỷ vì bất khả kháng.
  full,

  /// Hoàn theo elapsed time: ≥24h → 50%, ≥12h → 25%, <12h → 0%.
  partial,

  /// Tịch thu 100%, status chuyển sang `Forfeited`.
  none,
}

class DepositStatusEntity extends Equatable {
  final String depositId;
  final String orderId;
  final String cafeId;

  /// `bookingId` mà deposit này phục vụ — dùng để resume flow.
  final String? bookingId;

  /// Tên quán (optional — backend có thể không trả, fallback ở UI).
  final String? cafeName;

  final DepositStatus status;
  final double amount;
  final double? refundedAmount;
  final RefundPolicy? refundPolicy;
  final String? transferContent;
  final String? sePayTransactionId;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final DateTime? forfeitedAt;
  final DateTime? releasedAt;
  final DateTime? qrExpiresAt;
  final DateTime? scheduledAt;
  final String? activeSessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepositStatusEntity({
    required this.depositId,
    required this.orderId,
    required this.cafeId,
    this.bookingId,
    this.cafeName,
    required this.status,
    required this.amount,
    this.refundedAmount,
    this.refundPolicy,
    this.transferContent,
    this.sePayTransactionId,
    this.paidAt,
    this.refundedAt,
    this.forfeitedAt,
    this.releasedAt,
    this.qrExpiresAt,
    this.scheduledAt,
    this.activeSessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Trả về `true` khi đơn cọc đã ở trạng thái cuối (không cần polling).
  bool get isTerminal =>
      status == DepositStatus.paid ||
      status == DepositStatus.refunded ||
      status == DepositStatus.forfeited ||
      status == DepositStatus.expired;

  /// Trả về `true` khi QR đã hết hạn (BR-06) — UI nên gọi regenerate.
  bool get isQrExpired {
    final exp = qrExpiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp) && status == DepositStatus.pending;
  }

  @override
  List<Object?> get props => [
        depositId,
        orderId,
        cafeId,
        bookingId,
        cafeName,
        status,
        amount,
        refundedAmount,
        refundPolicy,
        transferContent,
        sePayTransactionId,
        paidAt,
        refundedAt,
        forfeitedAt,
        releasedAt,
        qrExpiresAt,
        scheduledAt,
        activeSessionId,
        createdAt,
        updatedAt,
      ];
}