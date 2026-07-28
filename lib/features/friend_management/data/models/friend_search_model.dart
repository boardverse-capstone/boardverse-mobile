import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendSuggestionEntity] — kết quả gợi ý kết bạn.
class FriendSuggestionModel {
  const FriendSuggestionModel({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.mutualFriendsCount,
    required this.reason,
    this.gamerTier,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final int mutualFriendsCount;
  final String reason;

  factory FriendSuggestionModel.fromJson(Map<String, dynamic> json) {
    return FriendSuggestionModel(
      odId: (json['odId'] ?? json['userId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
      karmaPoints: (json['karmaPoints'] ?? json['karma'] ?? 0) as int,
      gamerTier: _parseGamerTier(json['gamerTier']),
      mutualFriendsCount: (json['mutualFriendsCount'] ?? 0) as int,
      reason: (json['reason'] ?? 'Gợi ý cho bạn').toString(),
    );
  }

  static GamerTier? _parseGamerTier(dynamic value) {
    return parseEnum<GamerTier>(
      GamerTier.values,
      value,
      fallback: GamerTier.bronze,
      aliases: const {
        'plat': GamerTier.platinum,
      },
    );
  }

  FriendSuggestionEntity toEntity() => FriendSuggestionEntity(
        odId: odId,
        username: username,
        avatarUrl: avatarUrl,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        mutualFriendsCount: mutualFriendsCount,
        reason: reason,
      );
}

/// Model cho [UserSearchEntity] — kết quả tìm user.
class UserSearchModel {
  const UserSearchModel({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    required this.mutualFriendsCount,
    this.friendshipStatus,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final FriendshipStatus? friendshipStatus;
  final int mutualFriendsCount;

  factory UserSearchModel.fromJson(Map<String, dynamic> json) {
    return UserSearchModel(
      odId: (json['odId'] ?? json['userId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
      karmaPoints: (json['karmaPoints'] ?? json['karma'] ?? 0) as int,
      friendshipStatus: _parseFriendshipStatus(json['friendshipStatus']),
      mutualFriendsCount: (json['mutualFriendsCount'] ?? 0) as int,
    );
  }

  /// Parse [FriendshipStatus] từ backend. Backend .NET trả:
  /// - `null` (chưa quan hệ) → `FriendshipStatus.none`
  /// - `Pending` → `FriendshipStatus.pendingSent` (UI search mặc định coi như
  ///   current user đã gửi; nếu backend sau này trả thêm `requesterId` thì ta
  ///   sẽ phân biệt sent/received).
  /// - `Accepted` → `FriendshipStatus.accepted`
  /// - `Blocked` → `FriendshipStatus.blocked`
  static FriendshipStatus? _parseFriendshipStatus(dynamic value) {
    if (value == null) return FriendshipStatus.none;
    return parseEnum<FriendshipStatus>(
      FriendshipStatus.values,
      value,
      fallback: FriendshipStatus.none,
      aliases: const {
        'pending': FriendshipStatus.pendingSent,
        'pendingsent': FriendshipStatus.pendingSent,
        'pendingreceived': FriendshipStatus.pendingReceived,
        'accepted': FriendshipStatus.accepted,
        'friend': FriendshipStatus.accepted,
        'friends': FriendshipStatus.accepted,
        'blocked': FriendshipStatus.blocked,
        'block': FriendshipStatus.blocked,
        'none': FriendshipStatus.none,
        'notfriend': FriendshipStatus.none,
      },
    );
  }

  UserSearchEntity toEntity() => UserSearchEntity(
        odId: odId,
        username: username,
        avatarUrl: avatarUrl,
        karmaPoints: karmaPoints,
        friendshipStatus: friendshipStatus,
        mutualFriendsCount: mutualFriendsCount,
      );
}
