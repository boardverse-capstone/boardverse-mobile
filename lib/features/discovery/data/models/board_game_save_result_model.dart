import 'package:equatable/equatable.dart';

/// Model cho kết quả toggle save.
///
/// Trả về từ POST /api/v1/discovery/saved/{gameTemplateId}.
/// Trường `isSaved` phản ánh trạng thái mới sau khi toggle.
class BoardGameSaveResultModel extends Equatable {
  final String gameTemplateId;
  final String gameName;
  final bool isSaved;
  final DateTime? savedAt;

  /// Message từ backend (format 2 envelope: {statusCode, message, data}).
  /// Ví dụ: "Đã lưu board game." hoặc "Đá bỏ lưu board game."
  final String? message;

  const BoardGameSaveResultModel({
    required this.gameTemplateId,
    required this.gameName,
    required this.isSaved,
    this.savedAt,
    this.message,
  });

  /// Factory tạo model từ `data` field (caller truyền message riêng).
  ///
  /// **Defensive**: BE đôi khi không trả `gameName` (chỉ trả
  /// `gameTemplateId` + `isSaved` + `savedAt`) — fallback về empty
  /// string thay vì throw `TypeError: Null is not subtype of String`
  /// trên web (DDC).
  factory BoardGameSaveResultModel.fromJson(Map<String, dynamic> json) {
    return BoardGameSaveResultModel(
      gameTemplateId: json['gameTemplateId'] as String,
      gameName: json['gameName'] as String? ?? '',
      isSaved: json['isSaved'] as bool,
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
    );
  }

  /// Factory tạo model từ envelope format 2 — tự trích `message` từ envelope.
  factory BoardGameSaveResultModel.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] as Map<String, dynamic>;
    return BoardGameSaveResultModel(
      gameTemplateId: data['gameTemplateId'] as String,
      gameName: data['gameName'] as String? ?? '',
      isSaved: data['isSaved'] as bool,
      savedAt: data['savedAt'] != null
          ? DateTime.tryParse(data['savedAt'] as String)
          : null,
      message: envelope['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [gameTemplateId, gameName, isSaved, savedAt, message];

  /// Tạo bản sao với một số field override (dùng trong datasource để gắn
  /// `message` lấy từ envelope format 2).
  BoardGameSaveResultModel copyWith({
    String? gameTemplateId,
    String? gameName,
    bool? isSaved,
    DateTime? savedAt,
    String? message,
  }) {
    return BoardGameSaveResultModel(
      gameTemplateId: gameTemplateId ?? this.gameTemplateId,
      gameName: gameName ?? this.gameName,
      isSaved: isSaved ?? this.isSaved,
      savedAt: savedAt ?? this.savedAt,
      message: message ?? this.message,
    );
  }
}
