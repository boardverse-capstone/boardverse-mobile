import 'package:equatable/equatable.dart';

/// Kết quả trả về từ `GET /api/bookings/{bookingId}/ratings/status`
/// (xem `.agents/docs/apis_docs/booking-rating.md` §131-159 — gap #5).
///
/// Mobile dùng để quyết định hiển thị form chấm điểm hay ẩn.
class RatingStatusEntity extends Equatable {
  final String bookingId;

  /// Voter có trong cửa sổ vote + chưa rate (khi `alreadyRated=false`).
  final bool canRate;

  /// `ScheduleEndTime + 24h` — null nếu đã aggregate xong.
  final DateTime? rateDeadline;

  /// Voter đã gửi rating trước đó.
  final bool alreadyRated;

  /// Members voter đã rate (kể cả update).
  final List<String> ratedUserIds;

  /// Members chưa được voter rate (gợi ý hiển thị UI).
  final List<String> missingMemberIds;

  const RatingStatusEntity({
    required this.bookingId,
    required this.canRate,
    this.rateDeadline,
    required this.alreadyRated,
    required this.ratedUserIds,
    required this.missingMemberIds,
  });

  @override
  List<Object?> get props => [
        bookingId,
        canRate,
        rateDeadline,
        alreadyRated,
        ratedUserIds,
        missingMemberIds,
      ];
}
