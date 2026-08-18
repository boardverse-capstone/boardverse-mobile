import '../../domain/entities/lobby_invitable_friend.dart';
import '../../domain/entities/lobby_invite_entity.dart';

/// Model cho `LobbyInvitableFriendDto` từ backend.
class LobbyInvitableFriendModel {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final int karmaPoints;
  final String? gamerTier;
  final String? activityStatus;
  final DateTime? lastActiveAt;
  final DateTime friendsSince;
  final LobbyInviteFriendStatus inviteStatus;
  final String? latestInviteId;
  final LobbyInviteStatus? latestInviteStatus;
  final bool isInLobby;
  final bool hasPendingInvite;
  final bool isBlocked;

  const LobbyInvitableFriendModel({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.gamerTier,
    required this.activityStatus,
    required this.lastActiveAt,
    required this.friendsSince,
    required this.inviteStatus,
    required this.latestInviteId,
    required this.latestInviteStatus,
    required this.isInLobby,
    required this.hasPendingInvite,
    required this.isBlocked,
  });

  factory LobbyInvitableFriendModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      // Strip trailing 'Z' để parse thành local time thay vì UTC
      final s = v.toString();
      final normalized = s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
      return DateTime.tryParse(normalized);
    }

    return LobbyInvitableFriendModel(
      userId: (json['userId'] ?? '').toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      karmaPoints: (json['karmaPoints'] as num?)?.toInt() ?? 0,
      gamerTier: json['gamerTier']?.toString(),
      activityStatus: json['activityStatus']?.toString(),
      lastActiveAt: parseDate(json['lastActiveAt']),
      friendsSince:
          parseDate(json['friendsSince']) ?? DateTime.now(),
      inviteStatus: LobbyInviteFriendStatus.fromString(
        json['inviteStatus']?.toString(),
      ),
      latestInviteId: json['latestInviteId']?.toString(),
      latestInviteStatus: json['latestInviteStatus'] != null
          ? LobbyInviteStatus.fromString(json['latestInviteStatus'].toString())
          : null,
      isInLobby: (json['isInLobby'] as bool?) ?? false,
      hasPendingInvite: (json['hasPendingInvite'] as bool?) ?? false,
      isBlocked: (json['isBlocked'] as bool?) ?? false,
    );
  }

  LobbyInvitableFriend toEntity() => LobbyInvitableFriend(
    userId: userId,
    username: username ?? 'Người dùng',
    avatarUrl: avatarUrl,
    karmaPoints: karmaPoints,
    gamerTier: gamerTier,
    activityStatus: activityStatus,
    lastActiveAt: lastActiveAt,
    friendsSince: friendsSince,
    inviteStatus: inviteStatus,
    latestInviteId: latestInviteId,
    latestInviteStatus: latestInviteStatus,
    isInLobby: isInLobby,
    hasPendingInvite: hasPendingInvite,
    isBlocked: isBlocked,
  );
}
