import 'package:equatable/equatable.dart';

/// Trạng thái ghế ngồi theo business rules (BR-01)
enum CafeSeatStatus {
  available, // Trống khả dụng - có thể đặt
  limited, // Còn ít ghế - nên đặt sớm
  full, // Hết ghế - không thể đặt thêm
}

/// Trạng thái tựa game đã chọn tại quán — map từ
/// `NearbyCafeDto.selectedGameAvailabilityStatus` trong backend response.
enum SelectedGameAvailabilityStatus {
  /// Hộp game đang `Available` (rảnh) — UI: "Còn trống".
  gameAvailable,

  /// Tất cả hộp đang `InUse` — UI: "Chờ game ~X phút".
  waitingForGame,
}

class CafeEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double distanceMeters;
  final int availableTables;
  final bool hasGameInStock;
  final int? estimatedWaitMinutes;
  final double rating;
  final List<String> availableGameIds;

  // ─── Seat-based fields (BR-01) ───────────────────────────────────────
  final int totalSeats; // Tổng số ghế của quán
  final int availableSeats; // Ghế trống khả dụng hiện tại
  final CafeSeatStatus seatStatus; // Trạng thái ghế tổng quan
  final double? depositAmount; // Tiền cọc (VNĐ) - quán tự cấu hình
  final int? depositMinutesLimit; // Thời hạn giữ chỗ (phút) - max 30 (BR-06)
  final String? openingHours; // Giờ mở cửa
  final String? phoneNumber; // Số điện thoại liên hệ

  // ─── NearbyCafeDto fields (board-games nearby API) ──────────────────
  final int availableTableCount;
  final int totalTableCount;
  final int totalGameBoxCount;
  final int availableGameCount;
  final SelectedGameAvailabilityStatus
      selectedGameAvailabilityStatus; // AC 3.2

  const CafeEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.distanceMeters,
    required this.availableTables,
    required this.hasGameInStock,
    this.estimatedWaitMinutes,
    required this.rating,
    required this.availableGameIds,
    // Seat-based fields
    required this.totalSeats,
    required this.availableSeats,
    required this.seatStatus,
    this.depositAmount,
    this.depositMinutesLimit,
    this.openingHours,
    this.phoneNumber,
    // NearbyCafeDto fields
    this.availableTableCount = 0,
    this.totalTableCount = 0,
    this.totalGameBoxCount = 0,
    this.availableGameCount = 0,
    this.selectedGameAvailabilityStatus =
        SelectedGameAvailabilityStatus.gameAvailable,
  });

  /// Backward-compat getter: chuyển `distanceMeters` → `distanceKm` cho UI
  /// cũ vẫn dùng `cafe.distanceKm`.
  double get distanceKm => distanceMeters / 1000.0;

  /// Tính toán trạng thái ghế dựa trên availableSeats / totalSeats
  static CafeSeatStatus calculateSeatStatus(int available, int total) {
    if (available == 0) return CafeSeatStatus.full;
    if (available <= total * 0.2) return CafeSeatStatus.limited;
    return CafeSeatStatus.available;
  }

  /// Tính phần trăm ghế còn trống
  double get availableSeatPercentage =>
      totalSeats > 0 ? (availableSeats / totalSeats) * 100 : 0;

  /// Tính phần trăm bàn còn trống (dùng `availableTableCount/totalTableCount`)
  double get availableTablePercentage =>
      totalTableCount > 0 ? (availableTableCount / totalTableCount) * 100 : 0;

  /// UI helper: có đang chờ game hay không.
  bool get isWaitingForGame =>
      selectedGameAvailabilityStatus ==
      SelectedGameAvailabilityStatus.waitingForGame;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        distanceMeters,
        availableTables,
        hasGameInStock,
        estimatedWaitMinutes,
        rating,
        availableGameIds,
        // Seat-based fields
        totalSeats,
        availableSeats,
        seatStatus,
        depositAmount,
        depositMinutesLimit,
        openingHours,
        phoneNumber,
        // Nearby fields
        availableTableCount,
        totalTableCount,
        totalGameBoxCount,
        availableGameCount,
        selectedGameAvailabilityStatus,
      ];
}
