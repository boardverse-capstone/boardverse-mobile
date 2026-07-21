import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';

/// Leaderboard entry model for API response mapping.
class LeaderboardEntryModel {
  final int rank;
  final String oderId;
  final String displayName;
  final String? avatarUrl;
  final int globalElo;
  final int karma;
  final int tournamentsPlayed;
  final int tournamentsWon;

  const LeaderboardEntryModel({
    required this.rank,
    required this.oderId,
    required this.displayName,
    this.avatarUrl,
    required this.globalElo,
    required this.karma,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int? ?? 0,
      oderId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      globalElo: json['globalElo'] as int? ?? 1500,
      karma: json['karma'] as int? ?? 0,
      tournamentsPlayed: json['tournamentsPlayed'] as int? ?? 0,
      tournamentsWon: json['tournamentsWon'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': oderId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'globalElo': globalElo,
      'karma': karma,
      'tournamentsPlayed': tournamentsPlayed,
      'tournamentsWon': tournamentsWon,
    };
  }

  LeaderboardEntryEntity toEntity() {
    return LeaderboardEntryEntity(
      rank: rank,
      oderId: oderId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      globalElo: globalElo,
      karma: karma,
      tournamentsPlayed: tournamentsPlayed,
      tournamentsWon: tournamentsWon,
    );
  }
}
