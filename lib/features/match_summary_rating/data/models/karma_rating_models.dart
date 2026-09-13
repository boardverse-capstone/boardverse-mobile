import '../../domain/entities/rating_entity.dart';

/// Model + entity cho response `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}`
/// (AC 3.2 — spec `user-ratings.md`).
class KarmaRatingContextModel {
  final String lobbyId;
  final String lobbyStatus;
  final bool canSubmitRatings;
  final List<KarmaTagModel> availableTags;
  final List<MemberToRateModel> membersToRate;

  const KarmaRatingContextModel({
    required this.lobbyId,
    required this.lobbyStatus,
    required this.canSubmitRatings,
    required this.availableTags,
    required this.membersToRate,
  });

  factory KarmaRatingContextModel.fromJson(Map<String, dynamic> json) {
    final tags = (json['availableTags'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(KarmaTagModel.fromJson)
        .toList();
    final members = (json['membersToRate'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MemberToRateModel.fromJson)
        .toList();
    return KarmaRatingContextModel(
      lobbyId: (json['lobbyId'] ?? '').toString(),
      lobbyStatus: (json['lobbyStatus'] ?? '').toString(),
      canSubmitRatings: json['canSubmitRatings'] as bool? ?? false,
      availableTags: tags,
      membersToRate: members,
    );
  }

  KarmaRatingContextEntity toEntity() {
    return KarmaRatingContextEntity(
      lobbyId: lobbyId,
      lobbyStatus: lobbyStatus,
      canSubmitRatings: canSubmitRatings,
      availableTags: availableTags.map((m) => m.toEntity()).toList(),
      membersToRate: membersToRate.map((m) => m.toEntity()).toList(),
    );
  }
}

/// Model cho 1 entry trong `availableTags[]` — chỉ backend trả
/// `tag` (PascalCase) và `karmaWeight` (double). UI sẽ map sang
/// `KarmaRatingTag` enum để lấy label/icon tiếng Việt.
class KarmaTagModel {
  final String tag;
  final double karmaWeight;

  const KarmaTagModel({required this.tag, required this.karmaWeight});

  factory KarmaTagModel.fromJson(Map<String, dynamic> json) {
    return KarmaTagModel(
      tag: (json['tag'] ?? '').toString(),
      karmaWeight: (json['karmaWeight'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Convert sang entity [KarmaTag] dùng cho UI.
  ///
  /// Fallback: nếu backend trả tag lạ (không match enum), vẫn tạo
  /// entity để hiển thị raw label — không làm crash UI.
  KarmaTag toEntity() {
    final known = KarmaRatingTag.fromApiValue(tag);
    if (known != null) {
      return KarmaTag.fromApi(known);
    }
    return KarmaTag(
      id: tag,
      name: tag,
      icon: 'label_outline',
      isPositive: karmaWeight > 0,
      weight: karmaWeight,
    );
  }
}

/// Model cho 1 entry trong `membersToRate[]` — member cần được đánh giá.
class MemberToRateModel {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool alreadyRated;

  const MemberToRateModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.alreadyRated = false,
  });

  factory MemberToRateModel.fromJson(Map<String, dynamic> json) {
    return MemberToRateModel(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      alreadyRated: json['alreadyRated'] as bool? ?? false,
    );
  }

  MemberToRate toEntity() {
    return MemberToRate(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      alreadyRated: alreadyRated,
    );
  }
}

/// Model + entity cho response `POST /api/v1/users/ratings/karma`
/// (AC 3.3 — spec `user-ratings.md`).
class SubmitKarmaRatingsResultModel {
  final String lobbyId;
  final List<AppliedKarmaRatingModel> appliedRatings;

  const SubmitKarmaRatingsResultModel({
    required this.lobbyId,
    required this.appliedRatings,
  });

  factory SubmitKarmaRatingsResultModel.fromJson(Map<String, dynamic> json) {
    final applied = (json['appliedRatings'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppliedKarmaRatingModel.fromJson)
        .toList();
    return SubmitKarmaRatingsResultModel(
      lobbyId: (json['lobbyId'] ?? '').toString(),
      appliedRatings: applied,
    );
  }

  SubmitKarmaRatingsResultEntity toEntity() {
    return SubmitKarmaRatingsResultEntity(
      lobbyId: lobbyId,
      appliedRatings: appliedRatings.map((m) => m.toEntity()).toList(),
    );
  }
}

/// Model cho 1 entry trong `appliedRatings[]` — kết quả áp dụng Karma
/// cho 1 target.
class AppliedKarmaRatingModel {
  final String targetUserId;
  final List<String> tags;
  final double karmaDeltaApplied;
  final int targetKarmaPointsAfter;
  final String targetGamerTier;

  const AppliedKarmaRatingModel({
    required this.targetUserId,
    required this.tags,
    required this.karmaDeltaApplied,
    required this.targetKarmaPointsAfter,
    required this.targetGamerTier,
  });

  factory AppliedKarmaRatingModel.fromJson(Map<String, dynamic> json) {
    return AppliedKarmaRatingModel(
      targetUserId: (json['targetUserId'] ?? '').toString(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      karmaDeltaApplied:
          (json['karmaDeltaApplied'] as num?)?.toDouble() ?? 0,
      targetKarmaPointsAfter:
          (json['targetKarmaPointsAfter'] as num?)?.toInt() ?? 0,
      targetGamerTier: (json['targetGamerTier'] ?? '').toString(),
    );
  }

  AppliedKarmaRatingEntity toEntity() {
    return AppliedKarmaRatingEntity(
      targetUserId: targetUserId,
      tags: tags,
      karmaDeltaApplied: karmaDeltaApplied,
      targetKarmaPointsAfter: targetKarmaPointsAfter,
      targetGamerTier: targetGamerTier,
    );
  }
}
