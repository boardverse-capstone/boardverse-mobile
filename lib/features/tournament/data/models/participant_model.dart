import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';

/// Tournament participant model for API response mapping.
class TournamentParticipantModel {
  final String id;
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int elo;
  final int karma;
  final String status;
  final double swissScore;
  final int prestigePoints;
  final int? finalRank;
  final int eloDelta;
  final bool isWalkIn;

  const TournamentParticipantModel({
    required this.id,
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.elo,
    required this.karma,
    required this.status,
    required this.swissScore,
    required this.prestigePoints,
    this.finalRank,
    required this.eloDelta,
    required this.isWalkIn,
  });

  factory TournamentParticipantModel.fromJson(Map<String, dynamic> json) {
    return TournamentParticipantModel(
      id: _readRequiredString(json, const [
        'id',
        'participantId',
      ], fallback: ''),
      oderId: _readString(json, const ['userId', 'oderId'], ''),
      displayName: _readString(json, const [
        'displayName',
        'fullName',
        'name',
      ], 'Người chơi'),
      avatarUrl: _readNullableString(json, const ['avatarUrl', 'avatar']),
      elo: _readInt(json, const ['finalElo', 'initialElo', 'elo'], 1500),
      karma: _readInt(json, const [
        'karmaAtRegistration',
        'karma',
        'karmaPoints',
      ], 0),
      status: _readString(json, const ['status'], 'Registered'),
      swissScore: _readSwissScore(json),
      prestigePoints: _readInt(json, const [
        'totalPrestigePoints',
        'prestigePoints',
      ], 0),
      finalRank: _readNullableInt(json, const ['finalRank', 'rank']),
      eloDelta: _readInt(json, const ['eloDelta'], 0),
      isWalkIn: _readBool(json, const ['isWalkIn', 'walkIn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': oderId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'elo': elo,
      'karma': karma,
      'status': status,
      'swissScore': swissScore,
      'prestigePoints': prestigePoints,
      'finalRank': finalRank,
      'eloDelta': eloDelta,
      'isWalkIn': isWalkIn,
    };
  }

  TournamentParticipantEntity toEntity({
    bool isCurrentUser = false,
    int? totalRounds,
  }) {
    return TournamentParticipantEntity(
      id: id,
      oderId: oderId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      elo: elo,
      karma: karma,
      status: ParticipantStatus.fromString(status),
      swissScore: swissScore,
      prestigePoints: prestigePoints,
      finalRank: finalRank,
      eloDelta: eloDelta,
      isWalkIn: isWalkIn,
      isCurrentUser: isCurrentUser,
      totalRounds: totalRounds,
    );
  }
}

double _readSwissScore(Map<String, dynamic> json) {
  final explicit = json['swissScore'];
  if (explicit is num) return explicit.toDouble();
  final str = explicit?.toString();
  if (str != null && str.isNotEmpty) {
    final parsed = double.tryParse(str);
    if (parsed != null) return parsed;
  }

  final wins = _readInt(json, const ['swissWins'], 0);
  final draws = _readInt(json, const ['swissDraws'], 0);
  final losses = _readInt(json, const ['swissLosses'], 0);
  return wins + draws * 0.5 - losses * 0.5;
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

String _readRequiredString(
  Map<String, dynamic> json,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}
