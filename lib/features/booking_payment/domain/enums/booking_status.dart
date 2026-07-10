/// Trạng thái vòng đời của đơn đặt chỗ (BR-05, BR-06).
///
/// Khớp với đặc tả `state.md` mục "1. Trạng thái Đơn đặt chỗ".
enum BookingStatus {
  /// Đã tạo đơn, đang chờ thanh toán cọc. Ghế được giữ tạm (BR-06).
  pendingDeposit,

  /// Thanh toán thành công — Host đã đóng cọc.
  confirmed,

  /// Nhân viên POS đã quét QR check-in cho cả nhóm (Task 4).
  checkedIn,

  /// Hết thời hạn giữ chỗ theo BR-06 (mặc định ≤ 30 phút).
  expired,

  /// Host chủ động hủy trước khi đến quán.
  cancelledByPlayer,

  /// Quán đối tác hủy (qua Web POS) — out of scope Task 2,
  /// chỉ nhận qua polling ở Task 4.
  cancelledByCafe,
}

/// Helper extension cho [BookingStatus].
extension BookingStatusX on BookingStatus {
  /// Trạng thái kết thúc (không còn thao tác nào được).
  bool get isTerminal =>
      this == BookingStatus.expired ||
      this == BookingStatus.cancelledByPlayer ||
      this == BookingStatus.cancelledByCafe ||
      this == BookingStatus.checkedIn;

  /// Trạng thái còn khả năng chuyển tiếp sang `confirmed` / `expired`.
  bool get isActive =>
      this == BookingStatus.pendingDeposit ||
      this == BookingStatus.confirmed;

  /// Trạng thái cho phép Host chủ động hủy.
  bool get canPlayerCancel =>
      this == BookingStatus.pendingDeposit ||
      this == BookingStatus.confirmed;

  /// Nhãn tiếng Việt để hiển thị trên UI.
  String get displayLabel {
    switch (this) {
      case BookingStatus.pendingDeposit:
        return 'Chờ đặt cọc';
      case BookingStatus.confirmed:
        return 'Đã đặt cọc';
      case BookingStatus.checkedIn:
        return 'Đã check-in';
      case BookingStatus.expired:
        return 'Quá hạn giữ chỗ';
      case BookingStatus.cancelledByPlayer:
        return 'Đã hủy';
      case BookingStatus.cancelledByCafe:
        return 'Quán đã hủy';
    }
  }
}