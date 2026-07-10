/// Phương thức thanh toán cọc mà Host có thể chọn.
///
/// Hiện tại chỉ hỗ trợ `sandboxMock`. Các giá trị khác đặt sẵn để
/// khi tích hợp SDK VNPay / MoMo chỉ cần thêm implementation
/// tương ứng ở tầng Data mà không phải đổi enum.
enum PaymentMethod {
  /// Giả lập thanh toán — không qua cổng thật, dùng cho dev/test.
  sandboxMock,

  /// Tích hợp VNPay (placeholder — chưa impl trong Task 2).
  vnpay,

  /// Tích hợp MoMo (placeholder — chưa impl trong Task 2).
  momo,
}

/// Helper extension cho [PaymentMethod].
extension PaymentMethodX on PaymentMethod {
  /// Tên hiển thị tiếng Việt.
  String get displayName {
    switch (this) {
      case PaymentMethod.sandboxMock:
        return 'Thanh toán mô phỏng (Dev)';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.momo:
        return 'MoMo';
    }
  }

  /// Icon gợi ý cho UI.
  String get iconAsset {
    switch (this) {
      case PaymentMethod.sandboxMock:
        return 'assets/icons/payment_sandbox.png';
      case PaymentMethod.vnpay:
        return 'assets/icons/vnpay.png';
      case PaymentMethod.momo:
        return 'assets/icons/momo.png';
    }
  }
}