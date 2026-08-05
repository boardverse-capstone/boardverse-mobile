import 'package:flutter/material.dart';

import '../../domain/entities/game_category_entity.dart';

/// Map [GameCategoryEntity] (lấy từ `GET /api/v1/board-games/categories`) sang
/// [IconData] phù hợp để hiển thị UI.
///
/// Backend **không trả về** icon name — chỉ trả `id`, `name`, `slug`,
/// `description`, `sortOrder`. Vì vậy frontend đăng ký một map slug → icon
/// làm "translation layer" duy nhất, dùng chung cho mọi widget render
/// category chips (QuickFilterRow, FilterBottomSheet.CategoryGrid, v.v.).
///
/// Khi backend thêm thể loại mới, chỉ cần bổ sung 1 dòng vào [slugToIcon]
/// — không phải sửa từng widget riêng lẻ.
///
/// Slug anchor theo seed trong `.agents/docs/apis_docs/board-games.md`:
///   an-vai, chien-thuat, giai-tri, hop-tac, doi-khang, phieu-luu.
class CategoryIconMapper {
  CategoryIconMapper._();

  /// Slug (`CategoryDto.slug`) → [IconData] Material.
  /// Key viết thường, không dấu theo chuẩn backend.
  static const Map<String, IconData> slugToIcon = <String, IconData>{
    'an-vai': Icons.search,
    'chien-thuat': Icons.psychology,
    'giai-tri': Icons.celebration,
    'hop-tac': Icons.handshake,
    'doi-khang': Icons.military_tech,
    'phieu-luu': Icons.explore_outlined,
    'the-bai': Icons.style,
    'truu-tuong': Icons.grid_view,
    'gia-dinh': Icons.family_restroom,
    'chien': Icons.military_tech,
    'party': Icons.celebration,
    'strategy': Icons.psychology,
    'cooperative': Icons.handshake,
    'social-deduction': Icons.search,
    'card-game': Icons.style,
    'abstract': Icons.grid_view,
    'war': Icons.military_tech,
    'family': Icons.family_restroom,
  };

  /// Fallback icon khi category không có slug khớp.
  static const IconData fallbackIcon = Icons.category_outlined;

  /// Trả icon cho 1 category dựa trên `slug` (ưu tiên) → `name` (fallback).
  ///
  /// Match theo slug anchor trước (ổn định, không phụ thuộc ngôn ngữ
  /// hiển thị). Nếu slug null hoặc không tìm thấy, thử match theo name
  /// lowercase (giúp tương thích khi backend chưa có slug, vd: mock data).
  static IconData iconFor(GameCategoryEntity category) {
    final slug = category.slug?.toLowerCase().trim();
    if (slug != null && slug.isNotEmpty) {
      // Exact match trước, sau đó partial (slug prefix/suffix).
      if (slugToIcon.containsKey(slug)) {
        return slugToIcon[slug]!;
      }
      for (final entry in slugToIcon.entries) {
        if (slug.contains(entry.key) || entry.key.contains(slug)) {
          return entry.value;
        }
      }
    }

    final name = category.name.toLowerCase().trim();
    for (final entry in slugToIcon.entries) {
      if (name.contains(entry.key.replaceAll('-', ' ')) ||
          entry.key.replaceAll('-', ' ').contains(name)) {
        return entry.value;
      }
    }
    return fallbackIcon;
  }
}
