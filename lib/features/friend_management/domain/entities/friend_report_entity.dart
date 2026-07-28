import 'package:equatable/equatable.dart';

/// Phân loại báo cáo vi phạm — map theo backend enum:
/// `Spam` / `Harassment` / `FakeAccount` / `InappropriateContent` / `Other`.
enum FriendReportCategory {
  spam,
  harassment,
  fakeAccount,
  inappropriateContent,
  inappropriate,
  cheating,
  other,
}

/// Báo cáo vi phạm của current user gửi về một friend.
///
/// BR-FRIEND-REPORT-01: chỉ báo cáo được user đang là bạn (Accepted).
/// BR-FRIEND-REPORT-03: không báo cáo chính mình / Admin.
class FriendReportEntity extends Equatable {
  const FriendReportEntity({
    required this.reportId,
    required this.targetUserId,
    required this.targetUsername,
    required this.category,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  final String reportId;
  final String targetUserId;
  final String targetUsername;
  final FriendReportCategory category;
  final String reason;
  final DateTime createdAt;

  /// Trạng thái backend (raw string). Hiện tại backend không công bố enum cụ
  /// thể nên giữ string — UI chỉ hiển thị, không branch theo giá trị.
  final String status;

  @override
  List<Object?> get props => [
        reportId,
        targetUserId,
        targetUsername,
        category,
        reason,
        createdAt,
        status,
      ];
}
