import 'package:boardverse/features/tournament/domain/entities/elo_history_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/my_elo_history_entity.dart';

/// Model cho response wrapper `GET /tournaments/my-elo-history`.
///
/// Response thật:
/// ```json
/// {
///   "userId": "...",
///   "username": "...",
///   "currentElo": 1200,
///   "history": [
///     { "tournamentId": "...", "tournamentTitle": "...",
///       "tournamentDate": "2026-08-01T09:00:00Z",
///       "eloBefore": 1200, "eloAfter": 1200, "eloDelta": 0,
///       "finalRank": null, "tournamentStatus": "..." }
///   ]
/// }
/// ```
class MyEloHistoryResponseModel {
  final String userId;
  final String username;
  final int currentElo;
  final List<EloHistoryModel> history;

  const MyEloHistoryResponseModel({
    required this.userId,
    required this.username,
    required this.currentElo,
    required this.history,
  });

  factory MyEloHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    final historyList = rawHistory is List
        ? rawHistory
              .whereType<Map>()
              .map(
                (e) =>
                    EloHistoryModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <EloHistoryModel>[];

    return MyEloHistoryResponseModel(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      currentElo: _readInt(json, const ['currentElo'], 1500),
      history: historyList,
    );
  }

  MyEloHistoryResponse toEntity() {
    return MyEloHistoryResponse(
      userId: userId,
      username: username,
      currentElo: currentElo,
      history: history.map((m) => m.toEntity()).toList(),
    );
  }
}

/// Elo history entry model — map 1 phần tử trong `history[]` của
/// `/tournaments/my-elo-history`. Cũng tương thích với shape cũ (nếu
/// backend sau này trả về id/userId).
class EloHistoryModel {
  final String? id;
  final String? userId;
  final String? username;
  final String? displayName;
  final String tournamentTitle;
  final String tournamentId;
  final String? gameTemplateName;
  final int initialElo;
  final int finalElo;
  final int delta;
  final DateTime playedAt;
  final int? rank;
  final String? tournamentStatus;

  const EloHistoryModel({
    this.id,
    this.userId,
    this.username,
    this.displayName,
    required this.tournamentTitle,
    required this.tournamentId,
    this.gameTemplateName,
    required this.initialElo,
    required this.finalElo,
    required this.delta,
    required this.playedAt,
    this.rank,
    this.tournamentStatus,
  });

  factory EloHistoryModel.fromJson(Map<String, dynamic> json) {
    return EloHistoryModel(
      id: _readNullableString(json, const ['id', 'historyId']),
      userId: _readNullableString(json, const ['userId']),
      username: _readNullableString(json, const ['username']),
      displayName: _readNullableString(json, const [
        'displayName',
        'fullName',
        'name',
      ]),
      tournamentTitle: _readString(json, const [
        'tournamentTitle',
        'tournamentName',
        'title',
      ], 'Giải đấu'),
      tournamentId: _readString(json, const ['tournamentId'], ''),
      gameTemplateName: _readNullableString(
        json,
        const ['gameTemplateName', 'gameName'],
      ),
      initialElo: _readInt(json, const ['eloBefore', 'initialElo'], 1500),
      finalElo: _readInt(json, const ['eloAfter', 'finalElo'], 1500),
      delta: _readInt(json, const ['eloDelta', 'delta', 'eloChange'], 0),
      playedAt: _readDateTime(json, const [
        'tournamentDate',
        'playedAt',
        'playedDate',
        'createdAt',
      ]),
      rank: _readNullableInt(json, const ['finalRank', 'rank']),
      tournamentStatus: _readNullableString(json, const [
        'tournamentStatus',
        'status',
      ]),
    );
  }

  EloHistoryEntity toEntity() {
    return EloHistoryEntity(
      id: id,
      userId: userId ?? '',
      displayName: _resolveDisplayName(),
      tournamentTitle: tournamentTitle,
      tournamentId: tournamentId,
      gameTemplateName: gameTemplateName,
      initialElo: initialElo,
      finalElo: finalElo,
      delta: delta,
      playedAt: playedAt,
      rank: rank,
      tournamentStatus: tournamentStatus,
    );
  }

  String _resolveDisplayName() {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (username != null && username!.isNotEmpty) return username!;
    return 'Người chơi';
  }
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

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
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

DateTime _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      // Try next key
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
