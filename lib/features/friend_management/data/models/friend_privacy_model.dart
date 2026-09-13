import '../../domain/entities/entities.dart';

/// Model cho [FriendPrivacyEntity] — cài đặt riêng tư của current user.
class FriendPrivacyModel {
  const FriendPrivacyModel({
    required this.isFriendListPublic,
    required this.friendLimit,
    this.acceptFriendRequestsFrom,
  });

  final bool isFriendListPublic;
  final String? acceptFriendRequestsFrom;
  final int friendLimit;

  factory FriendPrivacyModel.fromJson(Map<String, dynamic> json) {
    return FriendPrivacyModel(
      isFriendListPublic: json['isFriendListPublic'] as bool? ?? true,
      acceptFriendRequestsFrom: json['acceptFriendRequestsFrom'] as String?,
      friendLimit: ((json['friendLimit'] ?? 5000) as num?)?.toInt() ?? 5000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFriendListPublic': isFriendListPublic,
      if (acceptFriendRequestsFrom != null)
        'acceptFriendRequestsFrom': acceptFriendRequestsFrom,
      'friendLimit': friendLimit,
    };
  }

  FriendPrivacyEntity toEntity() => FriendPrivacyEntity(
        isFriendListPublic: isFriendListPublic,
        acceptFriendRequestsFrom: acceptFriendRequestsFrom,
        friendLimit: friendLimit,
      );
}
