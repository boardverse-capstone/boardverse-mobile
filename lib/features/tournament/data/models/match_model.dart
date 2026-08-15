import 'package:boardverse/features/tournament/domain/entities/tournament_match_entity.dart';

/// Tournament match model for API response mapping.
class TournamentMatchModel {
  final String id;
  final int roundNumber;
  final bool isFinal;
  final int tableNumber;
  final String status;
  final String? winnerId;
  final List<MatchPlayerResultModel> results;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String? notes;

  const TournamentMatchModel({
    required this.id,
    required this.roundNumber,
    required this.isFinal,
    required this.tableNumber,
    required this.status,
    this.winnerId,
    required this.results,
    this.actualStartTime,
    this.actualEndTime,
    this.notes,
  });

  factory TournamentMatchModel.fromJson(Map<String, dynamic> json) {
    return TournamentMatchModel(
      id: _readString(json, const ['id', 'matchId'], ''),
      roundNumber: _readInt(json, const ['roundNumber', 'round'], 1),
      isFinal: _readBool(json, const ['isFinal', 'final']),
      tableNumber: _readInt(json, const ['tableNumber', 'table'], 1),
      status: _readString(json, const ['status', 'matchStatus'], 'Scheduled'),
      winnerId: _readNullableString(json, const ['winnerId', 'winnerUserId']),
      results: _readResults(json['results']),
      actualStartTime: _readNullableDateTime(json, const [
        'actualStartTime',
        'startedAt',
      ]),
      actualEndTime: _readNullableDateTime(json, const [
        'actualEndTime',
        'endedAt',
      ]),
      notes: _readNullableString(json, const ['notes', 'note']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundNumber': roundNumber,
      'isFinal': isFinal,
      'tableNumber': tableNumber,
      'status': status,
      'winnerId': winnerId,
      'results': results.map((e) => e.toJson()).toList(),
      'actualStartTime': actualStartTime?.toIso8601String(),
      'actualEndTime': actualEndTime?.toIso8601String(),
      'notes': notes,
    };
  }

  TournamentMatchEntity toEntity() {
    return TournamentMatchEntity(
      id: id,
      roundNumber: roundNumber,
      isFinal: isFinal,
      tableNumber: tableNumber,
      status: MatchStatus.fromString(status),
      winnerId: winnerId,
      results: results.map((e) => e.toEntity()).toList(),
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      notes: notes,
    );
  }
}

/// Individual player result model.
class MatchPlayerResultModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int cardsBought;
  final bool isWinner;

  const MatchPlayerResultModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.cardsBought,
    required this.isWinner,
  });

  factory MatchPlayerResultModel.fromJson(Map<String, dynamic> json) {
    // Display name: backend trả `username` cho player; `walkInDisplayName`
    // cho walk-in; fallback các alias khác để tương thích ngược.
    String displayName = 'Người chơi';
    final walkIn = _readString(json, const ['walkInDisplayName'], '');
    final username = _readString(json, const ['username'], '');
    if (walkIn.isNotEmpty) {
      displayName = walkIn;
    } else if (username.isNotEmpty) {
      displayName = username;
    } else {
      displayName = _readString(json, const [
        'displayName',
        'fullName',
        'name',
      ], 'Người chơi');
    }

    return MatchPlayerResultModel(
      userId: _readString(json, const ['userId', 'oderId'], ''),
      displayName: displayName,
      avatarUrl: _readNullableString(json, const ['avatarUrl', 'avatar']),
      score: _readInt(json, const ['score', 'finalScore', 'prestigePoints'], 0),
      cardsBought: _readInt(json, const ['cardsBought', 'cards'], 0),
      isWinner: _readBool(json, const ['isWinner', 'winner']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'cardsBought': cardsBought,
      'isWinner': isWinner,
    };
  }

  MatchPlayerResult toEntity() {
    return MatchPlayerResult(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      score: score,
      cardsBought: cardsBought,
      isWinner: isWinner,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────

List<MatchPlayerResultModel> _readResults(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => MatchPlayerResultModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
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

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    final str = value?.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
  }
  return false;
}

DateTime? _readNullableDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    try {
      if (value is DateTime) return value.toLocal();
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      // Try next key
    }
  }
  return null;
}
