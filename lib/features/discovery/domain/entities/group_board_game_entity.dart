import 'package:equatable/equatable.dart';

import 'sub_group_score_entity.dart';

/// Entity đại diện cho một board game được gợi ý trong Group Discovery.
class GroupBoardGameEntity extends Equatable {
  final String id;
  final String name;

  /// URL ảnh đại diện.
  final String? imageUrl;

  /// Mô tả ngắn.
  final String? description;

  final int minPlayers;
  final int maxPlayers;

  /// Thời gian chơi trung bình (phút).
  final int playTimeMinutes;

  /// BGG weight (độ phức tạp).
  final double? weight;

  /// Danh sách thể loại.
  final List<String> categories;

  /// Điểm số tổng hợp của game (trung bình có trọng số các sub-groups).
  final double aggregateScore;

  /// Chi tiết điểm số theo từng sub-group.
  final List<SubGroupScoreEntity> subGroupScores;

  const GroupBoardGameEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    this.weight,
    required this.categories,
    required this.aggregateScore,
    required this.subGroupScores,
  });

  String get playerRangeDisplay =>
      minPlayers == maxPlayers ? '$minPlayers người' : '$minPlayers-$maxPlayers người';

  @override
  List<Object?> get props => [
        id, name, imageUrl, description,
        minPlayers, maxPlayers, playTimeMinutes,
        weight, categories, aggregateScore, subGroupScores,
      ];
}
