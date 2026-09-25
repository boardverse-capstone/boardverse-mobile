import 'recommended_board_game_entity.dart';

/// Entity cho board game trong Solo Personalized Discovery.
///
/// Kế thừa từ RecommendedBoardGameEntity + thêm scoring breakdown.
class PersonalizedBoardGameEntity extends RecommendedBoardGameEntity {
  /// Base score (0-85) — điểm từ filter match cơ bản.
  final double baseScore;

  /// Personalization boost (0-15) — điểm cộng từ saved games affinity.
  final double personalizationBoost;

  /// Play history penalty (0 to -20) — điểm trừ từ lịch sử chơi gần đây.
  final double playHistoryPenalty;

  /// Điểm cuối cùng = min(baseScore + boost + penalty, 100).
  final double personalizedScore;

  /// Lý do cá nhân hóa (ví dụ: "Khớp với thể loại bạn thường chơi").
  final String? matchReason;

  /// Game có đang được lưu không.
  final bool isSaved;

  /// Có lobby đang mở cho game này không.
  final bool hasOpenLobby;

  /// Lobby ID để tham gia (nếu hasOpenLobby = true).
  final String? openLobbyId;

  const PersonalizedBoardGameEntity({
    required super.id,
    required super.name,
    super.imageUrl,
    super.weight,
    required super.minPlayers,
    required super.maxPlayers,
    required super.playTimeMinutes,
    required super.categories,
    required super.score,
    required super.matchReasons,
    required this.baseScore,
    required this.personalizationBoost,
    required this.playHistoryPenalty,
    required this.personalizedScore,
    this.matchReason,
    required this.isSaved,
    required this.hasOpenLobby,
    this.openLobbyId,
  });

  /// Cấp độ play history penalty để hiển thị badge.
  PlayHistoryLevel get playHistoryLevel {
    if (playHistoryPenalty == 0) return PlayHistoryLevel.none;
    if (playHistoryPenalty == -5) return PlayHistoryLevel.light;
    if (playHistoryPenalty <= -15) return PlayHistoryLevel.heavy;
    return PlayHistoryLevel.medium;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        baseScore, personalizationBoost, playHistoryPenalty,
        personalizedScore, matchReason, isSaved,
        hasOpenLobby, openLobbyId,
      ];
}

enum PlayHistoryLevel {
  none,
  light,    // -5: đã thử
  medium,   // -10, -15: chơi nhiều
  heavy,    // -20: chơi rất nhiều
}
