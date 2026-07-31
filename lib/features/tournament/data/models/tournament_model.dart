import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';

/// Tournament model for API response mapping.
class TournamentModel {
  final String id;
  final String title;
  final String cafeName;
  final String gameTemplateName;
  final DateTime startTime;
  final DateTime registrationDeadline;
  final String status;
  final int currentParticipants;
  final int maxParticipants;
  final int minKarmaRequirement;
  final int? registrationFee;
  final int prizePool;
  final String description;
  final String? organizerName;
  final int roundDurationMinutes;
  final int preliminaryRounds;
  final int? currentRound;
  final bool isUserRegistered;

  const TournamentModel({
    required this.id,
    required this.title,
    required this.cafeName,
    required this.gameTemplateName,
    required this.startTime,
    required this.registrationDeadline,
    required this.status,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.minKarmaRequirement,
    this.registrationFee,
    required this.prizePool,
    required this.description,
    this.organizerName,
    required this.roundDurationMinutes,
    required this.preliminaryRounds,
    this.currentRound,
    required this.isUserRegistered,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: _readRequiredString(json, const ['id', 'tournamentId']),
      title: _readString(json, const ['title', 'name'], 'Giải đấu'),
      cafeName: _readString(json, const ['cafeName'], 'Chưa cập nhật quán'),
      gameTemplateName: _readString(
        json,
        const ['gameTemplateName', 'gameName'],
        'Splendor',
      ),
      startTime: _readDateTime(json, const ['startTime', 'scheduledStartTime']),
      registrationDeadline: _readDateTime(
        json,
        const ['registrationDeadline'],
      ),
      status: _readString(json, const ['status'], 'Draft'),
      currentParticipants: _readInt(
        json,
        const [
          'currentParticipants',
          'participantCount',
          'registeredParticipantCount',
        ],
        0,
      ),
      maxParticipants: _readInt(json, const ['maxParticipants'], 0),
      minKarmaRequirement: _readInt(
        json,
        const ['minKarmaRequirement'],
        0,
      ),
      registrationFee: _readNullableInt(json, const ['registrationFee']),
      prizePool: _readInt(json, const ['prizePool'], 0),
      description: _readString(json, const ['description'], ''),
      organizerName: _readNullableString(
        json,
        const ['organizerName', 'managerName'],
      ),
      roundDurationMinutes: _readInt(
        json,
        const ['roundDurationMinutes'],
        45,
      ),
      preliminaryRounds: _readInt(json, const ['preliminaryRounds'], 3),
      currentRound: _readNullableInt(json, const ['currentRound']),
      isUserRegistered: _readBool(
        json,
        const ['isUserRegistered', 'isRegistered'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cafeName': cafeName,
      'gameTemplateName': gameTemplateName,
      'startTime': startTime.toIso8601String(),
      'registrationDeadline': registrationDeadline.toIso8601String(),
      'status': status,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'minKarmaRequirement': minKarmaRequirement,
      'registrationFee': registrationFee,
      'prizePool': prizePool,
      'description': description,
      'organizerName': organizerName,
      'roundDurationMinutes': roundDurationMinutes,
      'preliminaryRounds': preliminaryRounds,
      'currentRound': currentRound,
      'isUserRegistered': isUserRegistered,
    };
  }

  TournamentEntity toEntity({
    bool isUserCheckedIn = false,
    int? userCurrentRank,
  }) {
    return TournamentEntity(
      id: id,
      title: title,
      cafeName: cafeName,
      gameTemplateName: gameTemplateName,
      startTime: startTime,
      registrationDeadline: registrationDeadline,
      status: TournamentStatus.fromBackendStatus(status),
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
      minKarmaRequirement: minKarmaRequirement,
      registrationFee: registrationFee,
      prizePool: prizePool,
      description: description,
      organizerName: organizerName,
      roundDurationMinutes: roundDurationMinutes,
      preliminaryRounds: preliminaryRounds,
      currentRound: currentRound,
      isUserRegistered: isUserRegistered,
      isUserCheckedIn: isUserCheckedIn,
      userCurrentRank: userCurrentRank,
    );
  }
}

String _readRequiredString(Map<String, dynamic> json, List<String> keys) {
  final value = _readNullableString(json, keys);
  if (value != null) return value;
  throw FormatException('Tournament response is missing ${keys.join('/')}');
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys,
  String fallback,
) =>
    _readNullableString(json, keys) ?? fallback;

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

int _readInt(Map<String, dynamic> json, List<String> keys, int fallback) =>
    _readNullableInt(json, keys) ?? fallback;

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value?.toString().toLowerCase() == 'true') return true;
  }
  return false;
}

DateTime _readDateTime(Map<String, dynamic> json, List<String> keys) {
  final raw = _readRequiredString(json, keys);
  return DateTime.parse(raw).toLocal();
}
