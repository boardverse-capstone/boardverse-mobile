import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendProfileEntity] — response của
/// `GET /api/v1/friends/{userId}/profile`.
///
/// **Backend trả `PlayerProfileDto` với envelope wrapper** (theo `.agents/docs/swagger.json`):
/// ```json
/// {
///   "statusCode": 200,
///   "message": "...",
///   "data": {
///     "userId": "...",
///     "username": "jonny",
///     "avatarUrl": null,
///     "avatarBorderUrl": null,
///     "bio": "player friendly",
///     "firstName": "jonny",
///     "lastName": "tran",
///     "globalElo": 1200,
///     "karmaPoints": 100,
///     "gamerTier": "Bronze",
///     "level": 1,
///     "friendsCount": 0,
///     "mutualFriendsCount": 0,
///     "activityStatus": "Offline",
///     "lastActiveAt": null,
///     "joinedAt": "2026-06-06T02:52:28.920457Z",
///     "relationship": {
///       "status": "None | PendingSent | PendingReceived | Accepted | BlockedByMe | BlockedByThem",
///       "friendshipId": "...",
///       "isRequester": false,
///       "friendsSince": "...",
///       "message": "..."
///     },
///     "canSendFriendRequest": true,
///     "canReport": false
///   }
/// }
/// ```
///
/// **Lưu ý schema**: Backend đổi từ `friendshipStatus` top-level sang
/// `relationship.status` nested. `isBlockedByMe` / `hasBlockedMe` cũ derive
/// từ `relationship.status` (`BlockedByMe` / `BlockedByThem`) thay vì field
/// top-level riêng. Model parse defensive cho cả schema cũ + mới.
class FriendProfileModel {
  const FriendProfileModel({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.globalElo,
    required this.level,
    required this.mutualFriendsCount,
    required this.canSendFriendRequest,
    required this.canReport,
    this.bio,
    this.gamerTier,
    this.friendshipStatus,
    this.friendsSince,
    this.isBlockedByMe = false,
    this.hasBlockedMe = false,
    this.mutualFriends = const [],
  });

  final String userId;
  final String username;
  final String avatarUrl;
  final String? bio;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final int globalElo;
  final int level;
  final int mutualFriendsCount;
  final FriendshipStatus? friendshipStatus;
  final DateTime? friendsSince;
  final bool isBlockedByMe;
  final bool hasBlockedMe;
  final bool canSendFriendRequest;
  final bool canReport;
  final List<MutualFriendSummaryModel> mutualFriends;

  factory FriendProfileModel.fromJson(Map<String, dynamic> json) {
    // Backend wrap trong `{ relationship: { status, ... } }` — extract nested
    // object để dễ đọc.
    final relationship = json['relationship'];
    final isRelationshipMap = relationship is Map<String, dynamic>;
    final relationshipStatus = isRelationshipMap
        ? relationship['status'] as String?
        : null;
    final relationshipFriendsSince = isRelationshipMap
        ? parseDateTime(relationship['friendsSince'])
        : null;

    // Friendship status từ `relationship.status` (schema mới) HOẶC fallback
    // từ `friendshipStatus` top-level (schema cũ) HOẶC `status` top-level
    // (một số endpoint flatten).
    final statusValue = relationshipStatus ??
        json['friendshipStatus'] as String? ??
        json['status'] as String?;

    // Block flags derive từ `relationship.status` (schema mới) HOẶC từ
    // `isBlockedByMe` / `hasBlockedMe` top-level (schema cũ).
    final isBlockedByMe = relationshipStatus == 'BlockedByMe' ||
        json['isBlockedByMe'] == true;
    final hasBlockedMe = relationshipStatus == 'BlockedByThem' ||
        json['hasBlockedMe'] == true;

    return FriendProfileModel(
      userId: (json['userId'] ?? json['odId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
      bio: json['bio']?.toString(),
      karmaPoints: (json['karmaPoints'] ?? json['karma'] ?? 0) as int,
      gamerTier: _parseGamerTier(json['gamerTier']),
      globalElo: (json['globalElo'] ?? 0) as int,
      level: (json['level'] ?? 1) as int,
      mutualFriendsCount: (json['mutualFriendsCount'] ?? 0) as int,
      friendshipStatus: _parseFriendshipStatus(statusValue),
      friendsSince: relationshipFriendsSince ?? parseDateTime(json['friendsSince']),
      isBlockedByMe: isBlockedByMe,
      hasBlockedMe: hasBlockedMe,
      canSendFriendRequest: json['canSendFriendRequest'] as bool? ?? true,
      canReport: json['canReport'] as bool? ?? false,
      mutualFriends: _parseMutualFriends(json['mutualFriends']),
    );
  }

  static GamerTier? _parseGamerTier(dynamic value) {
    if (value == null) return null;
    return parseEnum<GamerTier>(
      GamerTier.values,
      value,
      fallback: GamerTier.bronze,
      aliases: const {
        'plat': GamerTier.platinum,
      },
    );
  }

  /// Parse [FriendshipStatus] từ backend. Backend `.NET` trả 6 giá trị:
  /// - `None` → `none`
  /// - `PendingSent` → `pendingSent`
  /// - `PendingReceived` → `pendingReceived`
  /// - `Accepted` → `accepted`
  /// - `BlockedByMe` → `blocked`
  /// - `BlockedByThem` → `blocked` (UI vẫn hiển thị "Đã chặn" cho cả 2 case;
  ///   backend không phân biệt ở entity `FriendshipStatus` của frontend).
  ///
  /// Vẫn giữ alias cũ `Pending` / `Blocked` / `friend` / `none` cho
  /// robustness khi backend đổi schema.
  static FriendshipStatus? _parseFriendshipStatus(dynamic value) {
    if (value == null) return FriendshipStatus.none;
    return parseEnum<FriendshipStatus>(
      FriendshipStatus.values,
      value,
      fallback: FriendshipStatus.none,
      aliases: const {
        'nones': FriendshipStatus.none,
        'none': FriendshipStatus.none,
        'notfriend': FriendshipStatus.none,
        'pendingsent': FriendshipStatus.pendingSent,
        'pending': FriendshipStatus.pendingSent,
        'pendingreceived': FriendshipStatus.pendingReceived,
        'accepted': FriendshipStatus.accepted,
        'friend': FriendshipStatus.accepted,
        'friends': FriendshipStatus.accepted,
        'blockedbyme': FriendshipStatus.blocked,
        'blockedbythem': FriendshipStatus.blocked,
        'blocked': FriendshipStatus.blocked,
        'block': FriendshipStatus.blocked,
      },
    );
  }

  static List<MutualFriendSummaryModel> _parseMutualFriends(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(MutualFriendSummaryModel.fromJson)
        .toList();
  }

  FriendProfileEntity toEntity() => FriendProfileEntity(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        globalElo: globalElo,
        level: level,
        mutualFriendsCount: mutualFriendsCount,
        friendshipStatus:
            friendshipStatus ?? FriendshipStatus.none,
        friendsSince: friendsSince,
        isBlockedByMe: isBlockedByMe,
        hasBlockedMe: hasBlockedMe,
        canSendFriendRequest: canSendFriendRequest,
        canReport: canReport,
        mutualFriends: mutualFriends.map((m) => m.toEntity()).toList(),
      );
}

/// Model nhỏ cho từng bạn chung trong preview list.
class MutualFriendSummaryModel {
  const MutualFriendSummaryModel({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });

  final String userId;
  final String username;
  final String avatarUrl;

  factory MutualFriendSummaryModel.fromJson(Map<String, dynamic> json) {
    return MutualFriendSummaryModel(
      userId: (json['userId'] ?? json['odId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
    );
  }

  MutualFriendSummary toEntity() => MutualFriendSummary(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
      );
}
