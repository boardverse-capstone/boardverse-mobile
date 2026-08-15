import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent storage cho theme preference sử dụng `FlutterSecureStorage`.
///
/// Key: `theme_mode` — lưu một trong các giá trị: `light`, `dark`, `system`.
class ThemePreferencesService {
  ThemePreferencesService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'theme_mode';

  final FlutterSecureStorage _storage;

  /// Async: đọc [ThemeMode] đã lưu. Trả về [ThemeMode.light] nếu chưa có
  /// hoặc giá trị lưu không hợp lệ.
  Future<ThemeMode> loadMode() async {
    try {
      final raw = await _storage.read(key: _key);
      return _parseMode(raw);
    } catch (_) {
      return ThemeMode.light;
    }
  }

  /// Default mode dùng cho lúc app khởi động khi chưa đợi được async load —
  /// UI sẽ tự cập nhật sau khi [loadMode] hoàn thành.
  ThemeMode get defaultMode => ThemeMode.light;

  Future<void> saveMode(ThemeMode mode) async {
    await _storage.write(key: _key, value: _serializeMode(mode));
  }

  ThemeMode _parseMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String _serializeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}