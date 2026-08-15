import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_model.dart';

/// Service to cache profile data locally so the UI can render even when
/// the network call fails or is unavailable.
///
/// Triggers: cold start, offline, API errors, /api/Userprofile returning
/// 401 (token rotated) right after login.
class ProfileCacheService {
  static const _cacheKey = 'profile.cache.v1';

  /// Save the profile JSON to local storage.
  Future<void> save(ProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'data': profile.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_cacheKey, json);
    } catch (_) {
      // Cache write failures are non-fatal — fall back to in-memory only.
    }
  }

  /// Load the cached profile, or null if not available / parse failed.
  Future<ProfileModel?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      return ProfileModel.fromJson(data);
    } catch (_) {
      // Stale or corrupt cache — drop it, treat as cache miss.
      await _clearSilently();
      return null;
    }
  }

  /// Clear the cached profile (e.g. on logout).
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {
      // Non-fatal.
    }
  }

  Future<void> _clearSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {
      // ignore
    }
  }
}
