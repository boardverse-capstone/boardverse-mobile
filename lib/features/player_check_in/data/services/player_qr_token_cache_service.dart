import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistent cache cho QR check-in token gần nhất của player.
///
/// Lưu ý:
/// - Token có TTL ngắn (~30 phút theo BR §21A.7) và chỉ dùng được 1 lần.
///   Vì vậy việc cache chỉ phục vụ UX (pre-fill input field khi retry,
///   tránh user phải gõ/paste lại) chứ không lưu giữ token hợp lệ để tái sử dụng.
/// - Dùng [FlutterSecureStorage] thay vì `SharedPreferences` vì:
///   1. Tính nhất quán với `ThemePreferencesService` (cùng pattern).
///   2. Mặc dù token không phải thông tin nhạy cảm, secure storage tránh
///      lộ rộng rãi qua root shell / debug dump.
/// - Mọi lỗi I/O đều trả về `null` thay vì throw — UI sẽ fallback về
///   input rỗng, không crash app.
///
/// API:
/// - [loadLastToken] — đọc token đã cache (hoặc `null`).
/// - [saveLastToken] — ghi token mới (chỉ ghi khi token hợp lệ format).
/// - [clear] — xoá token đã cache.
class PlayerQrTokenCacheService {
  PlayerQrTokenCacheService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'player_qr_last_token';

  final FlutterSecureStorage _storage;

  /// Đọc token đã cache. Trả về `null` nếu:
  /// - Chưa từng có token nào được cache.
  /// - Storage exception (corrupt, permission, ...).
  Future<String?> loadLastToken() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      // Chỉ trả về nếu token vẫn match format 16-char alphanumeric.
      // Nếu format sai (vd: dữ liệu cũ từ schema trước) → bỏ qua.
      if (!_isValidFormat(raw)) return null;
      return raw.toUpperCase();
    } catch (_) {
      return null;
    }
  }

  /// Ghi token vào cache. Bỏ qua nếu token không hợp lệ format
  /// (tránh ghi rác).
  Future<void> saveLastToken(String token) async {
    if (!_isValidFormat(token)) return;
    try {
      await _storage.write(key: _key, value: token.toUpperCase());
    } catch (_) {
      // Ignore — cache là best-effort.
    }
  }

  /// Xoá token đã cache. Dùng khi user logout hoặc muốn reset.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Ignore.
    }
  }

  bool _isValidFormat(String token) {
    return RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{16}$').hasMatch(
      token.toUpperCase(),
    );
  }
}
