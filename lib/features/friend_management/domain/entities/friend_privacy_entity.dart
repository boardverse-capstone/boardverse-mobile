import 'package:equatable/equatable.dart';

/// Cài đặt riêng tư cho friend list của current user.
///
/// - `isFriendListPublic`: cho phép người lạ xem friend list của mình.
/// - `acceptFriendRequestsFrom`: ai được phép gửi friend request.
///   Backend enum: `Everyone` / `FriendsOfFriends`.
/// - `friendLimit`: giới hạn số bạn (0 = không giới hạn, tối đa 5000).
class FriendPrivacyEntity extends Equatable {
  const FriendPrivacyEntity({
    required this.isFriendListPublic,
    required this.friendLimit,
    this.acceptFriendRequestsFrom,
  });

  final bool isFriendListPublic;
  final String? acceptFriendRequestsFrom;
  final int friendLimit;

  @override
  List<Object?> get props => [
        isFriendListPublic,
        acceptFriendRequestsFrom,
        friendLimit,
      ];
}
