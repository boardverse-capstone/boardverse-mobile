/// Helper parse enum từ JSON response của backend .NET (trả PascalCase).
///
/// Backend .NET (theo `.agents/docs/lobby_docs/friend.md`) trả:
/// - `Pending` / `Accepted` / `Declined` / `Removed` / `Expired` cho request
/// - `RecentlyActive` / `Away` / `Offline` cho activity
/// - `Pending` / `Accepted` / `Blocked` cho friendship
///
/// Frontend dùng enum name ở dạng `camelCase` (`pendingSent`,
/// `recentlyActive`, ...). Helper này normalize input (bỏ `_` `-` ` `)
/// rồi match theo 3 bước:
///
/// 1. Custom alias do caller cung cấp (ưu tiên) — dùng cho fallback semantic
///    như `rejected` → `declined`.
/// 2. Exact match enum name.
/// 3. Substring match — phòng trường hợp backend trả `pending_sent`.
T parseEnum<T extends Enum>(
  List<T> values,
  dynamic raw, {
  required T fallback,
  Map<String, T>? aliases,
}) {
  if (raw == null) return fallback;
  final str = raw.toString();
  if (str.isEmpty) return fallback;

  final normalized = str
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll('-', '')
      .replaceAll(' ', '');

  if (aliases != null) {
    final aliasMatch = aliases[normalized];
    if (aliasMatch != null) return aliasMatch;
  }

  for (final v in values) {
    final enumName = v.name.toLowerCase();
    if (enumName == normalized) return v;
  }

  for (final v in values) {
    final enumName = v.name.toLowerCase();
    if (normalized.contains(enumName) || enumName.contains(normalized)) {
      return v;
    }
  }

  return fallback;
}

/// Helper parse DateTime từ JSON. Trả null nếu null/invalid — caller tự quyết
/// định fallback (ví dụ `DateTime.now()`).
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Helper parse `List<String>` từ JSON. Backend có thể trả list trực
/// tiếp hoặc CSV string `"A,B,C"`.
List<String>? parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) return value.split(',').map((e) => e.trim()).toList();
  return null;
}
