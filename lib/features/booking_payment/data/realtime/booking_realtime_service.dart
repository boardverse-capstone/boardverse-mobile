import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/realtime/booking_realtime_events.dart';

/// SignalR service subscribe 3 nhóm: `booking-{id}`, `cafe-{id}`, lobby
/// group cho auto-cancel (gap #7 + gap #13).
///
/// Tái sử dụng hub `/hubs/lobby` (spec `lobby-hub.md` §4) — JWT auth flow
/// giống `RealLobbyRealtimeService` (đọc token từ secure storage).
///
/// Events (spec `lobby-hub.md` §37-60 + booking.md §84-120):
/// - `BookingCheckedIn`, `BookingCheckedOut`, `BookingCancelled`,
///   `BookingNoShowMarked` → emit `BookingRealtimeEvent` cho cubit.
/// - `CafePricingChanged` → emit `CafePricingChangedRealtimeEvent`.
/// - `LobbyAutoCancelled` → emit `LobbyAutoCancelledRealtimeEvent`.
class BookingRealtimeService {
  String _accessToken;
  HubConnection? _connection;
  bool _isConnected = false;

  final StreamController<BookingRealtimeEvent> _events =
      StreamController<BookingRealtimeEvent>.broadcast();

  Stream<BookingRealtimeEvent> get events => _events.stream;
  bool get isConnected => _isConnected;

  BookingRealtimeService(this._accessToken);

  Future<void> connect() async {
    if (_isConnected) return;
    if (_accessToken.isEmpty) {
      throw StateError('BookingRealtimeService: access token trống.');
    }
    final connection = HubConnectionBuilder()
        .withUrl(
          ApiEndpoints.lobbyHubBasePath,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => _accessToken,
          ),
        )
        .withAutomaticReconnect()
        .build();
    _registerHandlers(connection);
    await connection.start();
    _connection = connection;
    _isConnected = true;
  }

  void updateAccessToken(String token) {
    _accessToken = token;
    // Reconnect required — SignalR accessTokenFactory là closure, không
    // mutate được sau khi build. Caller phải disconnect+connect.
  }

  Future<void> disconnect() async {
    final conn = _connection;
    if (conn == null) return;
    try {
      await conn.stop();
    } finally {
      _connection = null;
      _isConnected = false;
    }
  }

  // ─── Group subscription ───────────────────────────────────────────

  Future<void> joinBookingGroup(String bookingId) async {
    final conn = _connection;
    if (conn == null || !_isConnected) {
      throw StateError('Hub chưa connect.');
    }
    await conn.invoke('JoinBookingGroup', args: [bookingId]);
  }

  Future<void> leaveBookingGroup(String bookingId) async {
    final conn = _connection;
    if (conn == null) return;
    try {
      await conn.invoke('LeaveBookingGroup', args: [bookingId]);
    } on Exception {/* ignore */}
  }

  Future<void> joinCafeGroup(String cafeId) async {
    final conn = _connection;
    if (conn == null || !_isConnected) {
      throw StateError('Hub chưa connect.');
    }
    await conn.invoke('JoinCafeGroup', args: [cafeId]);
  }

  Future<void> leaveCafeGroup(String cafeId) async {
    final conn = _connection;
    if (conn == null) return;
    try {
      await conn.invoke('LeaveCafeGroup', args: [cafeId]);
    } on Exception {/* ignore */}
  }

  Future<void> joinLobby(String lobbyId) async {
    final conn = _connection;
    if (conn == null || !_isConnected) return;
    try {
      await conn.invoke('JoinLobby', args: [lobbyId]);
    } on Exception {/* ignore */}
  }

  Future<void> leaveLobby(String lobbyId) async {
    final conn = _connection;
    if (conn == null) return;
    try {
      await conn.invoke('LeaveLobby', args: [lobbyId]);
    } on Exception {/* ignore */}
  }

  // ─── Event handlers ───────────────────────────────────────────────

  void _registerHandlers(HubConnection conn) {
    conn.on('BookingCheckedIn', _onBookingCheckedIn);
    conn.on('BookingCheckedOut', _onBookingCheckedOut);
    conn.on('BookingCancelled', _onBookingCancelled);
    conn.on('BookingNoShowMarked', _onBookingNoShowMarked);

    conn.on('CafePricingChanged', _onCafePricingChanged);
    conn.on('LobbyAutoCancelled', _onLobbyAutoCancelled);
  }

  void _onBookingCheckedIn(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(BookingCheckedInRealtimeEvent(
        bookingId:
            (raw['BookingId'] ?? raw['bookingId'] ?? '').toString(),
        checkedInAt: _parseDate(raw['CheckedInAt'] ?? raw['checkedInAt']),
        checkedInByUserId:
            (raw['CheckedInByUserId'] ?? raw['checkedInByUserId'] ?? '')
                .toString(),
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed payload */}
  }

  void _onBookingCheckedOut(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(BookingCheckedOutRealtimeEvent(
        bookingId:
            (raw['BookingId'] ?? raw['bookingId'] ?? '').toString(),
        activeSessionId:
            (raw['ActiveSessionId'] ?? raw['activeSessionId'] ?? '')
                .toString(),
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed */}
  }

  void _onBookingCancelled(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(BookingCancelledRealtimeEvent(
        bookingId:
            (raw['BookingId'] ?? raw['bookingId'] ?? '').toString(),
        reason: (raw['Reason'] ?? raw['reason'] ?? '').toString(),
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed */}
  }

  void _onBookingNoShowMarked(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      final membersRaw = raw['NoShowMemberIds'] ?? raw['noShowMemberIds'];
      final members = membersRaw is List
          ? membersRaw.map((e) => e.toString()).toList()
          : <String>[];
      _events.add(BookingNoShowMarkedRealtimeEvent(
        bookingId:
            (raw['BookingId'] ?? raw['bookingId'] ?? '').toString(),
        noShowMemberIds: members,
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed */}
  }

  void _onCafePricingChanged(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(CafePricingChangedRealtimeEvent(
        cafeId: (raw['CafeId'] ?? raw['cafeId'] ?? '').toString(),
        pricing: Map<String, dynamic>.from(
          (raw['Pricing'] ?? raw['pricing'] ?? const {}) as Map,
        ),
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed */}
  }

  void _onLobbyAutoCancelled(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    try {
      final raw = args.first as Map<String, dynamic>;
      _events.add(LobbyAutoCancelledRealtimeEvent(
        lobbyId: (raw['LobbyId'] ?? raw['lobbyId'] ?? '').toString(),
        reason: (raw['Reason'] ?? raw['reason'] ?? '').toString(),
        timestamp: _parseDate(raw['Timestamp'] ?? raw['timestamp']),
      ));
    } on Exception {/* malformed */}
  }

  DateTime _parseDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}