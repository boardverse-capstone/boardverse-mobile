import 'gamer_tier.dart';

/// Single entry in a leaderboard response.
///
/// Backend định nghĩa 2 schema entry hơi khác nhau theo metric:
/// - `/karma`: `rank, userId, username, displayName, avatarUrl, karmaPoints,
///   globalElo, level, gamerTier`
/// - `/elo`: `rank, userId, username, avatarUrl, globalElo, gamerTier, level`
///   (không có `karmaPoints`, không có `displayName`)
/// - `/level`: `rank, userId, username, avatarUrl, level, gamerTier,
///   globalElo` (client-side không fill được `currentExp`)
///
/// Entity này lưu **tất cả** các field optional — optional trong Dart
/// tương ứng "có thể không xuất hiện trong response của metric đó". UI đọc
/// `displayName ?? username` cho tên hiển thị, đọc `globalElo`/`karmaPoints`/
/// `level` theo `LeaderboardKind` đang xem.
class LeaderboardEntryEntity {
  final int rank;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  /// Karma Points — chỉ có ở `/karma`.
  final int? karmaPoints;

  /// Global Elo — có ở `/karma` + `/elo` + `/level`.
  final int? globalElo;

  /// Level — có ở `/karma` + `/elo` + `/level`.
  final int? level;

  /// Gamer Tier — backend tính sẵn theo Karma (xem `gamer_tier.dart`).
  final GamerTier gamerTier;

  const LeaderboardEntryEntity({
    required this.rank,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.karmaPoints,
    this.globalElo,
    this.level,
    this.gamerTier = GamerTier.unknown,
  });

  /// Tên hiển thị ưu tiên — `displayName` trước, fallback `username`.
  String get resolvedName {
    final n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return username;
  }

  @override
  String toString() =>
      'LeaderboardEntryEntity(rank: $rank, name: $resolvedName, '
      'karma: $karmaPoints, elo: $globalElo, level: $level, '
      'tier: ${gamerTier.label})';
}
