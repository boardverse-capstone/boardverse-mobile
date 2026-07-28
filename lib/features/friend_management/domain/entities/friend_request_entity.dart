import 'package:equatable/equatable.dart';

/// Trạng thái của một lời mời kết bạn.
///
/// Backend trả (theo `.agents/docs/lobby_docs/friend.md`):
/// - `Pending` — chờ phản hồi.
/// - `Accepted` — quan hệ được accept.
/// - `Declined` — bị từ chối.
/// - `Removed` — đã xóa (unfriend hoặc cancel).
/// - `Expired` — hết hạn (mặc định 30 ngày).
enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  removed,
  expired,
}

/// Lời mời kết bạn — dùng cho cả inbox (received) và outbox (sent).
class FriendRequestEntity extends Equatable {
  const FriendRequestEntity({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.isRead = false,
    this.mutualFriendsCount,
  });

  final String requestId;
  final String requesterId;
  final String requesterName;
  final String requesterAvatar;
  final String? message;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRead;
  final int? mutualFriendsCount;

  @override
  List<Object?> get props => [
        requestId,
        requesterId,
        requesterName,
        requesterAvatar,
        message,
        status,
        createdAt,
        expiresAt,
        isRead,
        mutualFriendsCount,
      ];
}
