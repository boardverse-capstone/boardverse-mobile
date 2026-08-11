import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/friend_repository.dart';
import 'states/states.dart';

/// Identifier of tab "sections" for per-tab loading flags.
enum SectionKind { friends, receivedRequests }

/// Cubit for managing friend list state.
///
/// Handles:
/// - Friends list loading with per-tab loading states
/// - Friend requests (received/sent)
/// - Friend actions (accept, decline, unfriend, block)
/// - Search users
/// - Notes management
/// - Privacy settings
/// - Reports
///
/// Lưu ý quan trọng về data preservation:
/// - Khi `loadFriends()` hoặc `loadReceivedRequests()` fail, ta KHÔNG emit
///   `FriendListError` (sẽ phá hủy toàn bộ dữ liệu đã load) — thay vào đó
///   ta giữ nguyên `FriendListLoaded` và set `friendsError` /
///   `receivedRequestsError` cho section tương ứng. UI mỗi tab sẽ tự hiển
///   thị ErrorRetryView riêng.
/// - Fix bug cũ: trước đây `_emitError` luôn emit `FriendListError` → user
///   chuyển tab thấy màn hình trắng / "không tìm thấy bạn bè" dù list đã
///   load thành công trước đó.
class FriendListCubit extends Cubit<FriendListState> {
  FriendListCubit({required this.repository}) : super(const FriendListInitial());

  final FriendRepository repository;

  // ─── Section Loading Helpers ─────────────────────────────────────────────────

  /// Set loading cho 1 section, đồng thời clear error của section đó.
  /// Nếu state hiện tại chưa phải `FriendListLoaded`, ta tự khởi tạo
  /// một state rỗng để giữ UI ổn định (tránh mất dữ liệu khi đã load
  /// section khác trước đó).
  void _setSectionLoading(SectionKind kind, bool isLoading) {
    final current = state;
    if (current is FriendListLoaded) {
      emit(current.copyWith(
        friendsLoading:
            kind == SectionKind.friends ? isLoading : current.friendsLoading,
        receivedRequestsLoading: kind == SectionKind.receivedRequests
            ? isLoading
            : current.receivedRequestsLoading,
        // Clear error khi bắt đầu retry.
        friendsError: kind == SectionKind.friends && isLoading
            ? null
            : current.friendsError,
        receivedRequestsError: kind == SectionKind.receivedRequests && isLoading
            ? null
            : current.receivedRequestsError,
      ));
      return;
    }

    // Chuyển từ Initial/Loading/Error → Loaded(rỗng) để có thể track
    // loading per-section. Preserve lại dữ liệu đã load trước đó nếu có.
    final prev = current;
    final base = prev is FriendListLoaded ? prev : null;
    emit(FriendListLoaded(
      friends: base?.friends ?? const [],
      receivedRequests: base?.receivedRequests ?? const [],
      sentRequests: base?.sentRequests ?? const [],
      unreadRequestCount: base?.unreadRequestCount ?? 0,
      notes: base?.notes ?? const [],
      privacySettings: base?.privacySettings,
      myReports: base?.myReports ?? const [],
      friendsLoading: kind == SectionKind.friends ? isLoading : false,
      receivedRequestsLoading:
          kind == SectionKind.receivedRequests ? isLoading : false,
      friendsError: kind == SectionKind.friends && isLoading
          ? null
          : base?.friendsError,
      receivedRequestsError: kind == SectionKind.receivedRequests && isLoading
          ? null
          : base?.receivedRequestsError,
      friendsEverLoaded: base?.friendsEverLoaded ?? false,
      receivedRequestsEverLoaded: base?.receivedRequestsEverLoaded ?? false,
    ));
  }

  /// Set error cho 1 section, giữ nguyên dữ liệu đã load (nếu có).
  /// Đây là fix chính cho bug "chuyển tab bị trắng màn hình":
  /// trước đây `_emitError` emit `FriendListError` tổng → phá hủy mọi
  /// dữ liệu; bây giờ ta chỉ đánh dấu section nào bị lỗi.
  void _emitSectionError(SectionKind kind, String message) {
    final current = state;
    final prev = current is FriendListLoaded ? current : null;
    if (prev != null) {
      emit(prev.copyWith(
        friendsLoading:
            kind == SectionKind.friends ? false : prev.friendsLoading,
        receivedRequestsLoading: kind == SectionKind.receivedRequests
            ? false
            : prev.receivedRequestsLoading,
        friendsError:
            kind == SectionKind.friends ? message : prev.friendsError,
        receivedRequestsError: kind == SectionKind.receivedRequests
            ? message
            : prev.receivedRequestsError,
      ));
    } else {
      // State chưa từng có FriendListLoaded (Initial/Loading) → vẫn
      // tạo FriendListLoaded(rỗng) với error để UI hiển thị retry button.
      emit(FriendListLoaded(
        friendsError:
            kind == SectionKind.friends ? message : null,
        receivedRequestsError:
            kind == SectionKind.receivedRequests ? message : null,
      ));
    }
  }

  // ─── Friends ────────────────────────────────────────────────────────────────

  Future<void> loadFriends() async {
    if (isClosed) return;
    _setSectionLoading(SectionKind.friends, true);

    final result = await repository.getFriendsWithActivity();
    if (isClosed) return;

    result.fold(
      (failure) {
        _setSectionLoading(SectionKind.friends, false);
        _emitSectionError(SectionKind.friends, failure.message);
      },
      (data) {
        final current = state;
        final prev = current is FriendListLoaded ? current : null;
        emit(FriendListLoaded(
          friends: data,
          receivedRequests: prev?.receivedRequests ?? const [],
          sentRequests: prev?.sentRequests ?? const [],
          unreadRequestCount: prev?.unreadRequestCount ?? 0,
          notes: prev?.notes ?? const [],
          privacySettings: prev?.privacySettings,
          myReports: prev?.myReports ?? const [],
          friendsLoading: false,
          receivedRequestsLoading: prev?.receivedRequestsLoading ?? false,
          friendsError: null,
          receivedRequestsError: prev?.receivedRequestsError,
          friendsEverLoaded: true,
          receivedRequestsEverLoaded: prev?.receivedRequestsEverLoaded ?? false,
        ));
      },
    );
  }

  Future<void> refreshFriends() => loadFriends();

  // ─── Friend Requests ───────────────────────────────────────────────────────

  Future<void> loadReceivedRequests() async {
    if (isClosed) return;
    _setSectionLoading(SectionKind.receivedRequests, true);

    final result = await repository.getReceivedRequests();
    if (isClosed) return;

    result.fold(
      (failure) {
        _setSectionLoading(SectionKind.receivedRequests, false);
        _emitSectionError(SectionKind.receivedRequests, failure.message);
      },
      (data) {
        final current = state;
        final prev = current is FriendListLoaded ? current : null;
        emit(FriendListLoaded(
          friends: prev?.friends ?? const [],
          receivedRequests: data,
          sentRequests: prev?.sentRequests ?? const [],
          unreadRequestCount: data.where((r) => !r.isRead).length,
          notes: prev?.notes ?? const [],
          privacySettings: prev?.privacySettings,
          myReports: prev?.myReports ?? const [],
          friendsLoading: prev?.friendsLoading ?? false,
          receivedRequestsLoading: false,
          friendsError: prev?.friendsError,
          receivedRequestsError: null,
          friendsEverLoaded: prev?.friendsEverLoaded ?? false,
          receivedRequestsEverLoaded: true,
        ));
      },
    );
  }

  Future<void> refreshReceivedRequests() => loadReceivedRequests();

  Future<void> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    final currentState = state;
    final result = await repository.sendFriendRequest(
      addresseeId: addresseeId,
      message: message,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        // Lỗi mutation không được phá hủy state hiện tại.
        // UI sẽ tự hiển thị SnackBar lỗi qua SearchUsersTab.
        // Nếu chưa có FriendListLoaded (Initial) → emit action state.
        if (currentState is! FriendListLoaded) {
          emit(FriendRequestSent(addresseeId: addresseeId));
        }
        // Không emit FriendListError tổng — giữ nguyên FriendListLoaded.
      },
      (request) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            sentRequests: [...currentState.sentRequests, request],
          ));
        } else {
          emit(FriendRequestSent(addresseeId: addresseeId));
        }
      },
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final currentState = state;
    final result = await repository.acceptFriendRequest(requestId);

    if (isClosed) return;
    result.fold(
      (failure) {
        // Lỗi mutation không phá hủy FriendListLoaded.
        if (currentState is! FriendListLoaded) {
          emit(FriendRequestProcessed(
            requestId: requestId,
            accepted: true,
          ));
        }
      },
      (_) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(
            requestId: requestId,
            accepted: true,
          ));
        }
      },
    );
  }

  Future<void> declineFriendRequest(String requestId) async {
    final currentState = state;
    final result = await repository.declineFriendRequest(requestId);

    if (isClosed) return;
    result.fold(
      (failure) {
        if (currentState is! FriendListLoaded) {
          emit(FriendRequestProcessed(
            requestId: requestId,
            accepted: false,
          ));
        }
      },
      (_) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(
            requestId: requestId,
            accepted: false,
          ));
        }
      },
    );
  }

  Future<void> markRequestAsRead(String requestId) async {
    await repository.markRequestAsRead(requestId);

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

  // ─── Friend Actions ─────────────────────────────────────────────────────────

  Future<void> unfriend(String friendId) async {
    final currentState = state;
    final result = await repository.unfriend(friendId);

    if (isClosed) return;
    result.fold(
      (failure) {
        if (currentState is! FriendListLoaded) {
          emit(FriendUnfriended(friendId: friendId));
        }
      },
      (_) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            friends:
                currentState.friends.where((f) => f.odId != friendId).toList(),
          ));
        } else {
          emit(FriendUnfriended(friendId: friendId));
        }
      },
    );
  }

  Future<void> blockUser(String userId) async {
    final result = await repository.blockUser(userId);

    if (isClosed) return;
    await result.fold(
      (failure) async {
        // Lỗi mutation: không phá hủy state, để UI hiển thị SnackBar.
      },
      (_) async {
        await loadFriends();
        if (isClosed) return;
        await loadReceivedRequests();
      },
    );
  }

  // ─── Search Users ──────────────────────────────────────────────────────────

  Future<List<UserSearchEntity>> searchUsers(String query) async {
    if (query.trim().isEmpty) return const [];
    final result = await repository.searchUsers(query: query.trim());
    return result.fold((failure) => const [], (data) => data);
  }

  // ─── Notes ─────────────────────────────────────────────────────────────────

  Future<void> loadNotes() async {
    if (isClosed) return;
    final result = await repository.getAllNotes();
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi load notes: không phá hủy state.
      },
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
    final result = await repository.upsertNote(
      friendUserId: friendUserId,
      alias: alias,
      note: note,
      tags: tags,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi mutation: không phá hủy FriendListLoaded.
      },
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
          emit(FriendNoteSaved(note: savedNote));
        }
      },
    );
  }

  Future<void> deleteNote(String noteId) async {
    if (isClosed) return;
    final result = await repository.deleteNote(noteId);
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi mutation: không phá hủy FriendListLoaded.
      },
      (_) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            notes: currentState.notes.where((n) => n.noteId != noteId).toList(),
          ));
        } else {
          emit(FriendNoteDeleted(noteId: noteId));
        }
      },
    );
  }

  // ─── Privacy ───────────────────────────────────────────────────────────────

  Future<void> loadPrivacySettings() async {
    if (isClosed) return;
    final result = await repository.getPrivacySettings();
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi load privacy: không phá hủy state.
      },
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
    final result = await repository.updatePrivacySettings(
      isFriendListPublic: isFriendListPublic,
      acceptFriendRequestsFrom: acceptFriendRequestsFrom,
      friendLimit: friendLimit,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi mutation: không phá hủy state.
      },
      (privacy) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(privacySettings: privacy));
        } else {
          emit(FriendPrivacyUpdated(privacy: privacy));
        }
      },
    );
  }

  // ─── Reports ───────────────────────────────────────────────────────────────

  Future<void> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) async {
    if (isClosed) return;
    final result = await repository.createReport(
      targetUserId: targetUserId,
      category: category,
      reason: reason,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi mutation: không phá hủy state.
      },
      (_) => emit(FriendReportCreated(targetUserId: targetUserId)),
    );
  }

  Future<void> loadMyReports() async {
    if (isClosed) return;
    final result = await repository.getMyReports();
    if (isClosed) return;

    result.fold(
      (failure) {
        // Lỗi load reports: không phá hủy state.
      },
      (reports) {
        final currentState = state;
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(myReports: reports));
        }
      },
    );
  }
}

/// Alias for FriendListState for backward compatibility.
typedef FriendListState = FriendListData;
