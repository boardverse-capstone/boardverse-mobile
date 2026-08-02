import 'package:equatable/equatable.dart';

/// Kết quả trả về từ `GET /api/cafes/{cafeId}/availability`
/// (xem `.agents/docs/apis_docs/cafe-booking.md` §90-114 — gap #2).
///
/// Mobile `BoardGameDetailPage` gọi trước khi navigate sang BookingSummary
/// để cảnh báo "quán hết chỗ" và gợi ý `alternativeSlots` nếu cần.
class CafeAvailabilityEntity extends Equatable {
  final String cafeId;
  final String cafeName;

  final DateTime requestedStartTime;
  final DateTime requestedEndTime;

  /// `true` khi `availableSeats >= seatCount` yêu cầu.
  final bool hasCapacity;

  /// Số ghế trống khả dụng trong khung giờ.
  final int availableSeats;

  /// Tổng ghế của cafe (snapshot).
  final int totalSeats;

  /// Số hộp game Available (chỉ populate khi truyền `gameTemplateId`).
  final int? availableGameBoxCount;

  /// `Available` / `PartiallyAvailable` / `Unavailable` / `NotRequested`.
  final String? selectedGameAvailabilityStatus;

  /// Top khung giờ gần nhất (cách 30 phút) còn capacity — gợi ý cho user.
  final List<AlternativeSlotEntity> alternativeSlots;

  const CafeAvailabilityEntity({
    required this.cafeId,
    required this.cafeName,
    required this.requestedStartTime,
    required this.requestedEndTime,
    required this.hasCapacity,
    required this.availableSeats,
    required this.totalSeats,
    this.availableGameBoxCount,
    this.selectedGameAvailabilityStatus,
    required this.alternativeSlots,
  });

  @override
  List<Object?> get props => [
        cafeId,
        cafeName,
        requestedStartTime,
        requestedEndTime,
        hasCapacity,
        availableSeats,
        totalSeats,
        availableGameBoxCount,
        selectedGameAvailabilityStatus,
        alternativeSlots,
      ];
}

/// Slot thay thế khi `CafeAvailabilityEntity.hasCapacity == false`.
class AlternativeSlotEntity extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final int availableSeats;

  const AlternativeSlotEntity({
    required this.startTime,
    required this.endTime,
    required this.availableSeats,
  });

  @override
  List<Object?> get props => [startTime, endTime, availableSeats];
}
