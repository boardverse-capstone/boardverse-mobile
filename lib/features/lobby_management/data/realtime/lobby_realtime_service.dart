import 'dart:async';

/// Realtime events do backend SignalR Hub đẩy về.
///
/// Mapping theo spec `.agents/docs/apis_docs/lobby.md:255-260`:
/// - `MemberJoined`     → BR-07, BR-10
/// - `MemberLeft`       → —
/// - `LobbyFull`        → BR-07
/// - `LobbyCancelled`   → — (reason: HOST_CANCELLED / TABLE_CONFLICT / ...)
/// - `LobbyTimeout`     → BR-08
/// - `BookingConfirmed` → BR-05
sealed class LobbyRealtimeEvent {
  const LobbyRealtimeEvent();
}

class MemberJoinedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final LobbyMemberPayload member;
  final DateTime timestamp;

  const MemberJoinedEvent({
    required this.lobbyId,
    required this.member,
    required this.timestamp,
  });
}

class MemberLeftEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String memberId;
  final DateTime timestamp;

  const MemberLeftEvent({
    required this.lobbyId,
    required this.memberId,
    required this.timestamp,
  });
}

class LobbyFullEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String message;
  final DateTime timestamp;

  const LobbyFullEvent({
    required this.lobbyId,
    required this.message,
    required this.timestamp,
  });
}

class LobbyCancelledEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String reason;
  final DateTime timestamp;

  const LobbyCancelledEvent({
    required this.lobbyId,
    required this.reason,
    required this.timestamp,
  });
}

class LobbyTimeoutEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String message;
  final DateTime timestamp;

  const LobbyTimeoutEvent({
    required this.lobbyId,
    required this.message,
    required this.timestamp,
  });
}

class BookingConfirmedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String bookingId;
  final String message;
  final DateTime timestamp;

  const BookingConfirmedEvent({
    required this.lobbyId,
    required this.bookingId,
    required this.message,
    required this.timestamp,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// Invite Events - cho Lobby Invite System
// ════════════════════════════════════════════════════════════════════════════

/// Server thông báo có lời mời lobby mới.
class LobbyInviteReceivedEvent extends LobbyRealtimeEvent {
  final String inviteId;
  final String lobbyId;
  final String inviterName;
  final String inviterAvatar;
  final String gameName;
  final String cafeName;
  final DateTime timestamp;

  const LobbyInviteReceivedEvent({
    required this.inviteId,
    required this.lobbyId,
    required this.inviterName,
    required this.inviterAvatar,
    required this.gameName,
    required this.cafeName,
    required this.timestamp,
  });
}

/// Server thông báo invite đã được accept bởi invitee.
class InviteAcceptedEvent extends LobbyRealtimeEvent {
  final String inviteId;
  final String lobbyId;
  final String inviteeName;
  final DateTime timestamp;

  const InviteAcceptedEvent({
    required this.inviteId,
    required this.lobbyId,
    required this.inviteeName,
    required this.timestamp,
  });
}

/// Server thông báo invite đã được decline.
class InviteDeclinedEvent extends LobbyRealtimeEvent {
  final String inviteId;
  final String lobbyId;
  final String inviteeName;
  final DateTime timestamp;

  const InviteDeclinedEvent({
    required this.inviteId,
    required this.lobbyId,
    required this.inviteeName,
    required this.timestamp,
  });
}

/// Server thông báo invite đã được cancel bởi inviter.
class InviteCancelledEvent extends LobbyRealtimeEvent {
  final String inviteId;
  final String lobbyId;
  final DateTime timestamp;

  const InviteCancelledEvent({
    required this.inviteId,
    required this.lobbyId,
    required this.timestamp,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// Match Result Events - cho Match Result System
// ════════════════════════════════════════════════════════════════════════════

/// Server thông báo có member submit kết quả trận đấu.
class MatchResultSubmittedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String odId;
  final String username;
  final String outcome;
  final int submittedCount;
  final int requiredCount;
  final DateTime timestamp;

  const MatchResultSubmittedEvent({
    required this.lobbyId,
    required this.odId,
    required this.username,
    required this.outcome,
    required this.submittedCount,
    required this.requiredCount,
    required this.timestamp,
  });
}

/// Server thông báo Elo đã được update sau khi match finalized.
class EloUpdatedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String odId;
  final String username;
  final int eloBefore;
  final int eloAfter;
  final int eloDelta;
  final DateTime timestamp;

  const EloUpdatedEvent({
    required this.lobbyId,
    required this.odId,
    required this.username,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
    required this.timestamp,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// Browse Realtime Events - cho NearbyLobbiesPage realtime refresh
// ════════════════════════════════════════════════════════════════════════════

/// Server broadcast khi có lobby mới được tạo trong vùng user đang subscribe
/// (gọi qua `subscribeNearbyLobbies`). Client nên refetch
/// `/api/v1/lobbies/discoverable` để hiển thị lobby mới.
///
/// Backend spec `lobby.md:249` — server publish event này cho group
/// location-based khi lobby có `visibility = public` và status = open.
class NearbyLobbyCreatedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String gameTemplateId;
  final String cafeId;
  final DateTime scheduledStartTime;
  final DateTime timestamp;

  const NearbyLobbyCreatedEvent({
    required this.lobbyId,
    required this.gameTemplateId,
    required this.cafeId,
    required this.scheduledStartTime,
    required this.timestamp,
  });
}

/// Server broadcast khi 1 lobby trong vùng bị cancel / timeout / full-lock
/// → không còn hiển thị trong `/discoverable`. Client nên refetch hoặc
/// remove item khỏi list cached.
class NearbyLobbyRemovedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final String reason;
  final DateTime timestamp;

  const NearbyLobbyRemovedEvent({
    required this.lobbyId,
    required this.reason,
    required this.timestamp,
  });
}

/// Server broadcast khi 1 lobby trong vùng vừa đổi sang `full` — client
/// nên refetch để cập nhật slot count + status badge trên card.
class NearbyLobbyUpdatedEvent extends LobbyRealtimeEvent {
  final String lobbyId;
  final int currentMembers;
  final int maxMembers;
  final DateTime timestamp;

  const NearbyLobbyUpdatedEvent({
    required this.lobbyId,
    required this.currentMembers,
    required this.maxMembers,
    required this.timestamp,
  });
}

/// Payload của server event `MemberJoined` — chỉ chứa field hiển thị trên UI.
/// Chi tiết thành viên đầy đủ nếu cần sẽ fetch qua
/// `GET /api/v1/lobbies/{id}`.
class LobbyMemberPayload {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final double karma;
  final DateTime joinedAt;

  const LobbyMemberPayload({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.karma,
    required this.joinedAt,
  });

  factory LobbyMemberPayload.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) =>
        v == null ? DateTime.now() : DateTime.parse(v.toString());
    return LobbyMemberPayload(
      id: (json['id'] ?? json['memberId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      isHost: json['isHost'] as bool? ?? false,
      karma: (json['karma'] as num?)?.toDouble() ?? 0,
      joinedAt: parseDate(json['joinedAt']),
    );
  }
}

/// Abstraction cho SignalR / mock realtime client.
///
/// Implementations (hiện tại):
/// - `MockLobbyRealtimeService` (no-op — dùng cho dev khi backend chưa
///   expose endpoint SignalR `/hubs/lobby/negotiate`)
/// - `RealLobbyRealtimeService` (signalr_netcore) — file đã bị xóa vì
///   backend dev chưa expose hub. Khi backend sẵn sàng, restore file và
///   đổi DI trong `injection.dart` từ `MockLobbyRealtimeService` sang
///   `RealLobbyRealtimeService`.
abstract class LobbyRealtimeService {
  /// Phát mọi event nhận được từ server (đã lọc theo group nếu có).
  /// Repository sẽ subscribe stream này và dispatch tới Cubit.
  Stream<LobbyRealtimeEvent> get events;

  /// Khởi động kết nối tới hub. Idempotent — gọi nhiều lần an toàn.
  Future<void> connect();

  /// Ngắt kết nối + cleanup timers.
  Future<void> disconnect();

  /// Subscribe vào group của 1 lobby (theo `lobbyId`).
  /// Backend spec `lobby.md:247-249`.
  Future<void> joinLobby(String lobbyId);

  /// Unsubscribe khỏi group của lobby (gọi khi navigate away).
  Future<void> leaveLobby(String lobbyId);

  /// Subscribe vào group location-based để nhận broadcast từ server khi
  /// có lobby mới mở quanh vị trí hiện tại.
  /// Backend spec `lobby.md:249`.
  Future<void> subscribeNearbyLobbies({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}
