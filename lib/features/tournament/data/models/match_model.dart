import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';

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
      id: json['id'] as String,
      roundNumber: json['roundNumber'] as int,
      isFinal: json['isFinal'] as bool? ?? false,
      tableNumber: json['tableNumber'] as int? ?? 1,
      status: json['status'] as String,
      winnerId: json['winnerId'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => MatchPlayerResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      actualStartTime: json['actualStartTime'] != null
          ? DateTime.parse(json['actualStartTime'] as String)
          : null,
      actualEndTime: json['actualEndTime'] != null
          ? DateTime.parse(json['actualEndTime'] as String)
          : null,
      notes: json['notes'] as String?,
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
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int cardsBought;
  final bool isWinner;

  const MatchPlayerResultModel({
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.cardsBought,
    required this.isWinner,
  });

  factory MatchPlayerResultModel.fromJson(Map<String, dynamic> json) {
    return MatchPlayerResultModel(
      oderId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      score: json['score'] as int? ?? 0,
      cardsBought: json['cardsBought'] as int? ?? 0,
      isWinner: json['isWinner'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': oderId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'cardsBought': cardsBought,
      'isWinner': isWinner,
    };
  }

  MatchPlayerResult toEntity() {
    return MatchPlayerResult(
      oderId: oderId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      score: score,
      cardsBought: cardsBought,
      isWinner: isWinner,
    );
  }
}
