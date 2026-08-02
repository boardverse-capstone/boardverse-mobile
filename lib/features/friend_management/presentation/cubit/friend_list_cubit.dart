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
class FriendListCubit extends Cubit<FriendListState> {
  FriendListCubit({required this.repository}) : super(const FriendListInitial());

  final FriendRepository repository;

  // ─── Section Loading Helpers ─────────────────────────────────────────────────

  void _setSectionLoading(SectionKind kind, bool isLoading) {
    final current = state;
    if (current is FriendListLoaded) {
      emit(current.copyWith(
        friendsLoading:
            kind == SectionKind.friends ? isLoading : current.friendsLoading,
        receivedRequestsLoading: kind == SectionKind.receivedRequests
            ? isLoading
            : current.receivedRequestsLoading,
      ));
    }
  }

  void _emitError(String message) {
    final current = state;
    if (current is FriendListLoaded) {
      emit(FriendListError(message: message));
    } else {
      emit(FriendListError(message: message));
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
        _emitError(failure.message);
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
        _emitError(failure.message);
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) async => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
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
      (failure) => _emitError(failure.message),
      (_) => emit(FriendReportCreated(targetUserId: targetUserId)),
    );
  }

  Future<void> loadMyReports() async {
    if (isClosed) return;
    final result = await repository.getMyReports();
    if (isClosed) return;

    result.fold(
      (failure) => _emitError(failure.message),
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
