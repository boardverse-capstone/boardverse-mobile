import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../../../domain/entities/friend_entity.dart';

/// Data source interface cho Friend Management.
/// Implementations:
/// - `RealFriendRemoteDatasource` - kết nối real API
/// - `MockFriendRemoteDatasource` - mock data cho dev
abstract class FriendRemoteDatasource {
  Future<Either<Failure, List<FriendEntity>>> getFriends();
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity();
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests();
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests();
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  });
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId);
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId);
  Future<Either<Failure, void>> markRequestAsRead(String requestId);
  Future<Either<Failure, void>> unfriend(String friendId);
  Future<Either<Failure, void>> blockUser(String userId);
  Future<Either<Failure, void>> unblockUser(String userId);
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  });
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({int limit = 20});
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId);
}
