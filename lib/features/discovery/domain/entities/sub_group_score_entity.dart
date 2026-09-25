import 'package:equatable/equatable.dart';

/// Điểm số của một sub-group trong Group Discovery.
///
/// Mỗi sub-group (thành viên trong nhóm) có score riêng cho game được gợi ý.
class SubGroupScoreEntity extends Equatable {
  /// Chỉ số sub-group (0, 1, 2, ...) — tương ứng với thứ tự trong request.
  final int subGroupIndex;

  /// Số người trong sub-group.
  final int playerCount;

  /// Trình độ người chơi (1-5).
  final int? experienceLevel;

  /// Điểm match của sub-group (0-100).
  final double score;

  /// Lý do gợi ý cho sub-group này.
  final String? reason;

  const SubGroupScoreEntity({
    required this.subGroupIndex,
    required this.playerCount,
    this.experienceLevel,
    required this.score,
    this.reason,
  });

  @override
  List<Object?> get props => [
        subGroupIndex, playerCount, experienceLevel, score, reason,
      ];
}
