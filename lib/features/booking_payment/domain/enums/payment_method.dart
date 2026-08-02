/// Phương thức thanh toán cọc.
///
/// Hiện tại backend chỉ expose 1 cổng duy nhất là SePay (qua
/// `POST /api/payments/booking-deposit`). Enum để mở rộng sau nếu bổ sung
/// VNPay/MoMo.
enum PaymentMethod {
  /// Thanh toán qua SePay — flow duy nhất hiện tại.
  sepay,
}

/// Helper extension cho [PaymentMethod].
extension PaymentMethodX on PaymentMethod {
  /// Tên hiển thị tiếng Việt.
  String get displayName {
    switch (this) {
      case PaymentMethod.sepay:
        return 'SePay (QR ngân hàng)';
    }
  }

  /// Icon gợi ý cho UI.
  String get iconAsset {
    switch (this) {
      case PaymentMethod.sepay:
        return 'assets/icons/sepay.png';
    }
  }
}
