import 'package:equatable/equatable.dart';

/// Payload trả về từ `POST /api/payments/booking-deposit`
/// (và `POST /booking-deposit/{depositId}/regenerate-qr`).
///
/// Dùng để mở SePay URL qua `url_launcher` và render QR dự phòng.
///
/// `qrExpiresAt` có thể null trong một số flow (ví dụ regenerate-QR
/// lần 2 với SePay fallback) — UI cần fallback dùng `BookingDeposit.createdAt
/// + 5 phút` theo BR-06.
class DepositPaymentEntity extends Equatable {
  final String depositId;
  final String orderId;
  final String qrUrl;
  final String paymentUrl;
  final DateTime? qrExpiresAt;
  final double amount;
  final bool requiresManualConfirmation;

  const DepositPaymentEntity({
    required this.depositId,
    required this.orderId,
    required this.qrUrl,
    required this.paymentUrl,
    required this.qrExpiresAt,
    required this.amount,
    required this.requiresManualConfirmation,
  });

  @override
  List<Object?> get props => [
        depositId,
        orderId,
        qrUrl,
        paymentUrl,
        qrExpiresAt,
        amount,
        requiresManualConfirmation,
      ];
}