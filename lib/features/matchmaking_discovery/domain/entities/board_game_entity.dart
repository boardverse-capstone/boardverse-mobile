import 'package:equatable/equatable.dart';

import 'game_category_entity.dart';

class BoardGameEntity extends Equatable {
  final String id;
  final String name;
  final String description;

  /// URL ảnh đại diện — map từ backend `thumbnailUrl`. Đặt tên `imageUrl`
  /// để giữ tương thích ngược với UI cũ (`BoardGameCard`, `GameDetailHeader`).
  final String imageUrl;

  final int minPlayers;
  final int maxPlayers;

  /// Thời gian chơi trung bình (phút) — map từ backend `playTime`.
  /// Tên field giữ `estimatedMinutes` để UI cũ vẫn đọc được.
  final int estimatedMinutes;

  /// Tên thể loại chính (string). Derive từ `categories.first.name` khi
  /// response backend chỉ trả mảng `categories[]`.
  final String category;

  /// Tóm tắt các linh kiện (chuỗi hiển thị) — dùng cho danh sách dạng
  /// text-only ở card/detail. Dữ liệu đầy đủ xem `BoardGameDetailEntity`.
  final List<String> components;
  final List<String> mechanics;
  final double rating;

  /// Số lượng linh kiện — map từ backend `componentCount` (danh sách).
  final int componentCount;

  /// Danh sách thể loại đầy đủ từ backend — dùng cho multi-filter
  /// `category_ids`. Có thể rỗng nếu game catalog chưa gắn category.
  final List<GameCategoryEntity> categories;

  const BoardGameEntity({
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
    this.componentCount = 0,
    this.categories = const [],
  });

  /// Định dạng hiển thị số người chơi:
  /// - Khi minPlayers == maxPlayers → "X người"
  /// - Khi minPlayers != maxPlayers → "X-Y người"
  ///
  /// Tránh UI hiển thị "2-2 người" khó hiểu khi chỉ có 1 giá trị.
  String get playerRangeDisplay =>
      minPlayers == maxPlayers ? '$minPlayers người' : '$minPlayers-$maxPlayers người';

  /// Phiên bản không có đuôi " người" — dùng cho pill nhỏ (icon + text).
  String get playerRangeRaw =>
      minPlayers == maxPlayers ? '$minPlayers' : '$minPlayers-$maxPlayers';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        minPlayers,
        maxPlayers,
        estimatedMinutes,
        category,
        components,
        mechanics,
        rating,
        componentCount,
        categories,
      ];
}
