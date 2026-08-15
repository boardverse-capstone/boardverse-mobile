/// GamerTier — Tier phân loại player theo Karma Points (BR §K-06).
///
/// Backend trả sẵn `gamerTier` trong response, client không cần tự tính.
/// Enum này dùng cho UI render (màu badge, label tiếng Việt).
enum GamerTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
  unknown;

  /// Tên tiếng Việt hiển thị cho UI.
  String get label {
    switch (this) {
      case GamerTier.bronze:
        return 'Đồng';
      case GamerTier.silver:
        return 'Bạc';
      case GamerTier.gold:
        return 'Vàng';
      case GamerTier.platinum:
        return 'Bạch kim';
      case GamerTier.diamond:
        return 'Kim cương';
      case GamerTier.master:
        return 'Cao thủ';
      case GamerTier.grandmaster:
        return 'Đại cao thủ';
      case GamerTier.unknown:
        return '—';
    }
  }

  /// Parse từ string backend (case-insensitive). Trả `unknown` cho
  /// giá trị không khớp (kể cả null/rỗng) — client vẫn render được entry.
  static GamerTier parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return GamerTier.unknown;
    final normalized = raw.trim().toLowerCase();
    for (final tier in GamerTier.values) {
      if (tier == GamerTier.unknown) continue;
      if (tier.name == normalized) return tier;
    }
    return GamerTier.unknown;
  }
}
