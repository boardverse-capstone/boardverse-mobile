import 'package:equatable/equatable.dart';

/// Body gửi lên `POST /api/bookings/{bookingId}/ratings` (gap #5).
///
/// Mỗi voter chấm cho từng thành viên khác trong lobby (không chấm chính mình).
class BookingRatingSubmissionEntity extends Equatable {
  final String bookingId;
  final List<RatingItemEntity> ratings;

  const BookingRatingSubmissionEntity({
    required this.bookingId,
    required this.ratings,
  });

  @override
  List<Object?> get props => [bookingId, ratings];
}

/// Một dòng chấm điểm cho 1 user.
class RatingItemEntity extends Equatable {
  final String ratedUserId;

  /// Thái độ chơi (toxic / fair-play) — 1..5.
  final int attitude;

  /// Tinh thần thể thao — 1..5.
  final int sportsmanship;

  /// Đúng giờ — 1..5.
  final int punctuality;

  /// Nhận xét tự do, tối đa 500 ký tự.
  final String? comment;

  const RatingItemEntity({
    required this.ratedUserId,
    required this.attitude,
    required this.sportsmanship,
    required this.punctuality,
    this.comment,
  });

  @override
  List<Object?> get props => [
        ratedUserId,
        attitude,
        sportsmanship,
        punctuality,
        comment,
      ];
}

/// Kết quả trả về từ `POST .../ratings` (xem `booking-rating.md` §108-120).
class RatingSubmissionResultEntity extends Equatable {
  final String bookingId;
  final String voterId;
  final DateTime submittedAt;
  final int ratedCount;

  const RatingSubmissionResultEntity({
    required this.bookingId,
    required this.voterId,
    required this.submittedAt,
    required this.ratedCount,
  });

  @override
  List<Object?> get props => [bookingId, voterId, submittedAt, ratedCount];
}
