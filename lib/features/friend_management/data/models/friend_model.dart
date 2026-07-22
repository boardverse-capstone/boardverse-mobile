import '../../domain/entities/friend_entity.dart';

class FriendModel {
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

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      odId: (json['odId'] ?? json['userId'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
      karmaPoints: (json['karmaPoints'] ?? json['karma'] ?? 0) as int,
      gamerTier: _parseGamerTier(json['gamerTier']),
      friendsSince: _parseDateTime(json['friendsSince']),
      activityStatus: _parseActivityStatus(json['activityStatus']),
      lastActiveAt: _parseDateTime(json['lastActiveAt']),
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
      isInLobby: json['isInLobby'] as bool? ?? false,
    );
  }

  static GamerTier? _parseGamerTier(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    return GamerTier.values.firstWhere(
      (e) => e.name == str,
      orElse: () => GamerTier.bronze,
    );
  }

  static ActivityStatus? _parseActivityStatus(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    return ActivityStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => ActivityStatus.offline,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

class FriendRequestModel {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String requesterAvatar;
  final String? message;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRead;
  final int? mutualFriendsCount;

  const FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.isRead = false,
    this.mutualFriendsCount,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: (json['requestId'] ?? json['id'] ?? '').toString(),
      requesterId: (json['requesterId'] ?? json['userId'] ?? '').toString(),
      requesterName: (json['requesterName'] ?? json['username'] ?? json['name'] ?? '').toString(),
      requesterAvatar: (json['requesterAvatar'] ?? json['avatarUrl'] ?? '').toString(),
      message: json['message'] as String?,
      status: _parseStatus(json['status']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDateTime(json['expiresAt']) ?? DateTime.now().add(const Duration(days: 30)),
      isRead: json['addresseeReadAt'] != null || json['isRead'] == true,
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
    );
  }

  static FriendRequestStatus _parseStatus(dynamic value) {
    if (value == null) return FriendRequestStatus.pending;
    final str = value.toString().toLowerCase();
    return FriendRequestStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => FriendRequestStatus.pending,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterAvatar': requesterAvatar,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isRead': isRead,
      'mutualFriendsCount': mutualFriendsCount,
    };
  }

  FriendRequestEntity toEntity() => FriendRequestEntity(
        requestId: requestId,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterAvatar: requesterAvatar,
        message: message,
        status: status,
        createdAt: createdAt,
        expiresAt: expiresAt,
        isRead: isRead,
        mutualFriendsCount: mutualFriendsCount,
      );
}

class FriendSuggestionModel {
  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final GamerTier? gamerTier;
  final int mutualFriendsCount;
  final String reason;

  const FriendSuggestionModel({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.gamerTier,
    required this.mutualFriendsCount,
    required this.reason,
  });

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
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    return GamerTier.values.firstWhere(
      (e) => e.name == str,
      orElse: () => GamerTier.bronze,
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

class UserSearchModel {
  final String odId;
  final String username;
  final String avatarUrl;
  final int karmaPoints;
  final FriendshipStatus? friendshipStatus;
  final int mutualFriendsCount;

  const UserSearchModel({
    required this.odId,
    required this.username,
    required this.avatarUrl,
    required this.karmaPoints,
    this.friendshipStatus,
    required this.mutualFriendsCount,
  });

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

  static FriendshipStatus? _parseFriendshipStatus(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    return FriendshipStatus.values.firstWhere(
      (e) => e.name == str,
      orElse: () => FriendshipStatus.none,
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
