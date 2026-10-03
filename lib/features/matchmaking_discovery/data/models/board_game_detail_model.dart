import '../../domain/entities/board_game_detail_entity.dart';
import 'game_category_model.dart';
import 'game_component_model.dart';

class BoardGameDetailModel {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final int minPlayers;
  final int maxPlayers;
  final int playTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<GameCategoryModel> categories;
  final List<GameComponentModel> components;

  /// Game có nằm trong danh sách yêu thích của user hay không.
  /// Lấy từ field `isSaved` trong response `GET /api/v1/board-games/{id}`
  /// (build 2026-10-03+). Mặc định `false` khi:
  /// - User chưa đăng nhập (endpoint vẫn trả 200, field = false).
  /// - Backend cũ chưa hỗ trợ field này.
  ///
  /// **Source of truth ưu tiên**:
  /// - 1. `BoardGameDetail.isSaved` (endpoint `/board-games/{id}`) — luôn
  ///   fetch mỗi lần mở trang chi tiết, không cache → đảm bảo freshness
  ///   ngay cả khi user vừa save/unsave ở tab khác.
  /// - 2. `ActiveCafesSearchResult.isSaved` (endpoint `.../active-cafes`)
  ///   — fallback. Cached 30s nên có thể stale, chỉ dùng khi detail
  ///   thiếu field (backward compat).
  final bool isSaved;

  const BoardGameDetailModel({
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
    this.isSaved = false,
  });

  factory BoardGameDetailModel.fromJson(Map<String, dynamic> json) {
    return BoardGameDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      minPlayers: (json['minPlayers'] as num).toInt(),
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      playTime: ((json['playTime'] as num?) ?? 0).toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      categories: (json['categories'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(GameCategoryModel.fromJson)
              .toList() ??
          const <GameCategoryModel>[],
      components: (json['components'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(GameComponentModel.fromJson)
              .toList() ??
          const <GameComponentModel>[],
      // Build 2026-10-03+ thêm `isSaved` top-level. Default `false` khi
      // user chưa login hoặc backend cũ chưa hỗ trợ.
      isSaved: (json['isSaved'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'playTime': playTime,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'components': components.map((c) => c.toJson()).toList(),
      'isSaved': isSaved,
    };
  }

  BoardGameDetailEntity toEntity() => BoardGameDetailEntity(
        id: id,
        name: name,
        description: description,
        thumbnailUrl: thumbnailUrl,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        playTime: playTime,
        createdAt: createdAt,
        updatedAt: updatedAt,
        categories: categories.map((c) => c.toEntity()).toList(),
        components: components.map((c) => c.toEntity()).toList(),
        isSaved: isSaved,
      );
}
