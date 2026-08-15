import '../../domain/entities/gamer_tier.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';

/// Model cho 1 entry trong leaderboard response. Map linh hoạt cho cả 3
/// metric (karma/elo/level) — các field optional không có trong response
/// của metric đó sẽ để null.
class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final int? karmaPoints;
  final int? globalElo;
  final int? level;
  final GamerTier gamerTier;

  const LeaderboardEntryModel({
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

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: _readInt(json, const ['rank'], 0),
      userId: _readString(json, const ['userId'], ''),
      username: _readString(json, const ['username'], ''),
      displayName: _readNullableString(json, const ['displayName']),
      avatarUrl: _readNullableString(json, const ['avatarUrl', 'avatar']),
      karmaPoints: _readOptionalInt(json, const ['karmaPoints', 'karma']),
      globalElo: _readOptionalInt(
        json,
        const ['globalElo', 'elo', 'tournamentElo'],
      ),
      level: _readOptionalInt(json, const ['level']),
      gamerTier: GamerTier.parse(json['gamerTier']?.toString()),
    );
  }

  LeaderboardEntryEntity toEntity() => LeaderboardEntryEntity(
        rank: rank,
        userId: userId,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        karmaPoints: karmaPoints,
        globalElo: globalElo,
        level: level,
        gamerTier: gamerTier,
      );
}

int _readInt(Map<String, dynamic> json, List<String> keys, int fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

int? _readOptionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys,
  String fallback,
) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}
