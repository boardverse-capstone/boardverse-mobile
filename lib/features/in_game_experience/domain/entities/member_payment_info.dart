/// Tỷ giá quy đổi: 1 BVC = 1.000 VND.
/// Giữ constant ở đây (đồng bộ với `wallet_entity.dart`) để các
/// widget khác nhau đều dùng cùng một giá trị khi format số tiền.
const int kBvcToVndRate = 1000;

/// Helper format VND theo locale Việt Nam: `150.000 VNĐ`.
/// Tái sử dụng cho mọi chỗ hiển thị tiền trong flow in-game.
String formatVnd(num? vnd) {
  if (vnd == null) return 'N/A';
  final str = vnd.round().toString();
  final result = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      result.write('.');
    }
    result.write(str[i]);
  }
  return '$result VNĐ';
}

/// Helper format BVC theo locale Việt Nam (không có phần thập phân,
/// làm tròn lên — player cần có đủ số BVC tối thiểu mới thanh toán
/// được bằng ví).
String formatBvcCeil(num? vnd) {
  if (vnd == null) return 'N/A';
  final bvc = (vnd / kBvcToVndRate).ceil();
  return '$bvc BVC';
}

/// Member payment info trong Split Bill flow
/// Mô tả trạng thái thanh toán của một thành viên trong phiên
class MemberPaymentInfo {
  final String memberId;
  final String? displayName;
  final String? avatarUrl;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;

  /// Số tiền member này phải trả — đơn vị **VND** (theo backend).
  /// Có thể hiển thị BVC qua [formattedAmountBvc] (1 BVC = 1.000 VND).
  final int? amountDue;

  /// URL ảnh QR thanh toán (từ SePay / VietQR CDN). Mobile có thể
  /// download qua Dio + Chrome UA để bypass CORS.
  final String? qrUrl;

  /// Ảnh QR đã encode Base64 (PNG). Ưu tiên dùng field này trước
  /// `qrUrl` — render trực tiếp, không cần network.
  final String? qrImageBase64;
  final DateTime? paidAt;
  final bool isCurrentUser;

  const MemberPaymentInfo({
    required this.memberId,
    this.displayName,
    this.avatarUrl,
    required this.paymentStatus,
    this.paymentMethod,
    this.amountDue,
    this.qrUrl,
    this.qrImageBase64,
    this.paidAt,
    this.isCurrentUser = false,
  });

  /// Check if this member has QR payment pending
  /// (staff đã tạo QR và member chưa quét).
  bool get hasPendingQr =>
      paymentMethod == PaymentMethod.qrCode &&
      paymentStatus == PaymentStatus.notPaid;

  /// True nếu staff đã tạo QR cho member này (có ảnh QR để hiển thị).
  /// Dùng để quyết định show QR section trong UI.
  bool get hasQr =>
      (qrImageBase64 != null && qrImageBase64!.isNotEmpty) ||
      (qrUrl != null && qrUrl!.isNotEmpty);

  /// Check if this member has paid
  bool get isPaid =>
      paymentStatus == PaymentStatus.paidCash ||
      paymentStatus == PaymentStatus.paidQr;

  /// Hiển thị số tiền dạng VND: `150.000 VNĐ`
  String get formattedAmountVnd => formatVnd(amountDue);

  /// Hiển thị số tiền quy đổi sang BVC (làm tròn lên): `150 BVC`
  /// Dùng kèm với [formattedAmountVnd] cho UX đầy đủ.
  String get formattedAmountBvc => formatBvcCeil(amountDue);

  /// Format gọn cho danh sách member (chỉ BVC) — UI list ngắn gọn.
  String get formattedAmountShort => formattedAmountBvc;
}

/// Payment status enum
enum PaymentStatus {
  notPaid,
  paidQr,
  paidCash,
}

/// Payment method enum
enum PaymentMethod {
  cash,
  qrCode,
}
