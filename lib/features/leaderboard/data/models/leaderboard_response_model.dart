import '../../domain/entities/leaderboard_kind.dart';
import '../../domain/entities/leaderboard_result_entity.dart';
import 'leaderboard_entry_model.dart';

/// Model cho wrapper response của `/api/v1/leaderboard/*`.
///
/// Backend schema (xem `.agents/docs/apis_docs/leaderboard.md`):
/// ```json
/// {
///   "entries": [...],
///   "offset": 0,
///   "limit": 50,
///   "totalCount": 10000,
///   "generatedAt": "2026-08-08T10:00:00Z",
///   "userRank": null | { ...entry... }
/// }
/// ```
class LeaderboardResponseModel {
  final List<LeaderboardEntryModel> entries;
  final int offset;
  final int limit;
  final int totalCount;
  final DateTime generatedAt;
  final LeaderboardEntryModel? userRank;

  /// Kind tương ứng với response — lưu từ datasource [fetch] để tiện
  /// debug/log. Không serialize qua JSON.
  final LeaderboardKind kind;

  const LeaderboardResponseModel({
    required this.entries,
    required this.offset,
    required this.limit,
    required this.totalCount,
    required this.generatedAt,
    this.userRank,
    required this.kind,
  });

  factory LeaderboardResponseModel.fromJson(
    Map<String, dynamic> json, {
    required LeaderboardKind kind,
  }) {
    final rawEntries = (json['entries'] as List?) ?? const [];
    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntryModel.fromJson)
        .toList(growable: false);

    final rawUserRank = json['userRank'];
    final userRank = rawUserRank is Map<String, dynamic>
        ? LeaderboardEntryModel.fromJson(rawUserRank)
        : null;

    return LeaderboardResponseModel(
      entries: entries,
      offset: _readInt(json['offset'], 0),
      limit: _readInt(json['limit'], 50),
      totalCount: _readInt(json['totalCount'], entries.length),
      generatedAt: _parseDate(json['generatedAt']) ?? DateTime.now(),
      userRank: userRank,
      kind: kind,
    );
  }

  LeaderboardResultEntity toEntity() {
    return LeaderboardResultEntity(
      entries: entries.map((e) => e.toEntity()).toList(growable: false),
      offset: offset,
      limit: limit,
      totalCount: totalCount,
      generatedAt: generatedAt,
      userRank: userRank?.toEntity(),
    );
  }
}

int _readInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed ?? fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
