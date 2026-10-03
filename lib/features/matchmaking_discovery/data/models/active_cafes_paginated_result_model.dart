import '../../domain/entities/board_game_active_cafe_entity.dart';
import 'board_game_active_cafe_model.dart';

/// Model wrapper cho response phân trang của
/// `GET /api/v1/board-games/{boardgameId}/active-cafes`.
///
/// **Backend response shape (build 2026-10-03)**: `{ isSaved, cafes: { data, meta } }`
/// - `isSaved` ở top-level — báo hiệu game hiện tại có nằm trong danh sách
///   yêu thích của user hay không. UI dùng để hiển thị icon save/unsave
///   trên header trang chi tiết board game.
/// - `cafes` được wrap trong 1 object `{ data: [...], meta: {...} }`
///   (thay vì để flat ở top-level như trước) — phải drill xuống 1 cấp.
///
/// **Backward-compat**: vẫn hỗ trợ các shape cũ:
/// 1. `{ data: [...], meta: {...} }`
/// 2. `{ items: [...], page: N, pageSize: N, totalItems: N, ... }`
/// 3. Trực tiếp array (single-page edge case).
class ActiveCafesPaginatedResultModel {
  final List<BoardGameActiveCafeModel> cafes;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  /// Game hiện tại có nằm trong danh sách yêu thích của user hay không.
  /// Mặc định `false` (chưa lưu) nếu backend không trả field này (vd:
  /// endpoint public / user chưa đăng nhập).
  ///
  /// Tên field BE: `isSaved` (top-level). Xem
  /// `.agents/docs/apis_docs/board-games.md` §GET /api/v1/board-games/{id}/active-cafes
  /// (build 2026-10-03 thêm field này).
  final bool isSaved;

  const ActiveCafesPaginatedResultModel({
    required this.cafes,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.isSaved = false,
  });

  /// Parse response dạng `PaginatedResponse<BoardGameActiveCafeDto>`
  /// (đã strip `statusCode`/`message` envelope ở layer ngoài).
  ///
  /// Chấp nhận cả 4 format envelope phổ biến:
  /// 0. `{ isSaved, cafes: { data: [...], meta: {...} } }` — build mới
  /// 1. `{ data: [...], meta: {...} }`
  /// 2. `{ items: [...], page: N, pageSize: N, totalItems: N, ... }`
  /// 3. Trực tiếp array (single-page edge case).
  ///
  /// Thứ tự check quan trọng: format 0 PHẢI đứng trước format 1 vì
  /// `json['data']` ở format 0 trỏ vào `cafes.data` (object) chứ không
  /// phải list → nếu check format 1 trước sẽ fail `data is List`.
  factory ActiveCafesPaginatedResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final itemsRaw = _extractItems(json);
    final cafes = itemsRaw
        .cast<Map<String, dynamic>>()
        .map(BoardGameActiveCafeModel.fromJson)
        .toList();

    // Meta object (format 1) hoặc flat fields (format 2).
    final meta = json['meta'] as Map<String, dynamic>?;
    final page = (meta?['currentPage'] as int?) ??
        (json['page'] as int?) ??
        1;
    final pageSize = (meta?['pageSize'] as int?) ??
        (json['pageSize'] as int?) ??
        20;
    final totalItems = (meta?['totalItems'] as int?) ??
        (json['totalItems'] as int?) ??
        (json['totalCount'] as int?) ??
        cafes.length;
    final totalPages = (meta?['totalPages'] as int?) ??
        (json['totalPages'] as int?) ??
        (pageSize > 0 ? (totalItems / pageSize).ceil() : 0);
    final hasNext = (meta?['hasNext'] as bool?) ??
        (json['hasNextPage'] as bool?) ??
        (page < totalPages);
    final hasPrevious = (meta?['hasPrevious'] as bool?) ??
        (json['hasPreviousPage'] as bool?) ??
        (page > 1);

    // `isSaved` ở top-level (build 2026-10-03+). Default `false` khi:
    // - Backend không trả (endpoint public / user chưa login)
    // - Field null (tránh NPE trên web DDC)
    final isSaved = (json['isSaved'] as bool?) ?? false;

    return ActiveCafesPaginatedResultModel(
      cafes: cafes,
      page: page,
      pageSize: pageSize,
      totalCount: totalItems,
      totalPages: totalPages,
      hasNextPage: hasNext,
      hasPreviousPage: hasPrevious,
      isSaved: isSaved,
    );
  }

  static List<dynamic> _extractItems(Map<String, dynamic> json) {
    // Format 0 (build 2026-10-03): { isSaved, cafes: { data: [...], meta: {...} } }
    // Phải check TRƯỚC format 1 vì `cafes.data` không phải list ở top-level.
    final cafesWrapper = json['cafes'];
    if (cafesWrapper is Map<String, dynamic>) {
      final data = cafesWrapper['data'];
      if (data is List) return data;
      final items = cafesWrapper['items'];
      if (items is List) return items;
    }
    // Format 1: { data: [...], meta: {...} }
    final data = json['data'];
    if (data is List) return data;
    // Format 2: { items: [...] }
    final items = json['items'];
    if (items is List) return items;
    // Backend trả về trực tiếp array (single-page edge case).
    if (json.values.first is List) {
      return json.values.first as List;
    }
    return const [];
  }

  /// Chuyển sang domain [ActiveCafesSearchResultEntity] cho cubit/UI.
  ActiveCafesSearchResultEntity toEntity() {
    return ActiveCafesSearchResultEntity(
      cafes: cafes.map((m) => m.toEntity()).toList(),
      emptyResultMessage:
          cafes.isEmpty ? 'Chưa có quán nào có sẵn board game này.' : null,
      alternativeSuggestions: const [],
      isSaved: isSaved,
    );
  }
}