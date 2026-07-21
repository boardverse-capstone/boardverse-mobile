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
/// Implementations:
/// - `MockLobbyRealtimeService` (giả lập bằng Timer, dùng dev/mock mode)
/// - `RealLobbyRealtimeService` (signalr_netcore, dùng khi backend sẵn sàng)
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
