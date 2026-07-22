import 'package:equatable/equatable.dart';

/// Activity status cho friend presence.
enum ActivityStatus {
  online, // lastActiveAt ≤ 5 phút
  recentlyActive, // ≤ 1 giờ
  away, // ≤ 7 ngày
  offline, // > 7 ngày hoặc chưa online
}

/// Gamer tier dựa trên karma points.
enum GamerTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Friend entity - represents a friend relationship.
class FriendEntity extends Equatable {
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

/// Friend request entity cho friend request inbox/outbox.
class FriendRequestEntity extends Equatable {
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

  const FriendRequestEntity({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.isRead = false,
    this.mutualFriendsCount,
  });

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

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  removed,
  expired,
}

/// Friend suggestion entity.
class FriendSuggestionEntity extends Equatable {
  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final int mutualFriendsCount;
  final String reason;

  const FriendSuggestionEntity({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.gamerTier,
    required this.mutualFriendsCount,
    required this.reason,
  });

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

/// User search result entity.
class UserSearchEntity extends Equatable {
  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final FriendshipStatus? friendshipStatus;
  final int mutualFriendsCount;

  const UserSearchEntity({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.friendshipStatus,
    required this.mutualFriendsCount,
  });

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

enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  accepted,
  blocked,
}
