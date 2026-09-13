import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendEntity] — dùng cho danh sách bạn, bạn chung, friend list
/// của user khác.
///
/// Parse từ `FriendSummaryDto` / `FriendActivityDto` của backend. Hai DTO này
/// có cùng trường cơ bản, khác nhau ở presence (`activityStatus` + `lastActiveAt`).
class FriendModel {
  const FriendModel({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.gamerTier,
    this.friendsSince,
    this.activityStatus,
    this.lastActiveAt,
    this.mutualFriendsCount,
    this.isInLobby = false,
  });

  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final DateTime? friendsSince;
  final ActivityStatus? activityStatus;
  final DateTime? lastActiveAt;
  final int? mutualFriendsCount;
  final bool isInLobby;

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      odId: (json['odId'] ?? json['userId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
      karmaPoints: ((json['karmaPoints'] ?? json['karma'] ?? 0) as num?)?.toInt() ?? 0,
      gamerTier: _parseGamerTier(json['gamerTier']),
      friendsSince: parseDateTime(json['friendsSince']),
      activityStatus: _parseActivityStatus(json['activityStatus']),
      lastActiveAt: parseDateTime(json['lastActiveAt']),
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
      isInLobby: json['isInLobby'] as bool? ?? false,
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

  /// Parse [ActivityStatus] từ backend. Backend .NET trả:
  /// `Online` / `RecentlyActive` / `Away` / `Offline`.
  static ActivityStatus? _parseActivityStatus(dynamic value) {
    return parseEnum<ActivityStatus>(
      ActivityStatus.values,
      value,
      fallback: ActivityStatus.offline,
      aliases: const {
        'recentlyactive': ActivityStatus.recentlyActive,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'odId': odId,
      'username': username,
      'avatarUrl': avatarUrl,
      'karmaPoints': karmaPoints,
      'gamerTier': gamerTier?.name,
      'friendsSince': friendsSince?.toIso8601String(),
      'activityStatus': activityStatus?.name,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'mutualFriendsCount': mutualFriendsCount,
      'isInLobby': isInLobby,
    };
  }

  FriendEntity toEntity() => FriendEntity(
        odId: odId,
        username: username,
        avatarUrl: avatarUrl,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        friendsSince: friendsSince,
        activityStatus: activityStatus,
        lastActiveAt: lastActiveAt,
        mutualFriendsCount: mutualFriendsCount,
        isInLobby: isInLobby,
      );
}
