import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/friend_repository.dart';
import 'states/friend_profile_states.dart';

/// Cubit for managing friend profile state.
///
/// Handles:
/// - Loading player profile (`/friends/{userId}/profile`)
/// - Reloading after relationship changes (send request, unfriend, block/unblock)
/// - Loading mutual friends list
/// - Action message handling
class FriendProfileCubit extends Cubit<FriendProfileState> {
  FriendProfileCubit({required FriendRepository repository})
      : _repository = repository,
        super(const FriendProfileInitial(userId: ''));

  final FriendRepository _repository;

  String? get currentUserId {
    final id = state.userId;
    return id.isEmpty ? null : id;
  }

  Future<void> loadProfile(String userId) async {
    if (userId.isEmpty) {
      emit(FriendProfileError(
        userId: userId,
        message: 'Thiếu userId — không thể tải hồ sơ.',
      ));
      return;
    }

    if (state is! FriendProfileLoaded) {
      emit(FriendProfileLoading(userId: userId));
    } else {
      final current = state as FriendProfileLoaded;
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }

    final result = await _repository.getPlayerProfile(userId);
    if (isClosed) return;

    result.fold(
      (failure) {
        final previous = state;
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: previous is FriendProfileLoaded
              ? previous.profile
              : (previous is FriendProfileError ? previous.profile : null),
        ));
      },
      (profile) => emit(FriendProfileLoaded(userId: userId, profile: profile)),
    );
  }

  Future<void> refresh() async {
    final userId = currentUserId;
    if (userId == null) return;
    await loadProfile(userId);
  }

  Future<void> sendFriendRequest({String? message}) async {
    final userId = currentUserId;
    if (userId == null) return;

    _setMutating(true);

    final result = await _repository.sendFriendRequest(
      addresseeId: userId,
      message: message,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: _currentProfile,
        ));
      },
      (_) async {
        await loadProfile(userId);
        if (isClosed) return;
        final next = state;
        if (next is FriendProfileLoaded) {
          emit(next.copyWith(actionMessage: 'Đã gửi lời mời kết bạn.'));
        }
      },
    );
  }

  Future<void> unfriend() async {
    final userId = currentUserId;
    if (userId == null) return;

    _setMutating(true);

    final result = await _repository.unfriend(userId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: _currentProfile,
        ));
      },
      (_) async {
        await loadProfile(userId);
        if (isClosed) return;
        final next = state;
        if (next is FriendProfileLoaded) {
          emit(next.copyWith(actionMessage: 'Đã hủy kết bạn.'));
        }
      },
    );
  }

  Future<void> blockUser() async {
    final userId = currentUserId;
    if (userId == null) return;

    _setMutating(true);

    final result = await _repository.blockUser(userId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: _currentProfile,
        ));
      },
      (_) async {
        await loadProfile(userId);
        if (isClosed) return;
        final next = state;
        if (next is FriendProfileLoaded) {
          emit(next.copyWith(actionMessage: 'Đã chặn người chơi.'));
        }
      },
    );
  }

  Future<void> unblockUser() async {
    final userId = currentUserId;
    if (userId == null) return;

    _setMutating(true);

    final result = await _repository.unblockUser(userId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: _currentProfile,
        ));
      },
      (_) async {
        await loadProfile(userId);
        if (isClosed) return;
        final next = state;
        if (next is FriendProfileLoaded) {
          emit(next.copyWith(actionMessage: 'Đã bỏ chặn người chơi.'));
        }
      },
    );
  }

  Future<void> report({
    required String category,
    required String reason,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    _setMutating(true);

    final result = await _repository.createReport(
      targetUserId: userId,
      category: category,
      reason: reason,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(FriendProfileError(
          userId: userId,
          message: failure.message,
          profile: _currentProfile,
        ));
      },
      (_) async {
        if (isClosed) return;
        final next = state;
        if (next is FriendProfileLoaded) {
          emit(next.copyWith(
            isMutating: false,
            actionMessage: 'Đã gửi báo cáo.',
          ));
        }
      },
    );
  }

  Future<void> loadMutualFriends() async {
    final userId = currentUserId;
    if (userId == null) return;

    final result = await _repository.getMutualFriends(userId);
    if (isClosed) return;

    result.fold(
      (failure) {
        final current = state;
        if (current is FriendProfileLoaded) {
          emit(current.copyWith(actionMessage: failure.message));
        }
      },
      (mutual) {
        final current = state;
        if (current is FriendProfileLoaded) {
          emit(current.copyWith(
            mutualFriends: mutual
                .map((f) => MutualFriendSummary(
                      userId: f.odId,
                      username: f.username,
                      avatarUrl: f.avatarUrl,
                    ))
                .toList(),
          ));
        }
      },
    );
  }

  void clearActionMessage() {
    final current = state;
    if (current is FriendProfileLoaded && current.actionMessage != null) {
      emit(current.copyWith(clearActionMessage: true));
    }
  }

  void _setMutating(bool isMutating) {
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: isMutating, clearActionMessage: true));
    }
  }

  FriendProfileEntity? get _currentProfile {
    final current = state;
    if (current is FriendProfileLoaded) return current.profile;
    if (current is FriendProfileError) return current.profile;
    return null;
  }
}
