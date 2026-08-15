import 'package:boardverse/features/tournament/domain/entities/my_registration_entity.dart';

/// Model cho response `GET /tournaments/my-registrations`.
///
/// Backend trả về một flat shape trộn tournament + participant, KHÔNG
/// phải `TournamentResponseDto`. Ví dụ:
///
/// ```json
/// {
///   "tournamentId": "...",
///   "title": "...",
///   "cafeId": "...",
///   "cafeName": "...",
///   "startTime": "2026-08-10T09:00:00Z",
///   "tournamentStatus": "RegistrationOpen",
///   "participantId": "...",
///   "participantStatus": "Registered",
///   "isWalkIn": false,
///   "walkInDisplayName": null,
///   "registeredAt": "...",
///   "checkedInAt": null,
///   "swissScore": 0, "swissWins": 0, "swissDraws": 0, "swissLosses": 0,
///   "finalRank": null,
///   "initialElo": 1200, "finalElo": 1200, "eloDelta": 0
/// }
/// ```
class MyRegistrationModel {
  final String tournamentId;
  final String title;
  final String cafeId;
  final String cafeName;
  final DateTime startTime;
  final String tournamentStatus;
  final String participantId;
  final String participantStatus;
  final bool isWalkIn;
  final String? walkInDisplayName;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final double swissScore;
  final int swissWins;
  final int swissDraws;
  final int swissLosses;
  final int? finalRank;
  final int initialElo;
  final int finalElo;
  final int eloDelta;

  const MyRegistrationModel({
    required this.tournamentId,
    required this.title,
    required this.cafeId,
    required this.cafeName,
    required this.startTime,
    required this.tournamentStatus,
    required this.participantId,
    required this.participantStatus,
    required this.isWalkIn,
    this.walkInDisplayName,
    required this.registeredAt,
    this.checkedInAt,
    required this.swissScore,
    required this.swissWins,
    required this.swissDraws,
    required this.swissLosses,
    this.finalRank,
    required this.initialElo,
    required this.finalElo,
    required this.eloDelta,
  });

  factory MyRegistrationModel.fromJson(Map<String, dynamic> json) {
    return MyRegistrationModel(
      tournamentId: _readString(json, const ['tournamentId'], ''),
      title: _readString(json, const ['title', 'name'], 'Giải đấu'),
      cafeId: _readString(json, const ['cafeId'], ''),
      cafeName: _readString(json, const ['cafeName'], 'Chưa cập nhật quán'),
      startTime: _readDateTime(json, const ['startTime']),
      tournamentStatus: _readString(
        json,
        const ['tournamentStatus', 'status'],
        'Draft',
      ),
      participantId: _readString(json, const ['participantId'], ''),
      participantStatus: _readString(
        json,
        const ['participantStatus'],
        'Registered',
      ),
      isWalkIn: _readBool(json, const ['isWalkIn', 'walkIn']),
      walkInDisplayName: _readNullableString(
        json,
        const ['walkInDisplayName'],
      ),
      registeredAt: _readDateTime(json, const ['registeredAt']),
      checkedInAt: _readNullableDateTime(json, const ['checkedInAt']),
      swissScore: _readSwissScore(json),
      swissWins: _readInt(json, const ['swissWins'], 0),
      swissDraws: _readInt(json, const ['swissDraws'], 0),
      swissLosses: _readInt(json, const ['swissLosses'], 0),
      finalRank: _readNullableInt(json, const ['finalRank', 'rank']),
      initialElo: _readInt(json, const ['initialElo'], 1500),
      finalElo: _readInt(json, const ['finalElo'], 1500),
      eloDelta: _readInt(json, const ['eloDelta'], 0),
    );
  }

  MyRegistrationEntry toEntity() {
    return MyRegistrationEntry(
      tournamentId: tournamentId,
      title: title,
      cafeId: cafeId,
      cafeName: cafeName,
      startTime: startTime,
      tournamentStatus: tournamentStatus,
      participantId: participantId,
      participantStatus: participantStatus,
      isWalkIn: isWalkIn,
      walkInDisplayName: walkInDisplayName,
      registeredAt: registeredAt,
      checkedInAt: checkedInAt,
      swissScore: swissScore,
      swissWins: swissWins,
      swissDraws: swissDraws,
      swissLosses: swissLosses,
      finalRank: finalRank,
      initialElo: initialElo,
      finalElo: finalElo,
      eloDelta: eloDelta,
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

DateTime _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      // try next key
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      // try next key
    }
  }
  return null;
}
