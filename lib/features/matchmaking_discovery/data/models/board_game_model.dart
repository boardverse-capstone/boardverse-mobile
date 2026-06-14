import '../../domain/entities/board_game_entity.dart';

class BoardGameModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int minPlayers;
  final int maxPlayers;
  final int estimatedMinutes;
  final String category;
  final List<String> components;
  final List<String> mechanics;
  final double rating;

  const BoardGameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedMinutes,
    required this.category,
    required this.components,
    required this.mechanics,
    required this.rating,
  });

  factory BoardGameModel.fromJson(Map<String, dynamic> json) {
    return BoardGameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      estimatedMinutes: json['estimatedMinutes'] as int,
      category: json['category'] as String,
      components: List<String>.from(json['components'] as List),
      mechanics: List<String>.from(json['mechanics'] as List),
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'estimatedMinutes': estimatedMinutes,
      'category': category,
      'components': components,
      'mechanics': mechanics,
      'rating': rating,
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
      );
}
