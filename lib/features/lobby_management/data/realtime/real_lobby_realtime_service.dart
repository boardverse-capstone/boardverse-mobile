import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/constants/api_endpoints.dart';
import 'lobby_realtime_service.dart';

/// Real SignalR client kết nối tới hub `/hubs/lobby` của backend.
///
/// Connection flow (theo spec `lobby.md:238-242`):
/// 1. POST `'/hubs/lobby/negotiate?access_token=<jwt>'` (lib tự làm).
/// 2. Upgrade lên WebSocket (lib tự).
/// 3. Server-side `[Authorize]` yêu cầu JWT — truyền qua
///    `accessTokenFactory` đọc từ `FlutterSecureStorage`.
///
/// Events server→client được map như sau:
/// - `MemberJoined`     → MemberJoinedEvent(payload)
/// - `MemberLeft`       → MemberLeftEvent(memberId)
/// - `LobbyFull`        → LobbyFullEvent
/// - `LobbyCancelled`   → LobbyCancelledEvent(reason)
/// - `LobbyTimeout`     → LobbyTimeoutEvent
/// - `BookingConfirmed` → BookingConfirmedEvent(bookingId)
///
/// Event payload là JSON object từ C# — đọc qua
/// `LobbyMemberPayload.fromJson` / dynamic Map access.
class RealLobbyRealtimeService implements LobbyRealtimeService {
  RealLobbyRealtimeService({required FlutterSecureStorage storage})
      : _storage = storage;

  final FlutterSecureStorage _storage;
  final _events = StreamController<LobbyRealtimeEvent>.broadcast();

  HubConnection? _connection;
  bool _isConnected = false;

  @override
  Stream<LobbyRealtimeEvent> get events => _events.stream;

  // ════════════════════════════════════════════════════════════════════
  // Connection lifecycle
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      throw StateError(
        'Cannot connect to lobby hub: access_token not found in secure storage. '
        'User phải đăng nhập trước khi mở lobby.',
      );
    }

    _connection = HubConnectionBuilder()
        .withUrl(
          ApiEndpoints.lobbyHubBasePath,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _registerHandlers(_connection!);
    await _connection!.start();
    _isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    if (_connection == null) return;
    await _connection!.stop();
    _connection = null;
    _isConnected = false;
  }

  // ════════════════════════════════════════════════════════════════════
  // Group subscription
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<void> joinLobby(String lobbyId) async {
    final conn = _connection;
    if (conn == null || !_isConnected) {
      throw StateError('Hub chưa connect. Gọi connect() trước joinLobby().');
    }
    await conn.invoke('JoinLobby', args: [lobbyId]);
  }

  @override
  Future<void> leaveLobby(String lobbyId) async {
    final conn = _connection;
    if (conn == null || !_isConnected) return;
    try {
      await conn.invoke('LeaveLobby', args: [lobbyId]);
    } on Exception {
      // Hub có thể đã đóng — bỏ qua.
    }
  }

  @override
  Future<void> subscribeNearbyLobbies({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final conn = _connection;
    if (conn == null || !_isConnected) {
      throw StateError('Hub chưa connect.');
    }
    await conn.invoke(
      'SubscribeNearbyLobbies',
      args: [latitude, longitude, radiusKm],
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Event handlers — spec `lobby.md:255-260`
  // ════════════════════════════════════════════════════════════════════

  void _registerHandlers(HubConnection conn) {
    conn.on('MemberJoined', _onMemberJoined);
    conn.on('MemberLeft', _onMemberLeft);
    conn.on('LobbyFull', _onLobbyFull);
    conn.on('LobbyCancelled', _onLobbyCancelled);
    conn.on('LobbyTimeout', _onLobbyTimeout);
    conn.on('BookingConfirmed', _onBookingConfirmed);
  }

  void _onMemberJoined(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(MemberJoinedEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        member: LobbyMemberPayload.fromJson(Map<String, dynamic>.from(
          (raw['Member'] ?? raw['member'] ?? const {}) as Map,
        )),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // Bỏ qua payload lỗi để stream không chết.
    }
  }

  void _onMemberLeft(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(MemberLeftEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        memberId: (raw['MemberId'] ?? raw['memberId'] ?? '').toString(),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // ignore malformed payload
    }
  }

  void _onLobbyFull(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(LobbyFullEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        message: (raw['Message'] ?? raw['message'] ?? '').toString(),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // ignore malformed payload
    }
  }

  void _onLobbyCancelled(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(LobbyCancelledEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        reason: (raw['Reason'] ?? raw['reason'] ?? '').toString(),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // ignore malformed payload
    }
  }

  void _onLobbyTimeout(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(LobbyTimeoutEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        message: (raw['Message'] ?? raw['message'] ?? '').toString(),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // ignore malformed payload
    }
  }

  void _onBookingConfirmed(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(BookingConfirmedEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        bookingId: (raw['BookingId'] ?? raw['bookingId'] ?? '').toString(),
        message: (raw['Message'] ?? raw['message'] ?? '').toString(),
        timestamp: _parseTimestamp(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {
      // ignore malformed payload
    }
  }

  DateTime _parseTimestamp(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
