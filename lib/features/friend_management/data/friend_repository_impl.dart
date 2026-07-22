import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../domain/entities/friend_entity.dart';
import '../domain/repositories/friend_repository.dart';
import 'datasources/base/friend_remote_datasource.dart';

/// Implementation của FriendRepository.
class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl({required this._datasource});

  final FriendRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends() {
    return _datasource.getFriends();
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() {
    return _datasource.getFriendsWithActivity();
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() {
    return _datasource.getReceivedRequests();
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() {
    return _datasource.getSentRequests();
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) {
    return _datasource.sendFriendRequest(
      addresseeId: addresseeId,
      message: message,
    );
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId) {
    return _datasource.acceptFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId) {
    return _datasource.declineFriendRequest(requestId);
  }

  @override
  Future<Either<Failure, void>> markRequestAsRead(String requestId) {
    return _datasource.markRequestAsRead(requestId);
  }

  @override
  Future<Either<Failure, void>> unfriend(String friendId) {
    return _datasource.unfriend(friendId);
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) {
    return _datasource.blockUser(userId);
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) {
    return _datasource.unblockUser(userId);
  }

  @override
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  }) {
    return _datasource.searchUsers(query: query, limit: limit);
  }

  @override
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({
    int limit = 20,
  }) {
    return _datasource.getSuggestions(limit: limit);
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId) {
    return _datasource.getMutualFriends(otherUserId);
  }
}
