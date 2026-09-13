/// Member payment info trong Split Bill flow
/// Mô tả trạng thái thanh toán của một thành viên trong phiên
class MemberPaymentInfo {
  final String memberId;
  final String? displayName;
  final String? avatarUrl;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final int? amountDue;
  final String? qrUrl;
  final String? qrImageBase64;
  final DateTime? qrExpiresAt;
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
    this.qrExpiresAt,
    this.paidAt,
    this.isCurrentUser = false,
  });

  /// Check if this member has QR payment pending
  bool get hasPendingQr =>
      paymentMethod == PaymentMethod.qrCode &&
      paymentStatus == PaymentStatus.notPaid;

  /// Check if this member has paid
  bool get isPaid =>
      paymentStatus == PaymentStatus.paidCash ||
      paymentStatus == PaymentStatus.paidQr;

  /// Format amount for display
  String get formattedAmountDue {
    if (amountDue == null) return 'N/A';
    return '${(amountDue! / 1000).toStringAsFixed(0)} BVC';
  }

  /// Get remaining time for QR expiry
  Duration? get qrRemainingTime {
    if (qrExpiresAt == null) return null;
    final remaining = qrExpiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time
  String get formattedQrRemainingTime {
    final remaining = qrRemainingTime;
    if (remaining == null) return 'N/A';
    if (remaining == Duration.zero) return 'Đã hết hạn';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
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
