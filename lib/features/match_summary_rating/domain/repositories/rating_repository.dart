import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  /// Lấy ngữ cảnh đánh giá chéo Karma cho 1 lobby.
  ///
  /// Maps to `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}`.
  /// Trả về danh sách thành viên (trừ bản thân), các tag khả dụng
  /// (`OnTime`, `Civil`, `Friendly`, `Toxic`, `NoShow`) và cờ
  /// `canSubmitRatings` để UI enable/disable nút Submit.
  ///
  /// Lỗi:
  /// - 403: không phải thành viên active của lobby.
  /// - 404: lobby không tồn tại.
  /// - 500: lỗi hệ thống.
  Future<Either<Failure, KarmaRatingContextEntity>> getKarmaRatingContext(
    String lobbyId,
  );

  /// Submit đánh giá chéo Karma cho các thành viên trong lobby.
  ///
  /// Maps to `POST /api/v1/users/ratings/karma`. Mỗi target trong
  /// [entries] phải có ≥1 tag; ratings rỗng sẽ bị server reject (400).
  ///
  /// Ràng buộc:
  /// - Phòng phải ở trạng thái `RatingOpen` hoặc `Closed` (400 nếu không).
  /// - Không được tự đánh giá bản thân (400).
  /// - Mỗi cặp (rater, target, lobby) chỉ submit một lần (409 nếu trùng).
  ///
  /// Thành công trả về danh sách [AppliedKarmaRatingEntity] kèm
  /// karma delta + tier mới của từng target.
  Future<Either<Failure, SubmitKarmaRatingsResultEntity>> submitKarmaRatings({
    required String lobbyId,
    required List<KarmaRatingEntry> entries,
  });

  // ─── Legacy: ELO + Match Result (mock UI flow cũ) ─────────────────
  // Giữ cho code cũ không bị break. Đã được thay thế bởi
  // `/api/v1/matches/results` (xem `lib/features/tournament/...`).
  @Deprecated('Use getKarmaRatingContext for karma flow.')
  Future<Either<Failure, void>> submitKarmaRating(
    String sessionId,
    Map<String, List<String>> playerRatings,
  );

  @Deprecated('Use /api/v1/matches/results (handled by tournament feature).')
  Future<Either<Failure, EloResult>> submitMatchResult(
    String sessionId,
    MatchResult result,
  );

  @Deprecated('Use getKarmaRatingContext.availableTags instead.')
  Future<Either<Failure, List<KarmaTag>>> getAvailableKarmaTags();
}
