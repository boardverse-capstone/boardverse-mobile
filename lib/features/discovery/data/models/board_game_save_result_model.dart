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

  const BoardGameSaveResultModel({
    required this.gameTemplateId,
    required this.gameName,
    required this.isSaved,
    this.savedAt,
  });

  factory BoardGameSaveResultModel.fromJson(Map<String, dynamic> json) {
    return BoardGameSaveResultModel(
      gameTemplateId: json['gameTemplateId'] as String,
      gameName: json['gameName'] as String,
      isSaved: json['isSaved'] as bool,
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [gameTemplateId, gameName, isSaved, savedAt];
}
