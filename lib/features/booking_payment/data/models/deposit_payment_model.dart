import '../../domain/entities/deposit_payment_entity.dart';

/// JSON ↔ Entity cho `DepositPaymentEntity` — kết quả của
/// `POST /api/payments/booking-deposit`.
///
/// Đặc tả từ `.agents/docs/apis_docs/payment.md` §"POST /booking-deposit":
/// ```json
/// {
///   "data": {
///     "depositId": "<guid>",
///     "orderId": "BV12345678",
///     "qrUrl": "https://pay.sepay.vn/...",
///     "paymentUrl": "https://pay.sepay.vn/v1/checkout/init?...",
///     "qrExpiresAt": "2026-07-21T10:05:00Z",
///     "amount": 20000,
///     "requiresManualConfirmation": false
///   }
/// }
/// ```
///
/// Một số version backend (theo swagger) trả `id` thay vì `depositId`.
/// Hỗ trợ cả hai để không vỡ khi backend đổi.
class DepositPaymentModel {
  final String depositId;
  final String orderId;
  final String qrUrl;
  final String paymentUrl;
  final DateTime? qrExpiresAt;
  final double amount;
  final bool requiresManualConfirmation;

  const DepositPaymentModel({
    required this.depositId,
    required this.orderId,
    required this.qrUrl,
    required this.paymentUrl,
    required this.qrExpiresAt,
    required this.amount,
    required this.requiresManualConfirmation,
  });

  factory DepositPaymentModel.fromJson(Map<String, dynamic> json) {
    return DepositPaymentModel(
      // Ưu tiên `depositId` (theo payment.md POST), fallback `id`
      // (theo swagger mới).
      depositId: (json['depositId'] ?? json['id'])?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      qrUrl: json['qrUrl']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString() ?? '',
      qrExpiresAt: _parse(json['qrExpiresAt']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      requiresManualConfirmation:
          json['requiresManualConfirmation'] as bool? ?? false,
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

  DepositPaymentEntity toEntity() => DepositPaymentEntity(
        depositId: depositId,
        orderId: orderId,
        qrUrl: qrUrl,
        paymentUrl: paymentUrl,
        qrExpiresAt: qrExpiresAt,
        amount: amount,
        requiresManualConfirmation: requiresManualConfirmation,
      );
}