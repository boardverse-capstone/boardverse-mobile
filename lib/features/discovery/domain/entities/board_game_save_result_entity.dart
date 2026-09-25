import 'package:equatable/equatable.dart';

/// Kết quả toggle save/unsave — trả về từ POST /saved/{id}.
class BoardGameSaveResultEntity extends Equatable {
  final String gameTemplateId;
  final String gameName;

  /// Trạng thái sau thao tác: true = đã lưu, false = đã bỏ lưu.
  final bool isSaved;

  /// Thời điểm lưu (chỉ có khi isSaved = true).
  final DateTime? savedAt;

  const BoardGameSaveResultEntity({
    required this.gameTemplateId,
    required this.gameName,
    required this.isSaved,
    this.savedAt,
  });

  @override
  List<Object?> get props => [gameTemplateId, gameName, isSaved, savedAt];
}
