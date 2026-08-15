import 'leaderboard_entry_entity.dart';

/// Result wrapper for a leaderboard request — `entries` + phân trang
/// metadata + optional `userRank` (chỉ trả khi request có JWT và viewer
/// nằm trong top 1000).
///
/// Backend response (xem `.agents/docs/apis_docs/leaderboard.md`):
/// ```json
/// {
///   "entries": [ ... ],
///   "offset": 0,
///   "limit": 50,
///   "totalCount": 10000,
///   "generatedAt": "2026-08-08T10:00:00Z",
///   "userRank": null | { ...LeaderboardEntry-like... }
/// }
/// ```
class LeaderboardResultEntity {
  final List<LeaderboardEntryEntity> entries;
  final int offset;
  final int limit;
  final int totalCount;
  final DateTime generatedAt;

  /// Rank của viewer (null khi auth chưa đăng nhập hoặc nằm ngoài top 1000).
  final LeaderboardEntryEntity? userRank;

  const LeaderboardResultEntity({
    required this.entries,
    required this.offset,
    required this.limit,
    required this.totalCount,
    required this.generatedAt,
    this.userRank,
  });

  bool get isEmpty => entries.isEmpty;
  bool get hasMore => offset + entries.length < totalCount;
}
