import 'dart:async';
import 'dart:math';

import '../models/lobby_model.dart';
import 'lobby_realtime_service.dart';
import '../datasources/mock/mock_lobby_remote_datasource.dart';

/// Mock implementation của [LobbyRealtimeService].
///
/// Cách hoạt động:
/// - Khi user gọi [joinLobby] (thường là sau khi tạo/load lobby), khởi động
///   1 timer `5s` mô phỏng `MemberJoined` event + cập nhật số người chơi.
/// - Khi user gọi [leaveLobby], hủy timer tương ứng.
/// - Khi lobby "đầy" (currentPlayers == maxPlayers), phát `LobbyFullEvent`
///   rồi dừng timer.
///
/// Mục đích: giữ UI test được khi `AppConfig.useMockLobbyData = true`
/// và backend SignalR chưa sẵn sàng.
class MockLobbyRealtimeService implements LobbyRealtimeService {
  MockLobbyRealtimeService();

  final _events = StreamController<LobbyRealtimeEvent>.broadcast();
  final Map<String, Timer> _timers = {};
  final _rng = Random();

  @override
  Stream<LobbyRealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    // No-op cho mock.
  }

  @override
  Future<void> disconnect() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  Future<void> joinLobby(String lobbyId) async {
    MockLobbyRemoteDatasource.ensureSeeded();
    // Phát ngay 1 snapshot "host đã sẵn sàng" để client có state khởi đầu
    // (giả lập phía server lúc user subscribe group).
    final initialLobby = MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId);
    if (initialLobby != null && initialLobby.players.isNotEmpty) {
      final host = initialLobby.players.firstWhere(
        (p) => p.isHost,
        orElse: () => initialLobby.players.first,
      );
      _events.add(MemberJoinedEvent(
        lobbyId: lobbyId,
        member: LobbyMemberPayload(
          id: host.id,
          name: host.name,
          avatarUrl: host.avatarUrl,
          isHost: host.isHost,
          karma: host.karma,
          joinedAt: DateTime.tryParse(host.joinedAt) ?? DateTime.now(),
        ),
        timestamp: DateTime.now(),
      ));
    }
    // Không double-start timer.
    if (_timers.containsKey(lobbyId)) return;

    final timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final lobby = MockLobbyRemoteDatasource.getLobbyByIdStatic(lobbyId);
      if (lobby == null) {
        _timers[lobbyId]?.cancel();
        _timers.remove(lobbyId);
        return;
      }
      if (lobby.status != LobbyStatusModel.open || lobby.isFull) {
        // Đầy phòng → phát LobbyFull 1 lần rồi dừng.
        if (lobby.isFull) {
          _events.add(LobbyFullEvent(
            lobbyId: lobbyId,
            message: 'Phòng đã đủ người',
            timestamp: DateTime.now(),
          ));
          _timers[lobbyId]?.cancel();
          _timers.remove(lobbyId);
        }
        return;
      }

      // Xác suất mỗi tick 55% có người join (giống MockLobbyDatasource cũ).
      if (_rng.nextDouble() >= 0.55) return;

      // Tăng currentPlayers; thêm LobbyPlayerModel giả.
      final newPlayer = LobbyPlayerModel(
        id: 'user_auto_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Người chơi mới',
        avatarUrl: 'https://picsum.photos/seed/auto${_rng.nextInt(999)}/150',
        isHost: false,
        isReady: false,
        joinedAt: DateTime.now().toIso8601String(),
        karma: (45 + _rng.nextInt(50)).toDouble(),
      );

      final isNowFull = lobby.currentPlayers + 1 >= lobby.maxPlayers;
      final updated = lobby.copyWith(
        currentPlayers: lobby.currentPlayers + 1,
        players: [...lobby.players, newPlayer],
        status: isNowFull ? LobbyStatusModel.full : lobby.status,
      );
      MockLobbyRemoteDatasource.setLobby(lobbyId, updated);

      _events.add(MemberJoinedEvent(
        lobbyId: lobbyId,
        member: LobbyMemberPayload(
          id: newPlayer.id,
          name: newPlayer.name,
          avatarUrl: newPlayer.avatarUrl,
          isHost: newPlayer.isHost,
          karma: newPlayer.karma,
          joinedAt: DateTime.tryParse(newPlayer.joinedAt) ?? DateTime.now(),
        ),
        timestamp: DateTime.now(),
      ));

      if (isNowFull) {
        _events.add(LobbyFullEvent(
          lobbyId: lobbyId,
          message: 'Phòng đã đủ người',
          timestamp: DateTime.now(),
        ));
        _timers[lobbyId]?.cancel();
        _timers.remove(lobbyId);
      }
    });

    _timers[lobbyId] = timer;
  }

  @override
  Future<void> leaveLobby(String lobbyId) async {
    _timers[lobbyId]?.cancel();
    _timers.remove(lobbyId);
    _events.add(MemberLeftEvent(
      lobbyId: lobbyId,
      memberId: 'mock-self',
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> subscribeNearbyLobbies({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    // No-op cho mock.
  }
}
