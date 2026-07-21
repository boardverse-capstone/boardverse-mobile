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
      id: json['id'] as String,
      oderId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String,
      tournamentTitle: json['tournamentTitle'] as String,
      tournamentId: json['tournamentId'] as String,
      initialElo: json['initialElo'] as int? ?? 1500,
      finalElo: json['finalElo'] as int? ?? 1500,
      delta: json['delta'] as int? ?? 0,
      playedAt: DateTime.parse(json['playedAt'] as String),
      rank: json['rank'] as int?,
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
