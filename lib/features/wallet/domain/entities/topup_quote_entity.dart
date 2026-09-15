import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Kết quả tạo đơn top-up qua SePay.
///
/// Backend trả về `paymentUrl`, `qrUrl` và (tùy phiên bản) `qrImageBase64`.
/// `qrImageBase64` được ưu tiên vì render được trên Flutter Web mà không
/// cần lo CORS.
class TopUpQuoteEntity extends Equatable {
  /// URL thanh toán SePay.
  final String paymentUrl;

  /// URL ảnh QR từ SePay/vietqr CDN.
  final String qrUrl;

  /// Ảnh QR PNG đã encode Base64 — backend proxy từ vietqr.app
  /// server-side. Có thể null với backend cũ.
  final String? qrImageBase64;

  /// Mã đơn hàng (prefix "BVC-").
  final String orderId;

  /// ID định danh đơn top-up — cần để gọi DELETE/PATCH endpoint.
  /// Có thể null khi backend chưa trả Guid; khi đó UI không thể cancel/
  /// update qua PATCH/DELETE và sẽ thử lại với `orderId` hoặc thất bại.
  final String? topUpId;

  /// Số BVC dự kiến nhận được (= amountVnd / 1000).
  final int expectedBvc;

  /// Thời hạn thanh toán.
  final DateTime expiresAt;

  /// Idempotency key đã dùng.
  final String idempotencyKey;

  const TopUpQuoteEntity({
    required this.paymentUrl,
    required this.qrUrl,
    required this.qrImageBase64,
    required this.orderId,
    required this.topUpId,
    required this.expectedBvc,
    required this.expiresAt,
    required this.idempotencyKey,
  });

  /// Số VND đã nạp.
  int get amountVnd => expectedBvc * 1000;

  /// QR còn hạn không.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// `true` khi có giá trị dùng được cho DELETE/PATCH.
  bool get hasTopUpId {
    final id = topUpId;
    return id != null && id.isNotEmpty;
  }

  /// Decode `qrImageBase64` → `Uint8List` PNG bytes. Trả về null nếu
  /// rỗng hoặc không phải base64 hợp lệ.
  Uint8List? get qrImageBytes {
    final base64 = qrImageBase64;
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        paymentUrl,
        qrUrl,
        qrImageBase64,
        orderId,
        topUpId,
        expectedBvc,
        expiresAt,
        idempotencyKey,
      ];
}
