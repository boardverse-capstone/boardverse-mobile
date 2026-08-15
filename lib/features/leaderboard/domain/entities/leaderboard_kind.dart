/// 3 loại leaderboard được backend hỗ trợ (xem
/// `.agents/docs/apis_docs/leaderboard.md` + `GET /api/v1/leaderboard/*`).
///
/// Tất cả đều public — auth optional. Nếu có JWT, response kèm `userRank`.
enum LeaderboardKind {
  elo,
  level,
  karma;

  /// Path segment dùng trong URL (vd `/api/v1/leaderboard/elo`).
  String get pathSegment {
    switch (this) {
      case LeaderboardKind.elo:
        return 'elo';
      case LeaderboardKind.level:
        return 'level';
      case LeaderboardKind.karma:
        return 'karma';
    }
  }

  /// Tên tiếng Việt hiển thị ở UI.
  String get label {
    switch (this) {
      case LeaderboardKind.elo:
        return 'ELO';
      case LeaderboardKind.level:
        return 'Level';
      case LeaderboardKind.karma:
        return 'Karma';
    }
  }

  /// Field dùng để sắp xếp / hiển thị giá trị chính trong entry.
  /// UI hiển thị số này ở cột phải của row.
  String get primaryMetricLabel {
    switch (this) {
      case LeaderboardKind.elo:
        return 'ELO';
      case LeaderboardKind.level:
        return 'Level';
      case LeaderboardKind.karma:
        return 'Karma';
    }
  }

  /// Mô tả ngắn hiển thị ở header/sheet.
  String get description {
    switch (this) {
      case LeaderboardKind.elo:
        return 'Xếp hạng theo Global Elo';
      case LeaderboardKind.level:
        return 'Xếp hạng theo Level (lâu năm)';
      case LeaderboardKind.karma:
        return 'Xếp hạng theo Karma Points';
    }
  }
}
