import '../../domain/entities/board_game_entity.dart';
import 'game_category_model.dart';

/// Model parse từ response của `GET /api/cafes/{cafeId}/active-games`.
///
/// Backend trả `PaginatedResponse<CafeActiveGameDto>` — mỗi item có:
/// - Core game info (id, name, thumbnail, min/maxPlayers, playTime, categories)
/// - Cafe-specific inventory info (inventoryId, boxQuantity, availableBoxCount,
///   isAvailableNow, status)
///
/// Field `inventoryId` là mã kho tại quán (dùng khi gọi reservation).
/// Field `gameTemplateId` là mã master game — dùng làm `id` khi convert
/// sang [BoardGameEntity] (vì BoardGameEntity.id là gameTemplateId).
///
/// Docs: `.agents/docs/apis_docs/cafe.md` §GET /api/cafes/{cafeId}/active-games
class CafeActiveGameModel {
  /// Mã kho tại quán (CafeGameInventory.Id) — dùng khi gọi reservation API.
  final String inventoryId;

  /// Mã master game — map sang [BoardGameEntity.id].
  final String gameTemplateId;

  final String gameName;
  final String? thumbnailUrl;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final int playTime;
  final int boxQuantity;

  /// Số hộp đang trống (Status=Available, IsActive=true).
  /// Player có thể đặt ngay khi `availableBoxCount > 0`.
  final int availableBoxCount;

  /// `true` ⇔ `availableBoxCount > 0`.
  final bool isAvailableNow;

  /// `true` ⇔ `minPlayers <= groupSize` khi client truyền `groupSize`;
  /// `null` khi không truyền.
  final bool? fitsGroupSize;

  /// Trạng thái vận hành: `Available` hoặc `InUse`.
  final String status;

  final List<GameCategoryModel> categories;

  const CafeActiveGameModel({
    required this.inventoryId,
    required this.gameTemplateId,
    required this.gameName,
    this.thumbnailUrl,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTime,
    required this.boxQuantity,
    required this.availableBoxCount,
    required this.isAvailableNow,
    this.fitsGroupSize,
    required this.status,
    required this.categories,
  });

  factory CafeActiveGameModel.fromJson(Map<String, dynamic> json) {
    return CafeActiveGameModel(
      inventoryId: json['inventoryId'] as String,
      gameTemplateId: json['gameTemplateId'] as String,
      gameName: json['gameName'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
      minPlayers: (json['minPlayers'] as num).toInt(),
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      playTime: (json['playTime'] as num).toInt(),
      boxQuantity: (json['boxQuantity'] as num).toInt(),
      availableBoxCount: (json['availableBoxCount'] as num).toInt(),
      isAvailableNow: json['isAvailableNow'] as bool,
      fitsGroupSize: json['fitsGroupSize'] as bool?,
      status: json['status'] as String,
      categories: (json['categories'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(GameCategoryModel.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Chuyển sang [BoardGameEntity] — dùng cho [LobbyGamePickerSheet]
  /// và các nơi cần danh sách game dạng `BoardGameEntity`.
  BoardGameEntity toEntity() {
    return BoardGameEntity(
      id: gameTemplateId,
      name: gameName,
      description: description ?? '',
      imageUrl: thumbnailUrl ?? '',
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      estimatedMinutes: playTime,
      category: categories.isNotEmpty ? categories.first.name : '',
      components: const [],
      mechanics: const [],
      // Cafe active-games endpoint không trả rating/componentCount — dùng mặc định.
      rating: 0.0,
      componentCount: 0,
      categories: categories.map((c) => c.toEntity()).toList(),
    );
  }
}
