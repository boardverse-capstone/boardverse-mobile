import '../../domain/entities/game_category_entity.dart';

class GameCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int gameCount;
  final String? description;

  const GameCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.gameCount,
    this.description,
  });

  factory GameCategoryModel.fromJson(Map<String, dynamic> json) {
    return GameCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String? ?? 'games',
      gameCount: json['gameCount'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'gameCount': gameCount,
      'description': description,
    };
  }

  GameCategoryEntity toEntity() => GameCategoryEntity(
        id: id,
        name: name,
        iconName: iconName,
        gameCount: gameCount,
        description: description,
      );
}
