/// Trạng thái vòng đời `Booking` theo backend (`/api/bookings`).
///
/// Backend trả về 2 cách:
///
/// - `status` (int): 0..4 để so sánh logic.
/// - `statusText` (string): `"PendingDeposit" | "Confirmed" | "CheckedIn" | "NoShow" | "Cancelled"`
///   dùng cho UI.
///
/// Enum này dùng dưới client; map từ int/string trong `BookingModel.fromJson`.
enum BookingStatus {
  /// `0` — Mới từ lobby lock, đang chờ player thanh toán cọc SePay.
  pendingDeposit,

  /// `1` — Đã cọc (hoặc không cần cọc). Chờ check-in tại quán.
  confirmed,

  /// `2` — POS quét `verificationQRCode` → phiên chơi đã mở.
  checkedIn,

  /// `3` — Quá giờ mà chưa check-in. Server tự đánh dấu.
  noShow,

  /// `4` — Bị hủy (player/manager) hoặc server reject.
  cancelled,
}

/// Helper extension cho [BookingStatus].
extension BookingStatusX on BookingStatus {
  /// Int tương ứng trong backend response.
  int get intValue {
    switch (this) {
      case BookingStatus.pendingDeposit:
        return 0;
      case BookingStatus.confirmed:
        return 1;
      case BookingStatus.checkedIn:
        return 2;
      case BookingStatus.noShow:
        return 3;
      case BookingStatus.cancelled:
        return 4;
    }
  }

  /// Map từ int backend (0..4) sang enum. Trả null nếu ngoài phạm vi.
  static BookingStatus? fromInt(int? value) {
    if (value == null) return null;
    if (value == 0) return BookingStatus.pendingDeposit;
    if (value == 1) return BookingStatus.confirmed;
    if (value == 2) return BookingStatus.checkedIn;
    if (value == 3) return BookingStatus.noShow;
    if (value == 4) return BookingStatus.cancelled;
    return null;
  }

  /// Map từ `statusText` (string) sang enum. Trả null nếu không match.
  static BookingStatus? fromStatusText(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'PendingDeposit':
        return BookingStatus.pendingDeposit;
      case 'Confirmed':
        return BookingStatus.confirmed;
      case 'CheckedIn':
        return BookingStatus.checkedIn;
      case 'NoShow':
        return BookingStatus.noShow;
      case 'Cancelled':
        return BookingStatus.cancelled;
    }
    return null;
  }

  /// Trạng thái kết thúc (đã chốt sổ — không có action nào tiếp tục).
  bool get isTerminal =>
      this == BookingStatus.noShow ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.checkedIn;

  /// Trạng thái còn khả năng chuyển sang Confirmed / NoShow.
  bool get isActive =>
      this == BookingStatus.pendingDeposit ||
      this == BookingStatus.confirmed;

  /// Player (host) có thể chủ động hủy.
  bool get canPlayerCancel =>
      this == BookingStatus.pendingDeposit ||
      this == BookingStatus.confirmed;

  /// Nhãn tiếng Việt để render trên UI.
  String get displayLabel {
    switch (this) {
      case BookingStatus.pendingDeposit:
        return 'Chờ đặt cọc';
      case BookingStatus.confirmed:
        return 'Đã đặt cọc';
      case BookingStatus.checkedIn:
        return 'Đã check-in';
      case BookingStatus.noShow:
        return 'Vắng (No-show)';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
