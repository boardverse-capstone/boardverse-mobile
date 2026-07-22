import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../entities/friend_entity.dart';

/// Repository interface cho Friend Management.
/// Chi tiết API: `.agents/docs/lobby_docs/friend.md`
abstract class FriendRepository {
  /// GET /api/v1/friends - Danh sách bạn bè (Accepted)
  Future<Either<Failure, List<FriendEntity>>> getFriends();

  /// GET /api/v1/friends/activity - Friend list + activity status
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity();

  /// GET /api/v1/friends/requests/received - Inbox: lời mời đã nhận
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests();

  /// GET /api/v1/friends/requests/sent - Outbox: lời mời đã gửi
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests();

  /// POST /api/v1/friends/requests - Gửi lời mời kết bạn
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  });

  /// POST /api/v1/friends/requests/{id}/accept - Accept lời mời
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId);

  /// POST /api/v1/friends/requests/{id}/decline - Decline lời mời
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId);

  /// POST /api/v1/friends/requests/{id}/read - Đánh dấu đã đọc
  Future<Either<Failure, void>> markRequestAsRead(String requestId);

  /// DELETE /api/v1/friends/{id} - Hủy kết bạn
  Future<Either<Failure, void>> unfriend(String friendId);

  /// POST /api/v1/friends/block/{userId} - Chặn user
  Future<Either<Failure, void>> blockUser(String userId);

  /// DELETE /api/v1/friends/block/{userId} - Bỏ chặn user
  Future<Either<Failure, void>> unblockUser(String userId);

  /// GET /api/v1/friends/search?q=&limit= - Tìm user theo username
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  });

  /// GET /api/v1/friends/suggestions?limit= - Gợi ý kết bạn
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({
    int limit = 20,
  });

  /// GET /api/v1/friends/{otherUserId}/mutual - Bạn chung
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId);
}
