import 'package:equatable/equatable.dart';

import 'board_game_entity.dart';
import 'game_category_entity.dart';

/// Gợi ý game thay thế khi không tìm thấy quán nào trong bán kính — map
/// từ `alternativeSuggestions[]` của `GET /api/cafes/nearby` (AC 5.2).
class AlternativeGameSuggestionEntity extends Equatable {
  final String gameTemplateId;
  final String? gameName;
  final String? thumbnailUrl;
  final int? minPlayers;
  final int? maxPlayers;
  final int nearbyCafeCount;
  final double nearestCafeDistanceMeters;
  final int availableBoxCount;
  final List<GameCategoryEntity> sharedCategories;

  const AlternativeGameSuggestionEntity({
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

  /// Chuyển sang [BoardGameEntity] để tái sử dụng [SimilarGamesCarousel].
  /// Các trường thiếu (description, rating, mechanics, components) sẽ dùng
  /// default — page sẽ tự load chi tiết khi user bấm vào.
  BoardGameEntity toBoardGameEntity() => BoardGameEntity(
        id: gameTemplateId,
        name: gameName ?? 'Game',
        description: '',
        imageUrl: thumbnailUrl ?? '',
        minPlayers: minPlayers ?? 1,
        maxPlayers: maxPlayers ?? 4,
        estimatedMinutes: 0,
        category: sharedCategories.isNotEmpty
            ? sharedCategories.first.name
            : '',
        components: const [],
        mechanics: const [],
        rating: 0,
      );

  @override
  List<Object?> get props => [
        gameTemplateId,
        gameName,
        thumbnailUrl,
        minPlayers,
        maxPlayers,
        nearbyCafeCount,
        nearestCafeDistanceMeters,
        availableBoxCount,
        sharedCategories,
      ];
}
