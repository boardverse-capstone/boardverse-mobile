import 'package:equatable/equatable.dart';

/// Entity mô tả danh mục/thể loại board game.
class GameCategoryEntity extends Equatable {
  final String id;
  final String name;

  /// Tên icon (Material Icons) — dùng cho UI cũ (chips/filter).
  /// Không có trong response backend mới, mock giữ nguyên.
  final String iconName;

  /// Số game thuộc category — mock sử dụng; backend trả về.
  final int gameCount;
  final String? description;

  /// Slug định danh — thêm từ backend (vd: "an-vai").
  final String? slug;

  /// Thứ tự sắp xếp — thêm từ backend.
  final int? sortOrder;

  const GameCategoryEntity({
    required this.id,
    required this.name,
    this.iconName = 'games',
    this.gameCount = 0,
    this.description,
    this.slug,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        iconName,
        gameCount,
        description,
        slug,
        sortOrder,
      ];
}
