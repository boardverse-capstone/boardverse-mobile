import 'package:equatable/equatable.dart';

/// Trạng thái hoạt động (presence) của friend.
///
/// Backend trả (theo `.agents/docs/lobby_docs/friend.md`):
/// - `Online` — lastActiveAt ≤ 5 phút.
/// - `RecentlyActive` — ≤ 1 giờ.
/// - `Away` — ≤ 7 ngày.
/// - `Offline` — chưa từng online hoặc > 7 ngày.
enum ActivityStatus {
  online,
  recentlyActive,
  away,
  offline,
}

/// Hạng gamer dựa trên karma points.
enum GamerTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Một người bạn trong quan hệ Accepted.
///
/// Sử dụng trong:
/// - Danh sách bạn bè (`GET /friends`)
/// - Danh sách có activity (`GET /friends/activity`)
/// - Bạn chung (`GET /friends/{id}/mutual`)
class FriendEntity extends Equatable {
  const FriendEntity({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.gamerTier,
    this.friendsSince,
    this.activityStatus,
    this.lastActiveAt,
    this.mutualFriendsCount,
    this.isInLobby = false,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final DateTime? friendsSince;
  final ActivityStatus? activityStatus;
  final DateTime? lastActiveAt;
  final int? mutualFriendsCount;
  final bool isInLobby;

  bool get isOnline => activityStatus == ActivityStatus.online;

  @override
  List<Object?> get props => [
        odId,
        username,
        avatarUrl,
        karmaPoints,
        gamerTier,
        friendsSince,
        activityStatus,
        lastActiveAt,
        mutualFriendsCount,
        isInLobby,
      ];
}
