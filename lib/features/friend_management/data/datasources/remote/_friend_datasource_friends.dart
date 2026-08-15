import 'package:dartz/dartz.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/data/models/friend_model.dart';
import 'package:boardverse/features/friend_management/data/models/friend_profile_model.dart';
import 'package:boardverse/features/friend_management/data/models/friend_request_model.dart';
import 'package:boardverse/features/friend_management/data/models/friend_search_model.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';

import '_api_guard_mixin.dart';

/// Phần 1: Friend list + Friend request CRUD + Search & suggestions.
///
/// Tách từ `real_friend_remote_datasource.dart` để giảm kích thước file và
/// nhóm theo concern. Các phần còn lại:
/// - `_real_friend_remote_datasource_notes.dart` — friend notes
/// - `_real_friend_remote_datasource_privacy_reports.dart` — privacy + reports
mixin FriendsAndRequestsMixin on ApiGuardMixin {
  Future<Either<Failure, List<FriendEntity>>> getFriends() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.friends);
      return parseListEnvelope<FriendEntity>(res.data, FriendModel.fromJson);
    });
  }

  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.friendsActivity);
      return parseListEnvelope<FriendEntity>(res.data, FriendModel.fromJson);
    });
  }

  Future<Either<Failure, List<FriendEntity>>> getFriendList(String otherUserId) {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendList(otherUserId),
      );
      return parseListEnvelope<FriendEntity>(res.data, FriendModel.fromJson);
    });
  }

  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId) {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendMutual(otherUserId),
      );
      return parseListEnvelope<FriendEntity>(res.data, FriendModel.fromJson);
    });
  }

  /// GET /api/v1/friends/{userId}/profile — chi tiết public profile của 1
  /// player (kèm `canSendFriendRequest`, `canReport`, mutual friends preview).
  Future<Either<Failure, FriendProfileEntity>> getPlayerProfile(String userId) {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendPlayerProfile(userId),
      );
      return FriendProfileModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendRequestsReceived,
      );
      return parseListEnvelope<FriendRequestEntity>(
        res.data,
        FriendRequestModel.fromJson,
      );
    });
  }

  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendRequestsSent,
      );
      return parseListEnvelope<FriendRequestEntity>(
        res.data,
        FriendRequestModel.fromJson,
      );
    });
  }

  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) {
    return guardApiCall(() async {
      final body = <String, dynamic>{'addresseeId': addresseeId};
      if (message != null && message.isNotEmpty) body['message'] = message;
      final res = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.friendRequests,
        data: body,
      );
      return FriendRequestModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId) {
    return guardApiCall(() async {
      final res = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.friendRequestAccept(requestId),
      );
      return FriendRequestModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId) {
    return guardApiCall(() async {
      final res = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.friendRequestDecline(requestId),
      );
      return FriendRequestModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, void>> markRequestAsRead(String requestId) {
    return guardApiCall(() async {
      await dio.post(ApiEndpoints.friendRequestRead(requestId));
    });
  }

  Future<Either<Failure, void>> unfriend(String friendId) {
    return guardApiCall(() async {
      await dio.delete(ApiEndpoints.friendUnfriend(friendId));
    });
  }

  Future<Either<Failure, void>> blockUser(String userId) {
    return guardApiCall(() async {
      await dio.post(ApiEndpoints.friendBlock(userId));
    });
  }

  Future<Either<Failure, void>> unblockUser(String userId) {
    return guardApiCall(() async {
      await dio.delete(ApiEndpoints.friendUnblock(userId));
    });
  }

  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  }) {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendSearch,
        queryParameters: {'q': query, 'limit': limit},
      );
      return parseListEnvelope<UserSearchEntity>(
        res.data,
        UserSearchModel.fromJson,
      );
    });
  }

  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({
    int limit = 20,
  }) {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.friendSuggestions,
        queryParameters: {'limit': limit},
      );
      return parseListEnvelope<FriendSuggestionEntity>(
        res.data,
        FriendSuggestionModel.fromJson,
      );
    });
  }
}
