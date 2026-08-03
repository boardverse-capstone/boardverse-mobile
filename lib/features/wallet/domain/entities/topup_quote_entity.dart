import 'package:equatable/equatable.dart';

/// Kết quả tạo đơn top-up qua SePay (BR §2.1)
///
/// Sau khi tạo top-up, backend trả về:
/// - `paymentUrl`: URL để mở SePay thanh toán
/// - `qrUrl`: URL QR code
/// - `orderId`: Mã đơn (prefix "BVC-")
/// - `expectedBvc`: Số BVC dự kiến nhận được
/// - `expiresAt`: Thời hạn thanh toán
class TopUpQuoteEntity extends Equatable {
  /// URL thanh toán SePay
  final String paymentUrl;

  /// URL QR code (render được)
  final String qrUrl;

  /// Mã đơn hàng (prefix "BVC-")
  final String orderId;

  /// Số BVC dự kiến nhận được (= amountVnd / 1000)
  final int expectedBvc;

  /// Thời hạn thanh toán (thường 15 phút)
  final DateTime expiresAt;

  /// Idempotency key đã dùng (để retry nếu cần)
  final String idempotencyKey;

  const TopUpQuoteEntity({
    required this.paymentUrl,
    required this.qrUrl,
    required this.orderId,
    required this.expectedBvc,
    required this.expiresAt,
    required this.idempotencyKey,
  });

  /// Số VND đã nạp
  int get amountVnd => expectedBvc * 1000;

  /// Kiểm tra QR còn hạn không
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Thời gian còn lại (Duration)
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  @override
  List<Object?> get props => [
        paymentUrl,
        qrUrl,
        orderId,
        expectedBvc,
        expiresAt,
        idempotencyKey,
      ];
}
