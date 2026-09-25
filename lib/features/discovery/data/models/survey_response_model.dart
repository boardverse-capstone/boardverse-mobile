import 'package:equatable/equatable.dart';

/// Model cho một game trong Survey response.
class RecommendedBoardGameModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final double? weight;
  final int minPlayers;
  final int maxPlayers;
  final int playTimeMinutes;
  final List<String> categories;
  final double score;
  final List<String> matchReasons;

  const RecommendedBoardGameModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.weight,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    required this.categories,
    required this.score,
    required this.matchReasons,
  });

  factory RecommendedBoardGameModel.fromJson(Map<String, dynamic> json) {
    return RecommendedBoardGameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      weight: (json['weight'] ?? json['bggWeight']) != null
          ? (json['weight'] ?? json['bggWeight'] as num).toDouble()
          : null,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      playTimeMinutes: json['playTimeMinutes'] as int? ??
          json['playTime'] as int? ??
          json['minPlaytime'] as int? ??
          60,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['name'] as String? ?? '')
              .toList() ??
          [],
      score: (json['score'] as num?)?.toDouble() ?? 0,
      matchReasons: (json['matchReasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        id, name, imageUrl, weight, minPlayers, maxPlayers,
        playTimeMinutes, categories, score, matchReasons,
      ];
}

/// Wrapper response cho Survey.
class SurveyResponseModel extends Equatable {
  final List<RecommendedBoardGameModel> games;
  final int totalCount;
  final bool hasMore;
  final String? message;

  const SurveyResponseModel({
    required this.games,
    required this.totalCount,
    required this.hasMore,
    this.message,
  });

  factory SurveyResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final gamesList = data['games'] as List<dynamic>? ?? [];
    return SurveyResponseModel(
      games: gamesList
          .map((e) => RecommendedBoardGameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? gamesList.length,
      hasMore: data['hasMore'] as bool? ?? false,
      message: data['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [games, totalCount, hasMore, message];
}
