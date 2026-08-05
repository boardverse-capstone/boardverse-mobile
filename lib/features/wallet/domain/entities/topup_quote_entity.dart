import 'package:equatable/equatable.dart';

/// Kết quả tạo đơn top-up qua SePay (BR §2.1)
///
/// Sau khi tạo top-up, backend trả về:
/// - `paymentUrl`: URL để mở SePay thanh toán
/// - `qrUrl`: URL QR code (URL của ảnh QR) — dùng để hiển thị trong app
/// - `orderId`: Mã đơn (prefix "BVC-")
/// - `topUpId`: Guid của BvcTopUpRequest — cần để gọi DELETE/PATCH
/// - `expectedBvc`: Số BVC dự kiến nhận được
/// - `expiresAt`: Thời hạn thanh toán
class TopUpQuoteEntity extends Equatable {
  /// URL thanh toán SePay
  final String paymentUrl;

  /// URL QR code (ảnh QR từ SePay)
  final String qrUrl;

  /// Mã đơn hàng (prefix "BVC-")
  final String orderId;

  /// Guid của BvcTopUpRequest — cần để cancel/update đơn
  final String topUpId;

  /// Số BVC dự kiến nhận được (= amountVnd / 1000)
  final int expectedBvc;

  /// Thời hạn thanh toán
  final DateTime expiresAt;

  /// Idempotency key đã dùng (để retry nếu cần)
  final String idempotencyKey;

  const TopUpQuoteEntity({
    required this.paymentUrl,
    required this.qrUrl,
    required this.orderId,
    required this.topUpId,
    required this.expectedBvc,
    required this.expiresAt,
    required this.idempotencyKey,
  });

  /// Số VND đã nạp
  int get amountVnd => expectedBvc * 1000;

  /// Kiểm tra QR còn hạn không
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        paymentUrl,
        qrUrl,
        orderId,
        topUpId,
        expectedBvc,
        expiresAt,
        idempotencyKey,
      ];
}
