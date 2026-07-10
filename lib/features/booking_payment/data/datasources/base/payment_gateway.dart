import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/enums/payment_method.dart';

/// Sealed class cho kết quả trả về từ `PaymentGateway.watchResult`.
sealed class PaymentResult {
  const PaymentResult();
}

/// Gateway đang chờ người dùng thao tác (chưa success/fail).
class GatewayPending extends PaymentResult {
  const GatewayPending();
}

/// Gateway xác nhận thanh toán thành công.
class GatewaySuccess extends PaymentResult {
  final String transactionRef;
  final DateTime paidAt;

  const GatewaySuccess({required this.transactionRef, required this.paidAt});
}

/// Gateway báo thanh toán thất bại hoặc user huỷ trên gateway.
class GatewayFailed extends PaymentResult {
  final String reason;

  const GatewayFailed({required this.reason});
}

/// Interface trừu tượng hoá cổng thanh toán (VNPay/MoMo/Sandbox).
///
/// Triển khai hiện tại:
/// - `MockPaymentGateway` (giả lập trong process)
/// - `VnpayGateway`, `MomoGateway` — placeholder cho phase tích hợp sau.
abstract class PaymentGateway {
  /// Mở phiên thanh toán. Trả về `transactionRef` dùng để theo dõi kết quả.
  Future<Either<Failure, String>> openGateway({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  });

  /// Theo dõi kết quả — sẽ thay bằng WebSocket ở phase sau.
  Stream<PaymentResult> watchResult(String transactionRef);
}