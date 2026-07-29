import 'package:equatable/equatable.dart';

import 'friend_entity.dart';
import 'friend_search_entity.dart';

/// Thông tin public profile của 1 player kèm permission flags.
///
/// Trả về từ `GET /api/v1/friends/{userId}/profile` (xem chi tiết player
/// trước/sau khi kết bạn). Tổng hợp từ UserProfile + FriendshipStatus +
/// MutualFriendsCount + permission flags (canSendFriendRequest, canReport).
///
/// Lưu ý: khác với `UserSearchEntity` (chỉ trả trong list search nhỏ gọn),
/// entity này đầy đủ hơn và có thêm block status, report status, friend
/// details (mutual friend list).
class FriendProfileEntity extends Equatable {
  const FriendProfileEntity({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    this.bio,
    required this.karmaPoints,
    this.gamerTier,
    required this.globalElo,
    required this.level,
    required this.mutualFriendsCount,
    required this.friendshipStatus,
    required this.canSendFriendRequest,
    required this.canReport,
    this.friendsSince,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.mutualFriends = const [],
  });

  final String userId;
  final String username;
  final String avatarUrl;
  final String? bio;
  final int karmaPoints;
  final GamerTier? gamerTier;

  /// ELO toàn cục của player (tính theo matchmaking chung).
  final int globalElo;

  /// Cấp độ hiện tại.
  final int level;

  /// Số bạn chung giữa current user và player này.
  final int mutualFriendsCount;

  /// Quan hệ giữa current user và player.
  final FriendshipStatus friendshipStatus;

  /// Ngày trở thành bạn (chỉ có khi `friendshipStatus == accepted`).
  final DateTime? friendsSince;

  /// `true` nếu current user đã chặn player này.
  final bool isBlockedByMe;

  /// `true` nếu player này đã chặn current user. UI nên disable hầu hết
  /// action khi giá trị này `true` vì current user không thể tương tác.
  final bool hasBlockedMe;

  /// `true` nếu frontend được phép hiển thị nút "Kết bạn" (đã check
  /// privacy + block + friend limit).
  final bool canSendFriendRequest;

  /// `true` nếu frontend được phép hiển thị nút "Báo cáo" (chỉ áp dụng
  /// cho quan hệ Accepted theo BR-FRIEND-REPORT-01).
  final bool canReport;

  /// Danh sách bạn chung (thường chỉ trả một phần nhỏ cho preview).
  final List<MutualFriendSummary> mutualFriends;

  bool get isFriend => friendshipStatus == FriendshipStatus.accepted;
  bool get hasPendingRequest =>
      friendshipStatus == FriendshipStatus.pendingSent ||
      friendshipStatus == FriendshipStatus.pendingReceived;
  bool get canInteract => !isBlockedByMe && !hasBlockedMe;

  @override
  List<Object?> get props => [
        userId,
        username,
        avatarUrl,
        bio,
        karmaPoints,
        gamerTier,
        globalElo,
        level,
        mutualFriendsCount,
        friendshipStatus,
        friendsSince,
        isBlockedByMe,
        hasBlockedMe,
        canSendFriendRequest,
        canReport,
        mutualFriends,
      ];
}

/// Tóm tắt 1 bạn chung trong danh sách mutual — chỉ trả userId/username/
/// avatarUrl để render avatar stack.
class MutualFriendSummary extends Equatable {
  const MutualFriendSummary({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });

  final String userId;
  final String username;
  final String avatarUrl;

  @override
  List<Object?> get props => [userId, username, avatarUrl];
}
