import 'package:equatable/equatable.dart';

/// Model cho một game trong danh sách "Đã lưu".
class SavedBoardGameModel extends Equatable {
  final String id;
  final String gameTemplateId;
  final String gameName;
  final String? thumbnailUrl;
  final List<String> categories;
  final double? weight;
  final int? playTime;
  final DateTime savedAt;

  const SavedBoardGameModel({
    required this.id,
    required this.gameTemplateId,
    required this.gameName,
    this.thumbnailUrl,
    required this.categories,
    this.weight,
    this.playTime,
    required this.savedAt,
  });

  factory SavedBoardGameModel.fromJson(Map<String, dynamic> json) {
    return SavedBoardGameModel(
      id: json['id'] as String,
      gameTemplateId: json['gameTemplateId'] as String,
      gameName: json['gameName'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['name'] as String? ?? '')
              .toList() ??
          [],
      weight: (json['weight'] ?? json['bggWeight']) != null
          ? (json['weight'] ?? json['bggWeight'] as num).toDouble()
          : null,
      playTime: json['playTime'] as int?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, gameTemplateId, gameName, thumbnailUrl,
        categories, weight, playTime, savedAt,
      ];
}

/// Wrapper response cho GET /saved.
class SavedGamesResponseModel extends Equatable {
  final List<SavedBoardGameModel> savedGames;
  final int totalCount;

  const SavedGamesResponseModel({
    required this.savedGames,
    required this.totalCount,
  });

  factory SavedGamesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final gamesList = data['savedGames'] as List<dynamic>? ?? data['games'] as List<dynamic>? ?? [];
    return SavedGamesResponseModel(
      savedGames: gamesList
          .map((e) => SavedBoardGameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: data['totalCount'] as int? ?? gamesList.length,
    );
  }

  @override
  List<Object?> get props => [savedGames, totalCount];
}
