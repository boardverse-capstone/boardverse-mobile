import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendRequestEntity] — dùng cho inbox (received) và outbox (sent).
///
/// Parse từ `FriendshipResponseDto` (backend .NET, theo
/// `.agents/docs/lobby_docs/friend.md`). Schema backend thực tế dùng **generic
/// `other*` prefix** thay vì `requester*` — field `otherUserId` / `otherUsername`
/// / `otherAvatarUrl` luôn trỏ về user kia (không phải current user), còn
/// `isRequester` cho biết current user là requester hay addressee:
///
/// ```json
/// {
///   "friendshipId": "762b3368-d8ef-4084-ab31-e6be6d32dc4d",
///   "otherUserId": "092bbcf3-e729-43b5-8913-898961babc99",
///   "otherUsername": "jonny",
///   "otherAvatarUrl": null,
///   "status": "Pending",
///   "isRequester": false,
///   "createdAt": "2026-07-28T12:16:41.670646Z",
///   "acceptedAt": null,
///   "message": null,
///   "addresseeReadAt": null,
///   "mutualFriendsCount": 0
/// }
/// ```
///
/// **Defensive parsing:** Model vẫn thử nhiều alias (`requester*` / `sender*` /
/// `friend*` / nested object) cho robustness nếu backend đổi schema sau này.
/// Alias **`other*`** được đặt đầu tiên vì đó là schema thực tế đã verify.
///
/// Nếu sau khi parse vẫn rỗng `requesterName`, UI fallback về `User #<id>`
/// (xem `FriendRequestCard._displayName`). Không để UI hiển thị "name rỗng".
class FriendRequestModel {
  const FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatar,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.isRead = false,
    this.mutualFriendsCount,
    this.karmaPoints,
    this.gamerTier,
  });

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
  final int? karmaPoints;
  final GamerTier? gamerTier;

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: _pickString(json, const [
        'friendshipId',
        'requestId',
        'id',
      ]),
      requesterId: _pickString(json, const [
        // Schema thực tế: `otherUserId` luôn trỏ về user kia
        // (không phải current user).
        'otherUserId',
        // Fallback aliases nếu backend đổi schema sau này:
        'requesterId',
        'userId',
        'odId',
        'senderId',
        'fromId',
        'fromUserId',
        'friendUserId',
        'id',
      ]),
      requesterName: _pickName(
        json,
        const [
          'otherUsername',
          'requesterName',
          'username',
          'userName',
          'name',
          'displayName',
        ],
      ),
      requesterAvatar: _pickString(json, const [
        'otherAvatarUrl',
        'requesterAvatar',
        'avatarUrl',
        'avatar',
        'avatarURL',
      ]),
      message: json['message'] as String?,
      status: _parseStatus(json['status']),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      expiresAt: parseDateTime(json['expiresAt']) ??
          parseDateTime(json['createdAt'])?.add(const Duration(days: 30)) ??
          DateTime.now().add(const Duration(days: 30)),
      isRead: json['addresseeReadAt'] != null || json['isRead'] == true,
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
      karmaPoints: (json['karmaPoints'] ?? json['karma']) as int?,
      gamerTier: _parseGamerTier(json['gamerTier']),
    );
  }

  /// Lấy string với multiple alias. Trả về chuỗi rỗng nếu không tìm thấy
  /// (để UI fallback về `User #<id>` chứ không phải `null`).
  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final v = json[key];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    // Nested object: `requester: { ... }` / `addressee: { ... }` /
    // `sender: { ... }` / `user: { ... }`.
    for (final nestedKey in const [
      'requester',
      'addressee',
      'sender',
      'user',
      'friend',
      'other',
    ]) {
      final nested = json[nestedKey];
      if (nested is Map<String, dynamic>) {
        for (final key in keys) {
          final v = nested[key];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
      }
    }
    return '';
  }

  /// Pick name — đặc biệt tìm cả full name ghép từ firstName + lastName
  /// (một số DTO chỉ trả firstName/lastName).
  static String _pickName(Map<String, dynamic> json, List<String> keys) {
    final direct = _pickString(json, keys);
    if (direct.isNotEmpty) return direct;
    // Ghép firstName + lastName từ nested object (vd `requester.firstName`).
    for (final nestedKey in const [
      'requester',
      'addressee',
      'sender',
      'user',
      'friend',
      'other',
    ]) {
      final nested = json[nestedKey];
      if (nested is Map<String, dynamic>) {
        final first = nested['firstName']?.toString();
        final last = nested['lastName']?.toString();
        final combined = [first, last]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ')
            .trim();
        if (combined.isNotEmpty) return combined;
      }
    }
    return '';
  }

  /// Parse [FriendRequestStatus] từ backend. Backend .NET trả:
  /// `Pending` / `Accepted` / `Declined` / `Removed` / `Expired`.
  static FriendRequestStatus _parseStatus(dynamic value) {
    return parseEnum<FriendRequestStatus>(
      FriendRequestStatus.values,
      value,
      fallback: FriendRequestStatus.pending,
      aliases: const {
        'pending': FriendRequestStatus.pending,
        'accepted': FriendRequestStatus.accepted,
        'declined': FriendRequestStatus.declined,
        'rejected': FriendRequestStatus.declined,
        'removed': FriendRequestStatus.removed,
        'cancelled': FriendRequestStatus.removed,
        'expired': FriendRequestStatus.expired,
      },
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
      'karmaPoints': karmaPoints,
      'gamerTier': gamerTier?.name,
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
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
      );
}
