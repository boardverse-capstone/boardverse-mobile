import '../models/rating_model.dart';

/// Mock data source for match summary rating feature.
/// Provides realistic sample data for UI development and testing.
class MockRatingDatasource {
  // ─── Karma Rating Tags ─────────────────────────────────────────────────

  /// Danh sách thẻ tiêu chí thái độ tích cực/tiêu cực
  static List<KarmaTagModel> get mockKarmaRatingTags => const [
        KarmaTagModel(
          id: 'tag_001',
          name: 'Đúng giờ',
          icon: 'check_circle',
          isPositive: true,
        ),
        KarmaTagModel(
          id: 'tag_002',
          name: 'Văn minh',
          icon: 'thumb_up',
          isPositive: true,
        ),
        KarmaTagModel(
          id: 'tag_003',
          name: 'Thân thiện',
          icon: 'emoji_emotions',
          isPositive: true,
        ),
        KarmaTagModel(
          id: 'tag_004',
          name: 'Chơi hay',
          icon: 'stars',
          isPositive: true,
        ),
        KarmaTagModel(
          id: 'tag_005',
          name: 'Toxic',
          icon: 'mood_bad',
          isPositive: false,
        ),
        KarmaTagModel(
          id: 'tag_006',
          name: 'No-show',
          icon: 'event_busy',
          isPositive: false,
        ),
        KarmaTagModel(
          id: 'tag_007',
          name: 'Trễ giờ',
          icon: 'schedule',
          isPositive: false,
        ),
        KarmaTagModel(
          id: 'tag_008',
          name: 'Gian lận',
          icon: 'gavel',
          isPositive: false,
        ),
      ];

  // ─── Elo Result Payload ───────────────────────────────────────────────

  /// Trạng thái kết quả đối kháng với biến động điểm số
  static EloResultModel get mockEloResultWin => const EloResultModel(
        sessionId: 'session_001',
        result: MatchResultModel.win,
        eloChange: 15,
        currentElo: 1250,
        newElo: 1265,
      );

  static EloResultModel get mockEloResultLose => const EloResultModel(
        sessionId: 'session_001',
        result: MatchResultModel.lose,
        eloChange: -12,
        currentElo: 1250,
        newElo: 1238,
      );

  static EloResultModel get mockEloResultDraw => const EloResultModel(
        sessionId: 'session_001',
        result: MatchResultModel.draw,
        eloChange: 0,
        currentElo: 1250,
        newElo: 1250,
      );

  // ─── Players to Rate ────────────────────────────────────────────────

  /// Danh sách người chơi cần đánh giá
  static List<RatingPlayerModel> get mockPlayersToRate => const [
        RatingPlayerModel(
          id: 'user_002',
          name: 'Thu Hà',
          avatarUrl: 'https://i.pravatar.cc/150?u=thuha',
        ),
        RatingPlayerModel(
          id: 'user_003',
          name: 'Anh Khoa',
          avatarUrl: 'https://i.pravatar.cc/150?u=anhkhoa',
        ),
        RatingPlayerModel(
          id: 'user_004',
          name: 'Lan Chi',
          avatarUrl: 'https://i.pravatar.cc/150?u=lanchi',
        ),
        RatingPlayerModel(
          id: 'user_005',
          name: 'Hoàng Nam',
          avatarUrl: 'https://i.pravatar.cc/150?u=hoangnam',
        ),
      ];
}
