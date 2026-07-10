import 'package:equatable/equatable.dart';

/// Entity mô tả danh mục/thể loại board game
class GameCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String iconName;
  final int gameCount;
  final String? description;

  const GameCategoryEntity({
    required this.id,
    required this.name,
    required this.iconName,
    required this.gameCount,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, iconName, gameCount, description];
}
