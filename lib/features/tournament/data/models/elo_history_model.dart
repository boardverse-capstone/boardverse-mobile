import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';

/// Elo history model for API response mapping.
class EloHistoryModel {
  final String id;
  final String oderId;
  final String displayName;
  final String tournamentTitle;
  final String tournamentId;
  final int initialElo;
  final int finalElo;
  final int delta;
  final DateTime playedAt;
  final int? rank;

  const EloHistoryModel({
    required this.id,
    required this.oderId,
    required this.displayName,
    required this.tournamentTitle,
    required this.tournamentId,
    required this.initialElo,
    required this.finalElo,
    required this.delta,
    required this.playedAt,
    this.rank,
  });

  factory EloHistoryModel.fromJson(Map<String, dynamic> json) {
    return EloHistoryModel(
      id: _readString(json, const ['id', 'historyId'], ''),
      oderId: _readString(json, const ['userId', 'oderId'], ''),
      displayName: _readString(json, const [
        'displayName',
        'fullName',
        'name',
      ], 'Người chơi'),
      tournamentTitle: _readString(json, const [
        'tournamentTitle',
        'tournamentName',
        'title',
      ], 'Giải đấu'),
      tournamentId: _readString(json, const ['tournamentId'], ''),
      initialElo: _readInt(json, const ['initialElo', 'eloBefore'], 1500),
      finalElo: _readInt(json, const ['finalElo', 'eloAfter'], 1500),
      delta: _readInt(json, const ['delta', 'eloDelta', 'eloChange'], 0),
      playedAt: _readDateTime(json, const [
        'playedAt',
        'playedDate',
        'createdAt',
      ]),
      rank: _readNullableInt(json, const ['rank', 'finalRank']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': oderId,
      'displayName': displayName,
      'tournamentTitle': tournamentTitle,
      'tournamentId': tournamentId,
      'initialElo': initialElo,
      'finalElo': finalElo,
      'delta': delta,
      'playedAt': playedAt.toIso8601String(),
      'rank': rank,
    };
  }

  EloHistoryEntity toEntity() {
    return EloHistoryEntity(
      id: id,
      oderId: oderId,
      displayName: displayName,
      tournamentTitle: tournamentTitle,
      tournamentId: tournamentId,
      initialElo: initialElo,
      finalElo: finalElo,
      delta: delta,
      playedAt: playedAt,
      rank: rank,
    );
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
