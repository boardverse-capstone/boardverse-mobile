import 'package:equatable/equatable.dart';

/// Trạng thái chi tiết của từng ghế ngồi (BR-01)
enum SeatSlotStatus {
  available,  // Trống khả dụng - có thể đặt trực tuyến
  holding,    // Đang giữ chờ payment (5 phút)
  reserved,   // Đã đặt cọc thành công
  inUse,      // Đang có người chơi
}

/// Trạng thái ghế tổng quan để hiển thị UI
enum SeatOverallStatus {
  plenty,    // Nhiều ghế trống (>50%)
  moderate,  // Vừa đủ (20-50%)
  limited,   // Ít ghế (<20%)
  unavailable, // Hết ghế (0%)
}

/// Entity mô tả thông tin ghế ngồi thời gian thực của một quán
class SeatAvailabilityEntity extends Equatable {
  final String cafeId;
  final String cafeName;
  final int totalSeats;
  final int availableSeats;
  final int holdingSeats;   // Ghế đang chờ payment
  final int reservedSeats;  // Ghế đã đặt cọc
  final int inUseSeats;     // Ghế đang sử dụng
  final SeatOverallStatus overallStatus;
  final DateTime lastUpdated;
  final DateTime? nextAvailableAt; // Giờ ghế sẽ trống (nếu đầy)

  const SeatAvailabilityEntity({
    required this.cafeId,
    required this.cafeName,
    required this.totalSeats,
    required this.availableSeats,
    required this.holdingSeats,
    required this.reservedSeats,
    required this.inUseSeats,
    required this.overallStatus,
    required this.lastUpdated,
    this.nextAvailableAt,
  });

  /// Kiểm tra xem có đủ ghế cho số lượng yêu cầu không (BR-05)
  bool hasEnoughSeats(int requiredSeats) => availableSeats >= requiredSeats;

  /// Tính phần trăm ghế trống
  double get availablePercentage =>
      totalSeats > 0 ? (availableSeats / totalSeats) * 100 : 0;

  /// Tính toán trạng thái tổng quan
  static SeatOverallStatus calculateStatus(int available, int total) {
    if (total == 0) return SeatOverallStatus.unavailable;
    final percentage = (available / total) * 100;
    if (percentage == 0) return SeatOverallStatus.unavailable;
    if (percentage < 20) return SeatOverallStatus.limited;
    if (percentage <= 50) return SeatOverallStatus.moderate;
    return SeatOverallStatus.plenty;
  }

  @override
  List<Object?> get props => [
        cafeId,
        cafeName,
        totalSeats,
        availableSeats,
        holdingSeats,
        reservedSeats,
        inUseSeats,
        overallStatus,
        lastUpdated,
        nextAvailableAt,
      ];
}
