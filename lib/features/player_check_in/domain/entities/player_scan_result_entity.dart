import '../../../reservation/domain/entities/entities.dart' as res;

/// Response từ `POST /api/check-in/scan-qr` (BR §21A.7 — PlayerCheckInController).
///
/// Backend trả về thông tin tối thiểu cần thiết để client hiển thị trang
/// "Vừa check-in thành công" và navigate sang InGameSessionPage.
class PlayerScanResultEntity {
  /// Id của ActiveSession mới tạo.
  final String activeSessionId;

  /// Reservation liên kết với check-in.
  final String reservationId;

  final String cafeId;

  /// Thời điểm backend xác nhận check-in.
  final DateTime checkedInAt;

  /// Trạng thái reservation do backend cập nhật — thường là
  /// `ReservationStatus.checkedIn` khi lần scan đầu tiên thành công,
  /// hoặc có thể vẫn là `confirmed` nếu backend chỉ tạo session mà chưa
  /// ghi nhận member. Một số backend trả về status hiện tại kèm theo để
  /// client đồng bộ UI mà không cần poll thêm lần nữa.
  final res.ReservationStatus? reservationStatus;

  const PlayerScanResultEntity({
    required this.activeSessionId,
    required this.reservationId,
    required this.cafeId,
    required this.checkedInAt,
    this.reservationStatus,
  });
}
