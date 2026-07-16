import '../../domain/entities/board_game_entity.dart';
import 'game_category_model.dart';

class BoardGameModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  /// `thumbnailUrl` từ backend — dùng làm `imageUrl` cho UI.
  /// Field này tách riêng để các nơi cần lấy `thumbnailUrl` thật (vd. card
  /// hiển thị ảnh catalog) có thể đọc trực tiếp, không phải suy ra.
  final String? thumbnailUrl;

  final int minPlayers;
  final int maxPlayers;
  final int estimatedMinutes;

  /// `playTime` từ backend — alias cho `estimatedMinutes`.
  final int? playTime;

  final String category;
  final List<String> components;
  final List<String> mechanics;
  final double rating;
  final int componentCount;
  final List<GameCategoryModel> categories;

  const BoardGameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedMinutes,
    this.playTime,
    required this.category,
    required this.components,
    required this.mechanics,
    required this.rating,
    this.componentCount = 0,
    this.categories = const [],
  });

  /// Parse từ response `GET /api/v1/board-games` (list) — JSON đã qua
  /// `ApiResponse.data.data[]`.
  factory BoardGameModel.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(GameCategoryModel.fromJson)
            .toList() ??
        const <GameCategoryModel>[];

    final derivedCategory = categories.isNotEmpty
        ? categories.first.name
        : (json['category'] as String? ?? '');

    return BoardGameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      imageUrl: (json['thumbnailUrl'] as String?) ??
          (json['imageUrl'] as String? ?? ''),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      minPlayers: (json['minPlayers'] as num).toInt(),
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      estimatedMinutes: ((json['playTime'] as num?) ??
              (json['estimatedMinutes'] as num? ??
                  0))
          .toInt(),
      playTime: (json['playTime'] as num?)?.toInt(),
      category: derivedCategory,
      components:
          (json['components'] as List?)?.cast<String>() ?? const <String>[],
      mechanics: (json['mechanics'] as List?)?.cast<String>() ??
          const <String>[],
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      componentCount: (json['componentCount'] as num?)?.toInt() ?? 0,
      categories: categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'estimatedMinutes': estimatedMinutes,
      'playTime': playTime,
      'category': category,
      'components': components,
      'mechanics': mechanics,
      'rating': rating,
      'componentCount': componentCount,
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  BoardGameEntity toEntity() => BoardGameEntity(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        estimatedMinutes: estimatedMinutes,
        category: category,
        components: components,
        mechanics: mechanics,
        rating: rating,
        componentCount: componentCount,
        categories: categories.map((c) => c.toEntity()).toList(),
      );
}
