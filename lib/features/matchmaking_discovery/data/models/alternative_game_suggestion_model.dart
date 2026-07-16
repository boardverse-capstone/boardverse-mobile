import '../../domain/entities/alternative_game_suggestion_entity.dart';
import 'game_category_model.dart';

class AlternativeGameSuggestionModel {
  final String gameTemplateId;
  final String? gameName;
  final String? thumbnailUrl;
  final int? minPlayers;
  final int? maxPlayers;
  final int nearbyCafeCount;
  final double nearestCafeDistanceMeters;
  final int availableBoxCount;
  final List<GameCategoryModel> sharedCategories;

  const AlternativeGameSuggestionModel({
    required this.gameTemplateId,
    this.gameName,
    this.thumbnailUrl,
    this.minPlayers,
    this.maxPlayers,
    required this.nearbyCafeCount,
    required this.nearestCafeDistanceMeters,
    required this.availableBoxCount,
    this.sharedCategories = const [],
  });

  factory AlternativeGameSuggestionModel.fromJson(Map<String, dynamic> json) {
    return AlternativeGameSuggestionModel(
      gameTemplateId: (json['gameTemplateId'] as String?) ?? '',
      gameName: json['gameName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      minPlayers: (json['minPlayers'] as num?)?.toInt(),
      maxPlayers: (json['maxPlayers'] as num?)?.toInt(),
      nearbyCafeCount: (json['nearbyCafeCount'] as num?)?.toInt() ?? 0,
      nearestCafeDistanceMeters:
          ((json['nearestCafeDistanceMeters'] as num?) ?? 0).toDouble(),
      availableBoxCount: (json['availableBoxCount'] as num?)?.toInt() ?? 0,
      sharedCategories: (json['sharedCategories'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(GameCategoryModel.fromJson)
              .toList() ??
          const <GameCategoryModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameTemplateId': gameTemplateId,
      'gameName': gameName,
      'thumbnailUrl': thumbnailUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'nearbyCafeCount': nearbyCafeCount,
      'nearestCafeDistanceMeters': nearestCafeDistanceMeters,
      'availableBoxCount': availableBoxCount,
      'sharedCategories':
          sharedCategories.map((c) => c.toJson()).toList(),
    };
  }

  AlternativeGameSuggestionEntity toEntity() =>
      AlternativeGameSuggestionEntity(
        gameTemplateId: gameTemplateId,
        gameName: gameName,
        thumbnailUrl: thumbnailUrl,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        nearbyCafeCount: nearbyCafeCount,
        nearestCafeDistanceMeters: nearestCafeDistanceMeters,
        availableBoxCount: availableBoxCount,
        sharedCategories:
            sharedCategories.map((c) => c.toEntity()).toList(),
      );
}
