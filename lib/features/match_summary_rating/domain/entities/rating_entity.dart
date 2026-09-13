import 'package:equatable/equatable.dart';

/// Karma tags được phép đánh giá — liệt kê theo spec
/// `.agents/docs/apis_docs/user-ratings.md` §POST /karma + BR §3.3.
///
/// Mỗi tag có trọng số `karmaWeight` cộng dồn khi áp dụng vào
/// `UserProfiles.KarmaPoints` (OnTime + Friendly = +0.2, làm tròn khi
/// ghi vào profile).
enum KarmaRatingTag {
  onTime('OnTime', 'Đúng giờ', 0.1),
  civil('Civil', 'Văn minh', 0.1),
  friendly('Friendly', 'Thân thiện', 0.1),
  toxic('Toxic', 'Toxic', -1.0),
  noShow('NoShow', 'Vắng mặt', -1.0);

  const KarmaRatingTag(this.apiValue, this.label, this.weight);

  /// Giá trị backend mong đợi (PascalCase).
  final String apiValue;

  /// Tên hiển thị tiếng Việt trên UI.
  final String label;

  /// Trọng số Karma (+/-).
  final double weight;

  /// `true` khi tag tăng điểm Karma (OnTime / Civil / Friendly).
  bool get isPositive => weight > 0;

  /// `true` khi tag trừ điểm Karma (Toxic / NoShow).
  bool get isNegative => weight < 0;

  /// Parse từ string backend trả về. Trả `null` nếu không nhận diện —
  /// caller quyết định fallback (vd: hiển thị raw value).
  static KarmaRatingTag? fromApiValue(String? value) {
    if (value == null) return null;
    for (final tag in KarmaRatingTag.values) {
      if (tag.apiValue == value) return tag;
    }
    return null;
  }
}

/// Karma tag đại diện cho 1 tiêu chí đánh giá trong response
/// `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}` §availableTags.
class KarmaTag extends Equatable {
  /// PascalCase enum string (vd: "OnTime") — match với
  /// [KarmaRatingTag.apiValue].
  final String id;

  /// Tên hiển thị tiếng Việt (do UI map từ [KarmaRatingTag.label]).
  final String name;

  /// Icon name (legacy, dùng cho [PlayerRatingCard] widget hiện có).
  /// Không dùng khi binding từ API thật — UI map từ [KarmaRatingTag] enum.
  final String icon;

  /// `true` cho tag tăng Karma, `false` cho tag âm.
  final bool isPositive;

  /// Trạng thái được user chọn (chỉ có trên UI, không có trên API).
  final bool isSelected;

  /// Trọng số Karma từ backend (+0.1 / -1). Dùng để hiển thị tooltip.
  final double weight;

  const KarmaTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.isPositive,
    this.isSelected = false,
    this.weight = 0.1,
  });

  /// Build [KarmaTag] từ API tag trong `availableTags[]`.
  factory KarmaTag.fromApi(KarmaRatingTag tag) {
    return KarmaTag(
      id: tag.apiValue,
      name: tag.label,
      icon: _iconFor(tag),
      isPositive: tag.isPositive,
      weight: tag.weight,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    isPositive,
    isSelected,
    weight,
  ];
}

String _iconFor(KarmaRatingTag tag) {
  switch (tag) {
    case KarmaRatingTag.onTime:
      return 'check_circle';
    case KarmaRatingTag.civil:
      return 'thumb_up';
    case KarmaRatingTag.friendly:
      return 'emoji_emotions';
    case KarmaRatingTag.toxic:
      return 'mood_bad';
    case KarmaRatingTag.noShow:
      return 'event_busy';
  }
}

/// 1 thành viên cần được user hiện tại đánh giá Karma trong lobby.
///
/// Tương ứng với `membersToRate[]` trong
/// `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}`. UI sử dụng để
/// render 1 [PlayerRatingCard] cho mỗi member (trừ chính user gọi).
class MemberToRate extends Equatable {
  final String userId;
  final String username;
  final String? avatarUrl;

  /// `true` nếu người gọi đã submit đánh giá cho member này trong lobby —
  /// UI sẽ disable toàn bộ tag chips cho member này và hiển thị chip
  /// "Đã đánh giá".
  final bool alreadyRated;

  const MemberToRate({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.alreadyRated = false,
  });

  @override
  List<Object?> get props => [userId, username, avatarUrl, alreadyRated];
}

/// Context cho 1 phiên đánh giá Karma của user trong lobby.
///
/// Trả về từ `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}` (AC 3.2).
/// UI dùng `canSubmitRatings` để enable/disable nút Submit, dùng
/// `availableTags` để render chip, dùng `membersToRate` để build danh
/// sách [PlayerRatingCard].
class KarmaRatingContextEntity extends Equatable {
  final String lobbyId;

  /// Lobby status từ backend — UI dùng để hiển thị banner phù hợp
  /// (vd: "Đang chờ mở đánh giá", "Đã đóng", ...).
  final String lobbyStatus;

  /// `true` khi lobbyStatus = RatingOpen hoặc Closed.
  final bool canSubmitRatings;

  final List<KarmaTag> availableTags;
  final List<MemberToRate> membersToRate;

  const KarmaRatingContextEntity({
    required this.lobbyId,
    required this.lobbyStatus,
    required this.canSubmitRatings,
    required this.availableTags,
    required this.membersToRate,
  });

  /// Số member CHƯA đánh giá — UI dùng để show "X người còn lại".
  int get pendingMemberCount =>
      membersToRate.where((m) => !m.alreadyRated).length;

  /// `true` khi không còn ai cần đánh giá (toàn bộ đã `alreadyRated`).
  bool get allRated =>
      membersToRate.isNotEmpty && pendingMemberCount == 0;

  @override
  List<Object?> get props => [
    lobbyId,
    lobbyStatus,
    canSubmitRatings,
    availableTags,
    membersToRate,
  ];
}

/// Kết quả áp dụng Karma cho 1 target — phần tử trong
/// `appliedRatings[]` của response `POST /api/v1/users/ratings/karma`.
class AppliedKarmaRatingEntity extends Equatable {
  final String targetUserId;
  final List<String> tags;

  /// Tổng trọng số Karma đã cộng/trừ (vd: OnTime + Friendly = +0.2).
  final double karmaDeltaApplied;

  /// Điểm Karma mới của target sau khi áp dụng.
  final int targetKarmaPointsAfter;

  /// Gamer tier mới (vd: "Gold", "Silver", "Bronze").
  final String targetGamerTier;

  const AppliedKarmaRatingEntity({
    required this.targetUserId,
    required this.tags,
    required this.karmaDeltaApplied,
    required this.targetKarmaPointsAfter,
    required this.targetGamerTier,
  });

  @override
  List<Object?> get props => [
    targetUserId,
    tags,
    karmaDeltaApplied,
    targetKarmaPointsAfter,
    targetGamerTier,
  ];
}

/// Response wrapper cho `POST /api/v1/users/ratings/karma` (AC 3.3).
class SubmitKarmaRatingsResultEntity extends Equatable {
  final String lobbyId;
  final List<AppliedKarmaRatingEntity> appliedRatings;

  const SubmitKarmaRatingsResultEntity({
    required this.lobbyId,
    required this.appliedRatings,
  });

  /// Tổng delta Karma của toàn bộ target (dương / âm).
  double get totalKarmaDelta => appliedRatings.fold(
        0.0,
        (sum, r) => sum + r.karmaDeltaApplied,
      );

  @override
  List<Object?> get props => [lobbyId, appliedRatings];
}

/// Phần tử gửi lên `POST /api/v1/users/ratings/karma` — 1 entry
/// cho 1 target user.
class KarmaRatingEntry extends Equatable {
  final String targetUserId;
  final List<KarmaRatingTag> tags;

  /// LobbyId mà rating này áp dụng cho.
  final String? lobbyId;

  const KarmaRatingEntry({
    required this.targetUserId,
    required this.tags,
    this.lobbyId,
  });

  @override
  List<Object?> get props => [targetUserId, tags, lobbyId];
}

/// Entity kế thừa cho Player rating card — chỉ dùng để hiển thị trong
/// UI karma flow. Tách khỏi `RatingEntity` (đã legacy cho match
/// result/ELO) để tránh hiểu nhầm giữa 2 hệ rating.
class RatingPlayer {
  final String id;
  final String name;
  final String avatarUrl;
  final List<String> selectedTagIds;
  final bool alreadyRated;

  const RatingPlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.selectedTagIds = const [],
    this.alreadyRated = false,
  });

  RatingPlayer copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    List<String>? selectedTagIds,
    bool? alreadyRated,
  }) {
    return RatingPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      alreadyRated: alreadyRated ?? this.alreadyRated,
    );
  }
}

/// Legacy — chỉ còn dùng nội bộ cho ELO rating flow (đã tách riêng
/// khỏi karma rating). Giữ lại để không phá code cũ đang build.
/// Nếu ELO flow đã được chuyển sang [match_summary_rating] thật, có
/// thể xoá kèm `RatingCubit`.
class RatingEntity extends Equatable {
  final String id;
  final String sessionId;
  final String playerId;
  final String playerName;
  final String avatarUrl;
  final List<KarmaTag> karmaTags;
  final int karmaScore;

  const RatingEntity({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.playerName,
    required this.avatarUrl,
    required this.karmaTags,
    required this.karmaScore,
  });

  @override
  List<Object?> get props => [
    id,
    sessionId,
    playerId,
    playerName,
    avatarUrl,
    karmaTags,
    karmaScore,
  ];
}

/// Legacy — ELO result từ match result flow. Giữ cho code cũ không
/// phải refactor ngay.
class EloResult extends Equatable {
  final String sessionId;
  final MatchResult result;
  final int eloChange;
  final int currentElo;
  final int newElo;

  const EloResult({
    required this.sessionId,
    required this.result,
    required this.eloChange,
    required this.currentElo,
    required this.newElo,
  });

  @override
  List<Object?> get props => [sessionId, result, eloChange, currentElo, newElo];
}

enum MatchResult { win, lose, draw }
