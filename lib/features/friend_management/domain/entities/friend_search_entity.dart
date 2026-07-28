import 'package:equatable/equatable.dart';

import 'friend_entity.dart';

/// Gợi ý kết bạn — trả về từ `GET /friends/suggestions`.
///
/// Lý do gợi ý (`reason`) do backend quyết định, ví dụ:
/// - "Bạn chung"
/// - "Cùng chơi lobby gần đây"
class FriendSuggestionEntity extends Equatable {
  const FriendSuggestionEntity({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.mutualFriendsCount,
    required this.reason,
    this.gamerTier,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final int mutualFriendsCount;
  final String reason;

  @override
  List<Object?> get props => [
        odId,
        username,
        avatarUrl,
        karmaPoints,
        gamerTier,
        mutualFriendsCount,
        reason,
      ];
}

/// Trạng thái quan hệ giữa current user và user trong kết quả tìm kiếm.
///
/// Frontend dùng enum này (chứ không phải `FriendRequestStatus`) vì kết quả
/// search có thêm khái niệm `pendingReceived` (current user là addressee) và
/// `blocked` để UI biết có hiển thị nút "Kết bạn" hay không.
enum FriendshipStatus {
  /// Chưa có quan hệ.
  none,

  /// Current user đã gửi lời mời nhưng chưa được phản hồi.
  pendingSent,

  /// User khác đã gửi lời mời cho current user.
  pendingReceived,

  /// Đã là bạn bè.
  accepted,

  /// Một trong hai bên đã chặn bên kia.
  blocked,
}

/// Kết quả tìm kiếm user (`GET /friends/search?q=&limit=`).
class UserSearchEntity extends Equatable {
  const UserSearchEntity({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.mutualFriendsCount,
    this.friendshipStatus,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final FriendshipStatus? friendshipStatus;
  final int mutualFriendsCount;

  @override
  List<Object?> get props => [
        odId,
        username,
        avatarUrl,
        karmaPoints,
        friendshipStatus,
        mutualFriendsCount,
      ];
}
