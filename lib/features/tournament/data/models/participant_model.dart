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
  final int swissScore;
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
      id: json['id'] as String,
      oderId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      elo: json['elo'] as int? ?? 1500,
      karma: json['karma'] as int? ?? 0,
      status: json['status'] as String,
      swissScore: json['swissScore'] as int? ?? 0,
      prestigePoints: json['prestigePoints'] as int? ?? 0,
      finalRank: json['finalRank'] as int?,
      eloDelta: json['eloDelta'] as int? ?? 0,
      isWalkIn: json['isWalkIn'] as bool? ?? false,
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

  TournamentParticipantEntity toEntity({bool isCurrentUser = false}) {
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
    );
  }
}
