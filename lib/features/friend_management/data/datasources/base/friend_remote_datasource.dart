import 'package:dartz/dartz.dart';

import 'package:boardverse/core/error/failures.dart';
import '../../../domain/entities/entities.dart';

/// Data source interface cho Friend Management.
/// Implementations:
/// - `RealFriendRemoteDatasource` - kết nối real API
/// - `MockFriendRemoteDatasource` - mock data cho dev
abstract class FriendRemoteDatasource {
  // ─── Friends ────────────────────────────────────────────────────────────────
  Future<Either<Failure, List<FriendEntity>>> getFriends();
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity();
  Future<Either<Failure, List<FriendEntity>>> getFriendList(String otherUserId);

  /// GET /api/v1/friends/{userId}/profile - Chi tiết public profile của 1
  /// player (bao gồm cả quan hệ hiện tại + permission flags).
  Future<Either<Failure, FriendProfileEntity>> getPlayerProfile(String userId);

  // ─── Friend Requests ───────────────────────────────────────────────────────
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests();
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests();
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  });
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId);
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId);
  Future<Either<Failure, void>> markRequestAsRead(String requestId);

  // ─── Friend Actions ────────────────────────────────────────────────────────
  Future<Either<Failure, void>> unfriend(String friendId);
  Future<Either<Failure, void>> blockUser(String userId);
  Future<Either<Failure, void>> unblockUser(String userId);

  // ─── Search & Suggestions ──────────────────────────────────────────────────
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  });
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({int limit = 20});
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId);

  // ─── Friend Notes ──────────────────────────────────────────────────────────
  Future<Either<Failure, List<FriendNoteEntity>>> getAllNotes();
  Future<Either<Failure, FriendNoteEntity>> upsertNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  });
  Future<Either<Failure, void>> deleteNote(String noteId);

  // ─── Friend Privacy ────────────────────────────────────────────────────────
  Future<Either<Failure, FriendPrivacyEntity>> getPrivacySettings();
  Future<Either<Failure, FriendPrivacyEntity>> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  });

  // ─── Friend Reports ────────────────────────────────────────────────────────
  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  });
  Future<Either<Failure, List<FriendReportEntity>>> getMyReports();
}
