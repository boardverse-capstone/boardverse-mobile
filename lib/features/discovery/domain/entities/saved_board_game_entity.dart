import 'package:equatable/equatable.dart';

/// Entity cho một board game trong danh sách "Đã lưu".
class SavedBoardGameEntity extends Equatable {
  final String id;

  /// GameTemplateId — dùng để toggle/unsave.
  final String gameTemplateId;

  final String gameName;

  /// URL ảnh đại diện.
  final String? thumbnailUrl;

  /// Danh sách thể loại (string).
  final List<String> categories;

  /// BGG weight (độ phức tạp).
  final double? weight;

  /// Thời gian chơi (phút).
  final int? playTime;

  /// Thời điểm user lưu game.
  final DateTime savedAt;

  const SavedBoardGameEntity({
    required this.id,
    required this.gameTemplateId,
    required this.gameName,
    this.thumbnailUrl,
    required this.categories,
    this.weight,
    this.playTime,
    required this.savedAt,
  });

  @override
  List<Object?> get props => [
        id, gameTemplateId, gameName, thumbnailUrl,
        categories, weight, playTime, savedAt,
      ];
}
