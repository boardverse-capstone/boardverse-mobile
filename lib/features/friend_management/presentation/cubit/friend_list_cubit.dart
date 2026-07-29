import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/friend_repository.dart';
import 'friend_list_state.dart';

/// Identifier của các "section" (data slice) trong cubit. Dùng cùng
/// `FriendListLoaded.friendsLoading` / `receivedRequestsLoading` để UI
/// biết chính xác tab nào đang fetch dữ liệu.
enum SectionKind { friends, receivedRequests }

class FriendListCubit extends Cubit<FriendListState> {
  FriendListCubit({required this._repository}) : super(const FriendListInitial());

  final FriendRepository _repository;

  /// Cập nhật per-tab loading flag trong khi giữ nguyên data hiện có.
  ///
  /// Nếu state hiện tại chưa phải [FriendListLoaded] (vd vừa mount, chưa
  /// load gì) thì lần load đầu tiên vẫn emit [FriendListError] / [FriendListLoaded]
  /// bình thường — flag loading chỉ có ý nghĩa khi slice đó đã có data sẵn.
  void _setSectionLoading(SectionKind kind, bool isLoading) {
    final current = state;
    if (current is FriendListLoaded) {
      emit(current.copyWith(
        friendsLoading: kind == SectionKind.friends ? isLoading : current.friendsLoading,
        receivedRequestsLoading: kind == SectionKind.receivedRequests
            ? isLoading
            : current.receivedRequestsLoading,
      ));
    }
  }

  /// Tab "Bạn bè" — chỉ fetch friend list (status Accepted).
  Future<void> loadFriends() async {
    if (isClosed) return;
    _setSectionLoading(SectionKind.friends, true);

    final friendsResult = await _repository.getFriendsWithActivity();
    if (isClosed) return;

    friendsResult.fold(
      (failure) {
        _setSectionLoading(SectionKind.friends, false);
        emit(FriendListError(failure.message));
      },
      (data) {
        final current = state;
        final prev = current is FriendListLoaded ? current : null;
        emit(FriendListLoaded(
          friends: data,
          receivedRequests: prev?.receivedRequests ?? const [],
          unreadRequestCount: prev?.unreadRequestCount ?? 0,
          notes: prev?.notes ?? const [],
          privacySettings: prev?.privacySettings,
          myReports: prev?.myReports ?? const [],
        ));
      },
    );
  }

  /// Tab "Lời mời" — chỉ fetch received requests (inbox).
  /// Không fetch sent requests vì UI đã bỏ phần "Đã gửi"
  /// (xem BR-FRIEND-REQUESTS-UI).
  Future<void> loadReceivedRequests() async {
    if (isClosed) return;
    _setSectionLoading(SectionKind.receivedRequests, true);

    final receivedResult = await _repository.getReceivedRequests();
    if (isClosed) return;

    receivedResult.fold(
      (failure) {
        _setSectionLoading(SectionKind.receivedRequests, false);
        emit(FriendListError(failure.message));
      },
      (data) {
        final current = state;
        final prev = current is FriendListLoaded ? current : null;
        emit(FriendListLoaded(
          friends: prev?.friends ?? const [],
          receivedRequests: data,
          unreadRequestCount: data.where((r) => !r.isRead).length,
          notes: prev?.notes ?? const [],
          privacySettings: prev?.privacySettings,
          myReports: prev?.myReports ?? const [],
        ));
      },
    );
  }

  /// Pull-to-refresh cho tab "Bạn bè" — chỉ reload friend list.
  Future<void> refreshFriends() async => loadFriends();

  /// Pull-to-refresh cho tab "Lời mời" — chỉ reload received requests.
  Future<void> refreshReceivedRequests() async => loadReceivedRequests();

  Future<void> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    final currentState = state;
    final result = await _repository.sendFriendRequest(
      addresseeId: addresseeId,
      message: message,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (request) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            sentRequests: [...currentState.sentRequests, request],
          ));
        } else {
          emit(FriendRequestSent(addresseeId));
        }
      },
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final currentState = state;
    final result = await _repository.acceptFriendRequest(requestId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (updated) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(requestId: requestId, accepted: true));
        }
      },
    );
  }

  Future<void> declineFriendRequest(String requestId) async {
    final currentState = state;
    final result = await _repository.declineFriendRequest(requestId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (updated) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(requestId: requestId, accepted: false));
        }
      },
    );
  }

  Future<void> unfriend(String friendId) async {
    final currentState = state;
    final result = await _repository.unfriend(friendId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (_) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            friends: currentState.friends
                .where((f) => f.odId != friendId)
                .toList(),
          ));
        } else {
          emit(FriendUnfriended(friendId));
        }
      },
    );
  }

  Future<void> blockUser(String userId) async {
    final result = await _repository.blockUser(userId);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(FriendListError(failure.message)),
      (_) async {
        // Block 1 user có thể thay đổi cả friend list (user bị block biến
        // mất khỏi friends) + received requests (block giữa chừng). Reload
        // 2 slice này. Lời mời đã gửi không cần (UI đã bỏ).
        await loadFriends();
        if (isClosed) return;
        await loadReceivedRequests();
      },
    );
  }

  Future<void> markRequestAsRead(String requestId) async {
    await _repository.markRequestAsRead(requestId);

    if (isClosed) return;
    final currentState = state;
    if (currentState is FriendListLoaded) {
      final updated = currentState.receivedRequests.map((r) {
        if (r.requestId == requestId && !r.isRead) {
          return r;
        }
        return r;
      }).toList();
      emit(currentState.copyWith(
        receivedRequests: updated,
        unreadRequestCount: updated.where((r) => !r.isRead).length,
      ));
    }
  }

  // ─── Search users ────────────────────────────────────────────────────

  Future<List<UserSearchEntity>> searchUsers(String query) async {
    if (query.trim().isEmpty) return const [];
    final result = await _repository.searchUsers(query: query.trim());
    return result.fold((failure) => const <UserSearchEntity>[], (data) => data);
  }

  // ─── Friend Notes ──────────────────────────────────────────────────────────

  Future<void> loadNotes() async {
    if (isClosed) return;
    final result = await _repository.getAllNotes();
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (notes) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(notes: notes));
        }
      },
    );
  }

  Future<void> saveNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  }) async {
    if (isClosed) return;
    final result = await _repository.upsertNote(
      friendUserId: friendUserId,
      alias: alias,
      note: note,
      tags: tags,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (savedNote) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          final existingIndex =
              currentState.notes.indexWhere((n) => n.friendUserId == friendUserId);
          List<FriendNoteEntity> notes;
          if (existingIndex >= 0) {
            notes = List<FriendNoteEntity>.from(currentState.notes)
              ..[existingIndex] = savedNote;
          } else {
            notes = [...currentState.notes, savedNote];
          }
          emit(currentState.copyWith(notes: List.from(notes)));
        } else {
          emit(FriendNoteSaved(savedNote));
        }
      },
    );
  }

  Future<void> deleteNote(String noteId) async {
    if (isClosed) return;
    final result = await _repository.deleteNote(noteId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (_) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            notes: currentState.notes.where((n) => n.noteId != noteId).toList(),
          ));
        } else {
          emit(FriendNoteDeleted(noteId));
        }
      },
    );
  }

  // ─── Friend Privacy ───────────────────────────────────────────────────────

  Future<void> loadPrivacySettings() async {
    if (isClosed) return;
    final result = await _repository.getPrivacySettings();
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (privacy) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(privacySettings: privacy));
        }
      },
    );
  }

  Future<void> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  }) async {
    if (isClosed) return;
    final result = await _repository.updatePrivacySettings(
      isFriendListPublic: isFriendListPublic,
      acceptFriendRequestsFrom: acceptFriendRequestsFrom,
      friendLimit: friendLimit,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (privacy) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(privacySettings: privacy));
        } else {
          emit(FriendPrivacyUpdated(privacy));
        }
      },
    );
  }

  // ─── Friend Reports ───────────────────────────────────────────────────────

  Future<void> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) async {
    if (isClosed) return;
    final result = await _repository.createReport(
      targetUserId: targetUserId,
      category: category,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (_) {
        emit(FriendReportCreated(targetUserId));
      },
    );
  }

  Future<void> loadMyReports() async {
    if (isClosed) return;
    final result = await _repository.getMyReports();
    if (isClosed) return;
    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (reports) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(myReports: reports));
        }
      },
    );
  }
}
