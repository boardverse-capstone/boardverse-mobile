import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../domain/entities/friend_entity.dart';
import '../domain/repositories/friend_repository.dart';
import 'datasources/base/friend_remote_datasource.dart';

/// Implementation của FriendRepository.
class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl({required this._datasource});

  final FriendRemoteDatasource _datasource;

  // ─── Friends ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends() {
    return _datasource.getFriends();
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() {
    return _datasource.getFriendsWithActivity();
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendList(String otherUserId) {
    return _datasource.getFriendList(otherUserId);
  }

  // ─── Friend Requests ───────────────────────────────────────────────────────

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

  // ─── Friend Actions ────────────────────────────────────────────────────────

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

  // ─── Search & Suggestions ───────────────────────────────────────────────────

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

  // ─── Friend Notes ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<FriendNoteEntity>>> getAllNotes() {
    return _datasource.getAllNotes();
  }

  @override
  Future<Either<Failure, FriendNoteEntity>> upsertNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  }) {
    return _datasource.upsertNote(
      friendUserId: friendUserId,
      alias: alias,
      note: note,
      tags: tags,
    );
  }

  @override
  Future<Either<Failure, void>> deleteNote(String noteId) {
    return _datasource.deleteNote(noteId);
  }

  // ─── Friend Privacy ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, FriendPrivacyEntity>> getPrivacySettings() {
    return _datasource.getPrivacySettings();
  }

  @override
  Future<Either<Failure, FriendPrivacyEntity>> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  }) {
    return _datasource.updatePrivacySettings(
      isFriendListPublic: isFriendListPublic,
      acceptFriendRequestsFrom: acceptFriendRequestsFrom,
      friendLimit: friendLimit,
    );
  }

  // ─── Friend Reports ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) {
    return _datasource.createReport(
      targetUserId: targetUserId,
      category: category,
      reason: reason,
    );
  }

  @override
  Future<Either<Failure, List<FriendReportEntity>>> getMyReports() {
    return _datasource.getMyReports();
  }
}
