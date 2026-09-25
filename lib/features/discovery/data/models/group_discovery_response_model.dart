import 'package:equatable/equatable.dart';

/// Model cho điểm số sub-group trong Group Discovery.
class SubGroupScoreModel extends Equatable {
  final int subGroupIndex;
  final int? playerCount;
  final int? experienceLevel;
  final double score;
  final String? reason;

  const SubGroupScoreModel({
    required this.subGroupIndex,
    this.playerCount,
    this.experienceLevel,
    required this.score,
    this.reason,
  });

  factory SubGroupScoreModel.fromJson(Map<String, dynamic> json) {
    return SubGroupScoreModel(
      subGroupIndex: json['subGroupIndex'] as int,
      playerCount: json['playerCount'] as int?,
      experienceLevel: json['experienceLevel'] as int?,
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [subGroupIndex, playerCount, experienceLevel, score, reason];
}

/// Model cho game trong Group Discovery.
class GroupBoardGameModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final int playTimeMinutes;
  final double? weight;
  final List<String> categories;
  final double aggregateScore;
  final List<SubGroupScoreModel> subGroupScores;

  const GroupBoardGameModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    this.weight,
    required this.categories,
    required this.aggregateScore,
    required this.subGroupScores,
  });

  factory GroupBoardGameModel.fromJson(Map<String, dynamic> json) {
    return GroupBoardGameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      description: json['description'] as String?,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      playTimeMinutes: json['playTimeMinutes'] as int? ?? json['playTime'] as int? ?? 60,
      weight: (json['weight'] ?? json['bggWeight']) != null
          ? (json['weight'] ?? json['bggWeight'] as num).toDouble()
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['name'] as String? ?? '')
              .toList() ??
          [],
      aggregateScore: (json['aggregateScore'] as num?)?.toDouble() ?? 0,
      subGroupScores: (json['subGroupScores'] as List<dynamic>? ??
              json['subGroupBreakdown'] as List<dynamic>? ??
              [])
          .map((e) => SubGroupScoreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id, name, imageUrl, description, minPlayers, maxPlayers,
        playTimeMinutes, weight, categories, aggregateScore, subGroupScores,
      ];
}

/// Wrapper response cho Group Discovery.
class GroupDiscoveryResponseModel extends Equatable {
  final List<GroupBoardGameModel> games;
  final int totalCount;
  final bool hasMore;

  const GroupDiscoveryResponseModel({
    required this.games,
    required this.totalCount,
    required this.hasMore,
  });

  factory GroupDiscoveryResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final gamesList = data['games'] as List<dynamic>? ?? [];
    return GroupDiscoveryResponseModel(
      games: gamesList
          .map((e) => GroupBoardGameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? gamesList.length,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [games, totalCount, hasMore];
}
