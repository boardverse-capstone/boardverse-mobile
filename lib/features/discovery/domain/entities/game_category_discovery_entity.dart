import 'package:equatable/equatable.dart';

/// Entity cho thể loại board game trong discovery filter.
class GameCategoryDiscoveryEntity extends Equatable {
  final String id;
  final String name;

  /// Slug dùng cho URL/routing.
  final String slug;

  /// Thứ tự sắp xếp.
  final int sortOrder;

  const GameCategoryDiscoveryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, slug, sortOrder];
}
