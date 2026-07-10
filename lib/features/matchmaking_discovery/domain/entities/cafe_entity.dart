import 'package:equatable/equatable.dart';

/// Trạng thái ghế ngồi theo business rules (BR-01)
enum CafeSeatStatus {
  available,   // Trống khả dụng - có thể đặt
  limited,    // Còn ít ghế - nên đặt sớm
  full,       // Hết ghế - không thể đặt thêm
}

class CafeEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double distanceKm;
  final int availableTables;
  final bool hasGameInStock;
  final int? estimatedWaitMinutes;
  final double rating;
  final List<String> availableGameIds;

  // ─── Seat-based fields (BR-01) ───────────────────────────────────────
  final int totalSeats;            // Tổng số ghế của quán
  final int availableSeats;       // Ghế trống khả dụng hiện tại
  final CafeSeatStatus seatStatus; // Trạng thái ghế tổng quan
  final double? depositAmount;     // Tiền cọc (VNĐ) - quán tự cấu hình
  final int? depositMinutesLimit;  // Thời hạn giữ chỗ (phút) - max 30 (BR-06)
  final String? openingHours;      // Giờ mở cửa
  final String? phoneNumber;       // Số điện thoại liên hệ

  const CafeEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.distanceKm,
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
  });

  /// Tính toán trạng thái ghế dựa trên availableSeats / totalSeats
  static CafeSeatStatus calculateSeatStatus(int available, int total) {
    if (available == 0) return CafeSeatStatus.full;
    if (available <= total * 0.2) return CafeSeatStatus.limited;
    return CafeSeatStatus.available;
  }

  /// Tính phần trăm ghế còn trống
  double get availableSeatPercentage =>
      totalSeats > 0 ? (availableSeats / totalSeats) * 100 : 0;

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        distanceKm,
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
      ];
}
