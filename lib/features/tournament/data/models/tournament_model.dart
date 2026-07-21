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
      id: json['id'] as String,
      title: json['title'] as String,
      cafeName: json['cafeName'] as String,
      gameTemplateName: json['gameTemplateName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      registrationDeadline: DateTime.parse(json['registrationDeadline'] as String),
      status: json['status'] as String,
      currentParticipants: json['currentParticipants'] as int,
      maxParticipants: json['maxParticipants'] as int,
      minKarmaRequirement: json['minKarmaRequirement'] as int? ?? 0,
      registrationFee: json['registrationFee'] as int?,
      prizePool: json['prizePool'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      organizerName: json['organizerName'] as String?,
      roundDurationMinutes: json['roundDurationMinutes'] as int? ?? 45,
      preliminaryRounds: json['preliminaryRounds'] as int? ?? 3,
      currentRound: json['currentRound'] as int?,
      isUserRegistered: json['isUserRegistered'] as bool? ?? false,
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
