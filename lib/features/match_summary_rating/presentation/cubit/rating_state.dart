import 'package:equatable/equatable.dart';
import '../../domain/entities/rating_entity.dart';

sealed class RatingState extends Equatable {
  const RatingState();

  @override
  List<Object?> get props => [];
}

class RatingInitial extends RatingState {
  const RatingInitial();
}

class RatingLoading extends RatingState {
  const RatingLoading();
}

/// State hiển thị form đánh giá Karma — bind tới response của
/// `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}`.
///
/// UI dùng:
/// - `playersToRate` để render [PlayerRatingCard] cho mỗi member.
/// - `availableTags` để render chip list tag (OnTime / Civil / ...).
/// - `canSubmitRatings` để enable/disable Submit button.
/// - `pendingMemberCount` + `allRated` để hiển thị counter / disabled state.
class KarmaRating extends RatingState {
  final List<RatingPlayer> playersToRate;
  final List<KarmaTag> availableTags;

  /// `true` khi lobby ở `RatingOpen` hoặc `Closed`.
  final bool canSubmitRatings;

  /// Lobby status raw từ backend — UI dùng để show banner phù hợp
  /// (vd: "Đang chờ mở đánh giá").
  final String lobbyStatus;

  /// Số member chưa được user này đánh giá.
  final int pendingMemberCount;

  /// `true` khi toàn bộ member đã `alreadyRated` — UI có thể auto-pop
  /// hoặc hiển thị "Đã hoàn tất".
  final bool allRated;

  const KarmaRating({
    required this.playersToRate,
    required this.availableTags,
    required this.canSubmitRatings,
    required this.lobbyStatus,
    required this.pendingMemberCount,
    required this.allRated,
  });

  @override
  List<Object?> get props => [
    playersToRate,
    availableTags,
    canSubmitRatings,
    lobbyStatus,
    pendingMemberCount,
    allRated,
  ];
}

/// State hiển thị kết quả sau khi submit thành công — bind tới response
/// của `POST /api/v1/users/ratings/karma` (AC 3.3).
///
/// UI dùng [result] để:
/// - Hiển thị danh sách target + karma delta + tier mới (Gold/Silver/...).
/// - Tổng kết "Bạn vừa cộng/trừ X Karma cho Y thành viên".
///
/// Nếu `partial=true` (vd: 409 conflict) thì hiển thị `message` nhẹ nhàng
/// và đóng page sau 2-3 giây.
class KarmaRatingSubmitted extends RatingState {
  final SubmitKarmaRatingsResultEntity result;

  /// `true` khi submit 1 phần thành công (vd: 1 vài target bị 409).
  final bool partial;
  final String? message;

  const KarmaRatingSubmitted({
    required this.result,
    required this.partial,
    required this.message,
  });

  @override
  List<Object?> get props => [result, partial, message];
}

/// Legacy — ELO/MatchResult entry (giữ cho code cũ).
class MatchResultEntry extends RatingState {
  final bool isWaitingConsensus;

  const MatchResultEntry({this.isWaitingConsensus = false});

  @override
  List<Object?> get props => [isWaitingConsensus];
}

/// Legacy — ELO display.
class EloResultDisplay extends RatingState {
  final EloResult eloResult;

  const EloResultDisplay({required this.eloResult});

  @override
  List<Object?> get props => [eloResult];
}

/// Legacy — flow hoàn tất (không dùng cho karma mới — dùng
/// [KarmaRatingSubmitted] thay thế).
class RatingComplete extends RatingState {
  const RatingComplete();
}

/// Error state — kèm statusCode để caller switch logic (vd: 409 → retry).
class RatingFailure extends RatingState {
  final String message;
  final int? statusCode;

  const RatingFailure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}
