import 'package:shared_preferences/shared_preferences.dart';

/// Cache local cho trạng thái "đã lưu" của board game.
///
/// Dùng [SharedPreferences] lưu danh sách gameTemplateId mà user đã save.
/// Mục đích: optimistic UI — hiển thị filled heart ngay khi mở card,
/// không cần chờ API response.
///
/// Cache là best-effort:
/// - Khi app khởi động, đọc từ SharedPreferences để render nhanh.
/// - Khi vào SavedGamesPage, gọi API refresh để đồng bộ.
/// - Sau khi toggle save, cập nhật local ngay (optimistic), rồi sync với API.
/// - Nếu API thất bại → revert local cache.
///
/// **Key:** `saved_game_ids` — danh sách UUID ngăn cách bằng `,`.
class SavedGamesCache {
  static const String _key = 'saved_game_ids';

  final SharedPreferences _prefs;

  SavedGamesCache(this._prefs);

  /// Đọc danh sách gameId đã lưu.
  Set<String> read() {
    final list = _prefs.getStringList(_key);
    if (list == null) return <String>{};
    return list.toSet();
  }

  /// Kiểm tra game đã được lưu chưa.
  bool isSaved(String gameId) => read().contains(gameId);

  /// Số lượng game đã lưu.
  int get count => read().length;

  /// Thêm game vào danh sách lưu.
  Future<void> add(String gameId) async {
    final s = read()..add(gameId);
    await _prefs.setStringList(_key, s.toList());
  }

  /// Xóa game khỏi danh sách lưu.
  Future<void> remove(String gameId) async {
    final s = read()..remove(gameId);
    await _prefs.setStringList(_key, s.toList());
  }

  /// Toggle save/unsave — trả về trạng thái mới (isSaved sau khi toggle).
  Future<bool> toggle(String gameId) async {
    final s = read();
    final isNowSaved = !s.contains(gameId);
    if (isNowSaved) {
      s.add(gameId);
    } else {
      s.remove(gameId);
    }
    await _prefs.setStringList(_key, s.toList());
    return isNowSaved;
  }

  /// Cập nhật toàn bộ danh sách (dùng khi API trả về list đầy đủ).
  Future<void> replaceAll(List<String> gameIds) async {
    await _prefs.setStringList(_key, gameIds.toList());
  }

  /// Xóa toàn bộ cache (ví dụ khi logout).
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
