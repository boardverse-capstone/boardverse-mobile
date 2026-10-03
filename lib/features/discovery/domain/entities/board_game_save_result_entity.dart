import 'package:equatable/equatable.dart';

/// Kết quả toggle save/unsave — trả về từ POST /saved/{id}.
class BoardGameSaveResultEntity extends Equatable {
  final String gameTemplateId;
  final String gameName;

  /// Trạng thái sau thao tác: true = đã lưu, false = đã bỏ lưu.
  final bool isSaved;

  /// Thời điểm lưu (chỉ có khi isSaved = true).
  final DateTime? savedAt;

  /// Message từ backend (format 2 envelope: {statusCode, message, data}).
  /// Dùng để hiển thị toast cho user sau khi save/unsave.
  final String? message;

  const BoardGameSaveResultEntity({
    required this.gameTemplateId,
    required this.gameName,
    required this.isSaved,
    this.savedAt,
    this.message,
  });

  @override
  List<Object?> get props => [gameTemplateId, gameName, isSaved, savedAt, message];
}
