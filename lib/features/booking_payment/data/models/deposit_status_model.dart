import '../../domain/entities/deposit_status_entity.dart';

/// JSON ↔ Entity cho `DepositStatusEntity` — kết quả của
/// `GET /api/payments/booking-deposit/{id}` (và `/by-order/{orderId}`).
///
/// Đặc tả từ `.agents/docs/apis_docs/payment.md` §"GET /api/payments/booking-deposit/{depositId}":
/// ```json
/// {
///   "id": "<guid>",
///   "orderId": "BV12345678",
///   "activeSessionId": "<guid or null>",
///   "userId": "<guid>",
///   "cafeId": "<guid>",
///   "cafeManagerId": "<guid>",
///   "amount": 20000,
///   "refundedAmount": null,
///   "refundPolicy": "Full",
///   "status": "Paid",
///   "transferContent": "BV12345678",
///   "sePayTransactionId": "TXN-...",
///   "paidAt": "2026-07-21T10:02:00Z",
///   "releasedAt": null,
///   "refundedAt": null,
///   "forfeitedAt": null,
///   "qrUrl": "https://pay.sepay.vn/...",
///   "qrExpiresAt": "2026-07-21T10:07:00Z",
///   "scheduledAt": "2026-07-22T19:00:00Z",
///   "createdAt": "2026-07-21T10:00:00Z",
///   "updatedAt": "2026-07-21T10:02:00Z"
/// }
/// ```
///
/// Backend dùng `id` làm tên trường cho GET (theo swagger), nhưng cũng
/// trả `depositId` ở một số phiên bản (POST response cũ). Hỗ trợ cả hai
/// để không vỡ khi backend đổi.
///
/// Status string đầy đủ: `"Pending" | "Paid" | "Refunded" | "Forfeited" |
/// "Expired" | "Holding"`. Map sang `DepositStatus` enum.
class DepositStatusModel {
  final String depositId;
  final String orderId;
  final String cafeId;
  final String? bookingId;
  final String? cafeName;
  final String status;
  final double amount;
  final double? refundedAmount;
  final String? refundPolicy;
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

  const DepositStatusModel({
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

  factory DepositStatusModel.fromJson(Map<String, dynamic> json) {
    return DepositStatusModel(
      // Ưu tiên `id` (GET response theo swagger), fallback `depositId`
      // (POST response cũ theo payment.md).
      depositId:
          (json['id'] ?? json['depositId'])?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      cafeId: json['cafeId']?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      cafeName: json['cafeName']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble(),
      refundPolicy: json['refundPolicy']?.toString(),
      transferContent: json['transferContent']?.toString(),
      sePayTransactionId: json['sePayTransactionId']?.toString(),
      paidAt: _parse(json['paidAt']),
      refundedAt: _parse(json['refundedAt']),
      forfeitedAt: _parse(json['forfeitedAt']),
      releasedAt: _parse(json['releasedAt']),
      qrExpiresAt: _parse(json['qrExpiresAt']),
      scheduledAt: _parse(json['scheduledAt']),
      activeSessionId: json['activeSessionId']?.toString(),
      createdAt: _parse(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parse(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Map status string từ backend sang [DepositStatus] enum.
  /// Hỗ trợ: `"Pending"`, `"Paid"`, `"Refunded"`, `"Forfeited"`,
  /// `"Expired"`, `"Holding"` (theo payment.md + swagger).
  DepositStatus get statusEnum {
    switch (status) {
      case 'Paid':
        return DepositStatus.paid;
      case 'Refunded':
        return DepositStatus.refunded;
      case 'Forfeited':
        return DepositStatus.forfeited;
      case 'Expired':
        return DepositStatus.expired;
      case 'Holding':
        // Server giữ ghế sau khi regenerate QR; vẫn pending về UI.
        return DepositStatus.pending;
      case 'Pending':
      default:
        return DepositStatus.pending;
    }
  }

  DepositStatusEntity toEntity() => DepositStatusEntity(
        depositId: depositId,
        orderId: orderId,
        cafeId: cafeId,
        bookingId: bookingId,
        cafeName: cafeName,
        status: statusEnum,
        amount: amount,
        refundedAmount: refundedAmount,
        refundPolicy: _parseRefundPolicy(refundPolicy),
        transferContent: transferContent,
        sePayTransactionId: sePayTransactionId,
        paidAt: paidAt,
        refundedAt: refundedAt,
        forfeitedAt: forfeitedAt,
        releasedAt: releasedAt,
        qrExpiresAt: qrExpiresAt,
        scheduledAt: scheduledAt,
        activeSessionId: activeSessionId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Map `refundPolicy` string từ backend (BR-18) sang enum.
  static RefundPolicy? _parseRefundPolicy(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'Full':
        return RefundPolicy.full;
      case 'Partial':
        return RefundPolicy.partial;
      case 'None':
        return RefundPolicy.none;
      default:
        return null;
    }
  }
}