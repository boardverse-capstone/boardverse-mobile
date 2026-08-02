import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/booking_rating_submission_entity.dart';
import '../../../domain/entities/no_show_vote_result_entity.dart';
import '../../../domain/entities/rating_status_entity.dart';

/// API cho NoShow voting + Cross-rating (xem `.agents/docs/apis_docs/booking-rating.md`,
/// gaps #4 + #5).
///
/// Tất cả endpoint yêu cầu user là lobby member của booking.
abstract class BookingRatingRemoteDatasource {
  /// POST /api/bookings/{bookingId}/no-show-votes (gap #4).
  ///
  /// Idempotent: vote lần 2 sẽ UPDATE vote trước.
  Future<Either<Failure, NoShowVoteResultEntity>> submitNoShowVote({
    required String bookingId,
    required List<String> absentMemberIds,
    DateTime? votedAt,
  });

  /// POST /api/bookings/{bookingId}/ratings (gap #5).
  ///
  /// Voter chấm cho từng thành viên khác trong lobby (không chấm chính mình).
  /// Mỗi `ratedUserId` chỉ chấm 1 lần (vote lần 2 sẽ UPDATE).
  Future<Either<Failure, RatingSubmissionResultEntity>> submitRatings(
    BookingRatingSubmissionEntity submission,
  );

  /// GET /api/bookings/{bookingId}/ratings/status (gap #5).
  ///
  /// Mobile dùng để quyết định hiển thị form chấm điểm hay ẩn.
  Future<Either<Failure, RatingStatusEntity>> getRatingStatus(
    String bookingId,
  );
}
