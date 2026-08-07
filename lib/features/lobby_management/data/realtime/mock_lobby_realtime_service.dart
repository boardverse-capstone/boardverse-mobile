import 'dart:async';

import 'lobby_realtime_service.dart';

/// No-op realtime service — không kết nối tới SignalR hub.
///
/// **Lý do dùng:** Backend hiện chưa expose endpoint SignalR
/// `POST /hubs/lobby/negotiate` (trả 404 trên dev). Realtime lobby update
/// giờ chỉ dựa vào REST polling qua `LobbyRepository.watchLobbyRealtime`
/// (đã có sẵn trong `lobby_remote_datasource.dart`).
///
/// Khi backend publish hub endpoint, đổi DI trong `injection.dart` từ
/// `MockLobbyRealtimeService` sang `RealLobbyRealtimeService`.
class MockLobbyRealtimeService implements LobbyRealtimeService {
  final _events = StreamController<LobbyRealtimeEvent>.broadcast();

  @override
  Stream<LobbyRealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    // No-op: REST polling đã đảm bảo realtime từ server.
  }

  @override
  Future<void> disconnect() async {
    // No-op.
  }

  @override
  Future<void> joinLobby(String lobbyId) async {
    // No-op: REST polling đã subscribe lobbyId.
  }

  @override
  Future<void> leaveLobby(String lobbyId) async {
    // No-op.
  }

  @override
  Future<void> subscribeNearbyLobbies({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    // No-op: NearbyLobbiesPage dùng REST list + auto-refresh.
  }

  Future<void> dispose() async {
    await _events.close();
  }
}
