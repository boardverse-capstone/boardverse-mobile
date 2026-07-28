import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../entities/friend_entity.dart';

/// Repository interface cho Friend Management.
/// Chi tiết API: `.agents/docs/lobby_docs/friend.md`
abstract class FriendRepository {
  // ─── Friends ────────────────────────────────────────────────────────────────
  /// GET /api/v1/friends - Danh sách bạn bè (Accepted)
  Future<Either<Failure, List<FriendEntity>>> getFriends();

  /// GET /api/v1/friends/activity - Friend list + activity status
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity();

  /// GET /api/v1/friends/{otherUserId}/list - Friend list của user khác
  Future<Either<Failure, List<FriendEntity>>> getFriendList(String otherUserId);

  // ─── Friend Requests ───────────────────────────────────────────────────────
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

  // ─── Friend Actions ────────────────────────────────────────────────────────
  /// DELETE /api/v1/friends/{id} - Hủy kết bạn
  Future<Either<Failure, void>> unfriend(String friendId);

  /// POST /api/v1/friends/block/{userId} - Chặn user
  Future<Either<Failure, void>> blockUser(String userId);

  /// DELETE /api/v1/friends/block/{userId} - Bỏ chặn user
  Future<Either<Failure, void>> unblockUser(String userId);

  // ─── Search & Suggestions ───────────────────────────────────────────────────
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

  // ─── Friend Notes ──────────────────────────────────────────────────────────
  /// GET /api/v1/friends/notes - Lấy tất cả ghi chú
  Future<Either<Failure, List<FriendNoteEntity>>> getAllNotes();

  /// PUT /api/v1/friends/notes/{friendUserId} - Tạo/cập nhật ghi chú
  Future<Either<Failure, FriendNoteEntity>> upsertNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  });

  /// DELETE /api/v1/friends/notes/{noteId} - Xóa ghi chú
  Future<Either<Failure, void>> deleteNote(String noteId);

  // ─── Friend Privacy ─────────────────────────────────────────────────────────
  /// GET /api/v1/friends/privacy - Lấy cài đặt riêng tư
  Future<Either<Failure, FriendPrivacyEntity>> getPrivacySettings();

  /// PUT /api/v1/friends/privacy - Cập nhật cài đặt riêng tư
  Future<Either<Failure, FriendPrivacyEntity>> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  });

  // ─── Friend Reports ────────────────────────────────────────────────────────
  /// POST /api/v1/friends/reports - Báo cáo vi phạm
  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  });

  /// GET /api/v1/friends/reports - Lấy danh sách báo cáo của mình
  Future<Either<Failure, List<FriendReportEntity>>> getMyReports();
}
