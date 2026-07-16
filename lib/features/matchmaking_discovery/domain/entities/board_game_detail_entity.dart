import 'package:equatable/equatable.dart';

import 'board_game_entity.dart';
import 'game_category_entity.dart';
import 'game_component_entity.dart';

/// Entity đầy đủ cho màn chi tiết board game — bao gồm components[]
/// và categories[] (mảng), dùng cho UI "Linh kiện trong hộp".
class BoardGameDetailEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int minPlayers;
  final int maxPlayers;
  final int playTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<GameCategoryEntity> categories;
  final List<GameComponentEntity> components;

  const BoardGameDetailEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTime,
    this.createdAt,
    this.updatedAt,
    this.categories = const [],
    this.components = const [],
  });

  /// Rút gọn về [BoardGameEntity] cho danh sách/UI dùng chung (card, search).
  BoardGameEntity toBoardGameEntity({
    String? fallbackCategory,
    String? fallbackImageUrl,
    List<String>? fallbackComponents,
    List<String> mechanics = const [],
    double rating = 0,
  }) {
    final derivedCategory =
        (categories.isNotEmpty ? categories.first.name : null) ??
            fallbackCategory ??
            '';
    return BoardGameEntity(
      id: id,
      name: name,
      description: description,
      imageUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : (fallbackImageUrl ?? ''),
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      estimatedMinutes: playTime,
      category: derivedCategory,
      components: fallbackComponents ??
          components
              .map((c) =>
                  '${c.componentName} (x${c.defaultQuantity})')
              .toList(),
      mechanics: mechanics,
      rating: rating,
      componentCount: components.length,
      categories: categories,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        thumbnailUrl,
        minPlayers,
        maxPlayers,
        playTime,
        createdAt,
        updatedAt,
        categories,
        components,
      ];
}
