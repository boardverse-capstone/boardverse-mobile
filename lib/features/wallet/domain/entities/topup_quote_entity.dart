import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Kết quả tạo đơn top-up qua SePay (BR §2.1)
///
/// Sau khi tạo top-up, backend trả về:
/// - `paymentUrl`: URL để mở SePay thanh toán
/// - `qrUrl`: URL QR code (URL của ảnh QR) — dùng để hiển thị trong app
/// - `qrImageBase64`: Ảnh QR PNG đã encode Base64 (backend proxy từ
///   vietqr.app server-side). Hiển thị trực tiếp được trên Flutter Web
///   không cần lo CORS.
/// - `orderId`: Mã đơn (prefix "BVC-")
/// - `topUpId`: Guid của BvcTopUpRequest — cần để gọi DELETE/PATCH
/// - `expectedBvc`: Số BVC dự kiến nhận được
/// - `expiresAt`: Thời hạn thanh toán
class TopUpQuoteEntity extends Equatable {
  /// URL thanh toán SePay
  final String paymentUrl;

  /// URL QR code (ảnh QR từ SePay)
  final String qrUrl;

  /// Ảnh QR PNG đã encode Base64 — backend proxy từ vietqr.app server-side.
  ///
  /// Tại sao cần? `vietqr.app` CDN không trả CORS header → Flutter Web
  /// không thể load ảnh từ `qrUrl` qua `Image.network`/`Dio`. Backend
  /// giải quyết bằng cách fetch ảnh server-side (không có CORS) và
  /// embed base64 trong JSON response.
  ///
  /// Có thể `null` khi:
  /// - Backend cũ chưa hỗ trợ (legacy)
  /// - Backend proxy thất bại (vietqr.app timeout/5xx) khi tạo đơn
  ///   → client fallback: gọi `GET /wallet/topup/{orderId}/qr-image`
  ///   hoặc dùng `QrImageView` local từ `paymentUrl`.
  final String? qrImageBase64;

  /// Mã đơn hàng (prefix "BVC-")
  final String orderId;

  /// Guid của BvcTopUpRequest — cần để gọi DELETE/PATCH endpoint.
  ///
  /// **Có thể null** khi backend Swagger phiên bản hiện tại chưa trả field
  /// `topUpId` trong `TopUpResponseDto` (xem `.agents/docs/apis_docs/wallet.md`).
  /// Khi null, các action "Hủy đơn" / "Đổi số tiền" bị disable vì backend
  /// cần Guid để xác định đơn (gọi bằng `orderId` "BVC-..." sẽ 404).
  ///
  /// Tạm thời để nullable để app không crash; backend team cần thêm
  /// field `topUpId` (Guid) vào response của POST/PATCH `/api/v1/wallet/topup`.
  final String? topUpId;

  /// Số BVC dự kiến nhận được (= amountVnd / 1000)
  final int expectedBvc;

  /// Thời hạn thanh toán
  final DateTime expiresAt;

  /// Idempotency key đã dùng (để retry nếu cần)
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

  /// Số VND đã nạp
  int get amountVnd => expectedBvc * 1000;

  /// Kiểm tra QR còn hạn không
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// `true` khi backend trả về `topUpId` hợp lệ (Guid hoặc fallback orderId).
  ///
  /// Logic:
  /// - **Guid format** (8-4-4-4-12 hex): backend đã trả field chuẩn → ưu tiên.
  /// - **orderId fallback** (model gán `topUpId = orderId` khi backend
  ///   chưa trả Guid): vẫn cho phép gọi PATCH/DELETE. Nếu backend thực sự
  ///   yêu cầu Guid strict, PATCH/DELETE sẽ 404 và UI sẽ nhận error.
  /// - **Không có gì**: false → disable buttons.
  bool get hasTopUpId {
    final id = topUpId;
    if (id == null || id.isEmpty) return false;

    // Guid 36 ký tự: 8-4-4-4-12 — backend trả đúng field.
    final guidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (guidRegex.hasMatch(id)) return true;

    // Fallback orderId: chấp nhận hex không gạch ngang (vd "DD71ADF68972B219C6")
    // hoặc "BVC-..." — caller sẽ nhận error 404 nếu backend yêu cầu Guid.
    return id.isNotEmpty;
  }

  /// Decode `qrImageBase64` → `Uint8List` PNG bytes.
  ///
  /// Trả về `null` nếu:
  /// - `qrImageBase64` null/rỗng
  /// - Chuỗi không phải base64 hợp lệ
  ///
  /// UI client không cần catch exception — fallback chain (xem
  /// `QrNetworkImage`) sẽ tự xử lý khi bytes null.
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
