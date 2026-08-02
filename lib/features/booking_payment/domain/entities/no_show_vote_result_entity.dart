import 'package:equatable/equatable.dart';

/// Kết quả trả về từ `POST /api/bookings/{bookingId}/no-show-votes`
/// (xem `.agents/docs/apis_docs/booking-rating.md` §41-58 — gap #4).
///
/// Mobile cập nhật UI sau mỗi lần vote để hiển thị progress
/// "2/4 votes đã xác nhận vắng mặt".
class NoShowVoteResultEntity extends Equatable {
  final String bookingId;
  final String voterId;
  final List<String> absentMemberIds;

  /// Map `userId → VoteCountDto` — chi tiết vote cho từng thành viên.
  final Map<String, VoteCountEntity> currentVoteCounts;

  /// Members đã bị xác nhận no-show (absentVotes > totalMembers/2).
  final List<String> noShowConfirmedMembers;

  /// Thời điểm server xử lý vote. Null khi mới ghi nhận, chưa tới ngưỡng.
  final DateTime? processedAt;

  const NoShowVoteResultEntity({
    required this.bookingId,
    required this.voterId,
    required this.absentMemberIds,
    required this.currentVoteCounts,
    required this.noShowConfirmedMembers,
    this.processedAt,
  });

  @override
  List<Object?> get props => [
        bookingId,
        voterId,
        absentMemberIds,
        currentVoteCounts,
        noShowConfirmedMembers,
        processedAt,
      ];
}

/// Số vote vắng mặt / có mặt cho 1 thành viên cụ thể
/// (xem `booking-rating.md` §51-53).
class VoteCountEntity extends Equatable {
  final int absentVotes;
  final int presentVotes;
  final int totalMembers;

  const VoteCountEntity({
    required this.absentVotes,
    required this.presentVotes,
    required this.totalMembers,
  });

  @override
  List<Object?> get props => [absentVotes, presentVotes, totalMembers];
}
