import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Future<void> clearAll() async {
    await clearActiveLobbyId();
    await clearLobbyDetails();
  }
}
