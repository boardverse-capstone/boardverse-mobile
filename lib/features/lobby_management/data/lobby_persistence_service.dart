import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/lobby_entity.dart';
import 'models/lobby_model.dart';

/// Service for persisting lobby state locally.
///
/// This allows:
/// - Saving the active lobby ID when user creates a lobby
/// - Restoring the lobby when the app restarts or user returns
/// - Checking if user has an active lobby
class LobbyPersistenceService {
  static const _activeLobbyKey = 'active_lobby_id';
  static const _lobbyDetailsKey = 'lobby_details';

  final FlutterSecureStorage _storage;

  LobbyPersistenceService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Save the active lobby ID
  Future<void> saveActiveLobbyId(String lobbyId) async {
    await _storage.write(key: _activeLobbyKey, value: lobbyId);
  }

  /// Get the active lobby ID (if any)
  Future<String?> getActiveLobbyId() async {
    return await _storage.read(key: _activeLobbyKey);
  }

  /// Clear the active lobby ID
  Future<void> clearActiveLobbyId() async {
    await _storage.delete(key: _activeLobbyKey);
  }

  /// Save full lobby details for offline access
  Future<void> saveLobbyDetails(Map<String, dynamic> lobbyDetails) async {
    await _storage.write(
      key: _lobbyDetailsKey,
      value: jsonEncode(lobbyDetails),
    );
  }

  /// Get saved lobby details
  Future<Map<String, dynamic>?> getLobbyDetails() async {
    final details = await _storage.read(key: _lobbyDetailsKey);
    if (details == null) return null;
    return jsonDecode(details) as Map<String, dynamic>;
  }

  /// Clear lobby details
  Future<void> clearLobbyDetails() async {
    await _storage.delete(key: _lobbyDetailsKey);
  }

  /// Check if user has an active lobby
  Future<bool> hasActiveLobby() async {
    final lobbyId = await getActiveLobbyId();
    if (lobbyId == null) return false;

    // Also check if lobby details exist
    final details = await getLobbyDetails();
    if (details == null) return false;

    // Check if lobby is not expired
    final expiresAt = DateTime.tryParse(details['expiresAt'] ?? '');
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(expiresAt);
  }

  /// Clear all lobby persistence data
  /// Build một [LobbyEntity] tối thiểu từ cached details (dùng làm fallback
  /// khi response backend thiếu field như `hostName`, `cafeName`,
  /// `inviteCode` — schema mới `/lobbies/{id}` chỉ trả id chứ không trả
  /// tên hiển thị).
  ///
  /// Trả null nếu không có cached details.
  LobbyEntity? getCachedLobbyEntity() {
    final details = _cachedDetails;
    if (details == null) return null;
    return _buildEntityFromCache(details);
  }

  /// Load cached details vào memory. Idempotent — gọi nhiều lần không sao.
  Future<void> loadCachedDetails() async {
    final raw = await _storage.read(key: _lobbyDetailsKey);
    if (raw == null) {
      _cachedDetails = null;
      return;
    }
    try {
      _cachedDetails = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      _cachedDetails = null;
    }
  }

  LobbyEntity? _buildEntityFromCache(Map<String, dynamic> details) {
    final id = details['id'] as String?;
    if (id == null) return null;

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    // Parse status — fallback 'open' nếu cache cũ không có field.
    final statusRaw = (details['status'] as String?)?.toLowerCase() ?? 'open';
    final status = LobbyStatus.values.firstWhere(
      (s) => s.name == statusRaw,
      orElse: () => LobbyStatus.open,
    );

    final timeoutAt = parseDate(details['expiresAt'] ?? details['timeoutAt']);

    return LobbyEntity(
      id: id,
      gameId: (details['gameId'] as String?) ?? '',
      gameName: (details['gameName'] as String?) ?? '',
      cafeId: (details['cafeId'] as String?) ?? '',
      cafeName: (details['cafeName'] as String?) ?? '',
      hostId: (details['hostId'] as String?) ?? '',
      hostName: (details['hostName'] as String?) ?? '',
      scheduledTime: parseDate(details['scheduledTime']),
      currentPlayers: (details['currentPlayers'] as int?) ?? 0,
      maxPlayers: (details['maxPlayers'] as int?) ?? 2,
      minPlayers: (details['minPlayers'] as int?) ?? 2,
      isPublic: LobbyModel.parseVisibility(
        isPublic: details['isPublic'],
        isPrivate: details['isPrivate'],
        visibility: details['visibility'],
      ),
      inviteCode: details['inviteCode'] as String?,
      status: status,
      players: const [],
      createdAt: parseDate(details['createdAt']),
      timeoutAt: timeoutAt,
      playStartedAt: details['playStartedAt'] != null
          ? DateTime.tryParse(details['playStartedAt'].toString())
          : null,
    );
  }

  Future<void> clearAll() async {
    _cachedDetails = null;
    await clearActiveLobbyId();
    await clearLobbyDetails();
  }

  Map<String, dynamic>? _cachedDetails;
}
