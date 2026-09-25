import 'package:equatable/equatable.dart';

/// User preference profile được extract từ ≥3 saved games của user.
///
/// Trả về null nếu user có <3 saved games.
class UserGamePreferenceEntity extends Equatable {
  final String userId;

  /// Top 3 category IDs thường được lưu.
  final List<String> topCategoryIds;

  /// Trọng số BGG weight trung bình (từ games đã lưu).
  final double averageWeight;

  /// Thời gian chơi trung bình (phút).
  final double averageDuration;

  /// Số saved games dùng để phân tích.
  final int savedGameCount;

  const UserGamePreferenceEntity({
    required this.userId,
    required this.topCategoryIds,
    required this.averageWeight,
    required this.averageDuration,
    required this.savedGameCount,
  });

  @override
  List<Object?> get props => [
        userId, topCategoryIds, averageWeight, averageDuration, savedGameCount,
      ];
}
