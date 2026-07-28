import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendRequestEntity] — dùng cho inbox (received) và outbox (sent).
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

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: (json['requestId'] ?? json['id'] ?? '').toString(),
      requesterId: (json['requesterId'] ?? json['userId'] ?? '').toString(),
      requesterName:
          (json['requesterName'] ?? json['username'] ?? json['name'] ?? '')
              .toString(),
      requesterAvatar:
          (json['requesterAvatar'] ?? json['avatarUrl'] ?? '').toString(),
      message: json['message'] as String?,
      status: _parseStatus(json['status']),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      expiresAt: parseDateTime(json['expiresAt']) ??
          DateTime.now().add(const Duration(days: 30)),
      isRead: json['addresseeReadAt'] != null || json['isRead'] == true,
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
    );
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
