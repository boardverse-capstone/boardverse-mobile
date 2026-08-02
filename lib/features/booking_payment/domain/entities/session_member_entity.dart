import 'package:equatable/equatable.dart';

/// Trạng thái của một thành viên trong ActiveSession (xem `booking.md` §211-219).
enum SessionMemberStatus {
  /// Đang chơi bình thường.
  active,

  /// Về sớm — Staff đã thực hiện partial-checkout cho member này.
  leftEarly,

  /// Đã thanh toán phần của mình và rời session.
  checkedOut,
}

/// Member trong ActiveSession — mirror `BookingSessionStatusDto.members[]`.
class SessionMemberEntity extends Equatable {
  final String userId;
  final String username;

  final SessionMemberStatus status;

  /// Thời điểm member rời session (khi `status != active`).
  final DateTime? leftAt;

  /// Phần bill mà member này đã trả khi rời sớm.
  final double partialBillAmount;

  /// `true` khi partial bill đã được thanh toán.
  final bool partialBillPaid;

  /// Khi player rời sớm mà tiếp tục chơi ở session khác (BR-III.2 edge case).
  final String? mergedIntoSessionId;

  const SessionMemberEntity({
    required this.userId,
    required this.username,
    required this.status,
    this.leftAt,
    required this.partialBillAmount,
    required this.partialBillPaid,
    this.mergedIntoSessionId,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        status,
        leftAt,
        partialBillAmount,
        partialBillPaid,
        mergedIntoSessionId,
      ];
}
