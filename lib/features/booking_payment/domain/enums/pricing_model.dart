/// Mô hình biểu phí của quán (BR-01).
enum PricingModel {
  /// Tính tiền theo khối thời gian (Giá giờ đầu + Giá lũy tiến).
  hourly,

  /// Thu phí cố định duy nhất (giờ đầu = vé vào cổng, các block sau = 0đ).
  flatEntry,
}