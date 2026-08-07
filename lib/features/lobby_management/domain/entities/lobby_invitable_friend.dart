import 'package:equatable/equatable.dart';

import 'lobby_invite_entity.dart';

/// Trạng thái mời của một friend trong context của lobby cụ thể
/// (theo `LobbyInviteFriendStatus` enum từ backend).
///
/// Dùng để render đúng UI:
/// - [Invitable]   → bật nút "Mời"
/// - [InvitePending] → hiển thị "Đã gửi" (có thể cancel)
/// - [InviteAccepted] → "Đã tham gia" (thành viên khác của lobby)
/// - [InviteNotPending] → invite cũ ở terminal state → cho phép Resend
/// - [AlreadyMember] → "Đã trong phòng"
/// - [BlockedByThem] / [BlockedByMe] → disable hoàn toàn
/// - [LobbyClosed] → lobby đã đóng, không mời được nữa
enum LobbyInviteFriendStatus {
  invitable,
  invitePending,
  inviteAccepted,
  inviteNotPending,
  alreadyMember,
  blockedByThem,
  blockedByMe,
  lobbyClosed,
  /// Unknown — backend trả giá trị không nằm trong enum đã biết.
  unknown;

  /// Parse từ string (PascalCase từ backend).
  static LobbyInviteFriendStatus fromString(String? value) {
    if (value == null) return LobbyInviteFriendStatus.unknown;
    switch (value.trim()) {
      case 'Invitable':
        return LobbyInviteFriendStatus.invitable;
      case 'InvitePending':
        return LobbyInviteFriendStatus.invitePending;
      case 'InviteAccepted':
        return LobbyInviteFriendStatus.inviteAccepted;
      case 'InviteNotPending':
        return LobbyInviteFriendStatus.inviteNotPending;
      case 'AlreadyMember':
        return LobbyInviteFriendStatus.alreadyMember;
      case 'BlockedByThem':
        return LobbyInviteFriendStatus.blockedByThem;
      case 'BlockedByMe':
        return LobbyInviteFriendStatus.blockedByMe;
      case 'LobbyClosed':
        return LobbyInviteFriendStatus.lobbyClosed;
      default:
        return LobbyInviteFriendStatus.unknown;
    }
  }
}

/// Bạn bè + trạng thái có thể mời vào lobby.
///
/// Trả về bởi `GET /api/v1/lobbies/{lobbyId}/invitable-friends` —
/// server đã tính sẵn trạng thái cho UI render.
class LobbyInvitableFriend extends Equatable {
  /// ID của user.
  final String userId;

  /// Username.
  final String username;

  /// Avatar URL.
  final String? avatarUrl;

  /// Karma points hiện tại của user.
  final int karmaPoints;

  /// Tier (Bronze/Silver/Gold/Platinum/Diamond) — optional.
  final String? gamerTier;

  /// "Online" / "RecentlyActive" / "Offline" — optional, free string từ backend.
  final String? activityStatus;

  /// Lần cuối user active (optional).
  final DateTime? lastActiveAt;

  /// Thời điểm trở thành bạn.
  final DateTime friendsSince;

  /// Trạng thái invite cho lobby hiện tại (đã được server tính).
  final LobbyInviteFriendStatus inviteStatus;

  /// ID của invite mới nhất (nếu có) — dùng cho Resend.
  final String? latestInviteId;

  /// Status của invite mới nhất (Pending/Declined/Expired/Cancelled).
  final LobbyInviteStatus? latestInviteStatus;

  /// Server-derived flag: friend đã là thành viên lobby chưa.
  final bool isInLobby;

  /// Server-derived flag: có pending invite đang chờ không.
  final bool hasPendingInvite;

  /// Server-derived flag: friend bị block bởi current user không.
  final bool isBlocked;

  const LobbyInvitableFriend({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.karmaPoints,
    this.gamerTier,
    this.activityStatus,
    this.lastActiveAt,
    required this.friendsSince,
    required this.inviteStatus,
    this.latestInviteId,
    this.latestInviteStatus,
    required this.isInLobby,
    required this.hasPendingInvite,
    required this.isBlocked,
  });

  /// User có đang online/recently active không (cho `onlineOnly` filter UI).
  bool get isOnline {
    final status = activityStatus?.toLowerCase().trim();
    return status == 'online' || status == 'recentlyactive';
  }

  /// Đã là thành viên lobby → ẩn nút invite, hiển thị badge.
  bool get canShowAsMember =>
      inviteStatus == LobbyInviteFriendStatus.alreadyMember ||
      inviteStatus == LobbyInviteFriendStatus.inviteAccepted ||
      isInLobby;

  /// Có thể bấm nút "Mời" (invite mới).
  bool get canInvite =>
      inviteStatus == LobbyInviteFriendStatus.invitable &&
      !isInLobby &&
      !isBlocked;

  /// Có pending invite → hiển thị "Đã gửi" + nút huỷ.
  bool get canCancel =>
      inviteStatus == LobbyInviteFriendStatus.invitePending ||
      hasPendingInvite;

  /// Có invite cũ ở terminal state → cho phép Resend.
  bool get canResend =>
      inviteStatus == LobbyInviteFriendStatus.inviteNotPending &&
      latestInviteId != null &&
      (latestInviteStatus == LobbyInviteStatus.declined ||
          latestInviteStatus == LobbyInviteStatus.expired ||
          latestInviteStatus == LobbyInviteStatus.cancelled);

  @override
  List<Object?> get props => [
    userId,
    username,
    avatarUrl,
    karmaPoints,
    gamerTier,
    activityStatus,
    lastActiveAt,
    friendsSince,
    inviteStatus,
    latestInviteId,
    latestInviteStatus,
    isInLobby,
    hasPendingInvite,
    isBlocked,
  ];
}
