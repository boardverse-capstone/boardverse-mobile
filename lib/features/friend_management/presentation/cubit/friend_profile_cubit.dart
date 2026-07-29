import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/friend_repository.dart';
import 'friend_profile_state.dart';

/// Cubit cho màn hình Friend Profile.
///
/// Quản lý:
/// - Load profile của 1 player (`/friends/{userId}/profile`).
/// - Reload khi có action thay đổi quan hệ (gửi lời mời / unfriend /
///   block / unblock) để cập nhật `friendshipStatus` + permission flags.
/// - Load thêm mutual friends nếu người dùng muốn xem đầy đủ.
///
/// **userId contract:** Mọi state do cubit này emit đều mang `userId` để
/// UI/retry/action luôn biết đang thao tác trên profile của ai (kể cả
/// khi `profile == null` trong [FriendProfileError]). Tránh bug "empty
/// userId" khiến endpoint dạng `/friends/{userId}/...` bị 405.
class FriendProfileCubit extends Cubit<FriendProfileState> {
  FriendProfileCubit({required this._repository})
      : super(const FriendProfileInitial(userId: ''));

  final FriendRepository _repository;

  /// Trả về `userId` hiện tại từ state (luôn có sau khi `loadProfile`).
  /// Ưu tiên đọc từ state thay vì cache private để đảm bảo consistency.
  String? get currentUserId {
    final id = state.userId;
    return id.isEmpty ? null : id;
  }

  /// Tải profile. Nếu đã load rồi thì gọi lại sẽ reload (refresh).
  Future<void> loadProfile(String userId) async {
    if (userId.isEmpty) {
      // Defensive: tránh gọi API với empty userId (gây 405).
      emit(FriendProfileError(
        userId: userId,
        message: 'Thiếu userId — không thể tải hồ sơ.',
      ));
      return;
    }
    if (state is! FriendProfileLoaded) {
      emit(FriendProfileLoading(userId: userId));
    } else {
      // Giữ state Loaded, chỉ flag mutating (refresh in-place).
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

  /// Gọi lại `getPlayerProfile` để refresh (giữ page hiện tại).
  Future<void> refresh() async {
    final userId = currentUserId;
    if (userId == null) return;
    await loadProfile(userId);
  }

  /// Gửi lời mời kết bạn → reload profile.
  Future<void> sendFriendRequest({String? message}) async {
    final userId = currentUserId;
    if (userId == null) return;
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }
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
          emit(next.copyWith(
            actionMessage: 'Đã gửi lời mời kết bạn.',
          ));
        }
      },
    );
  }

  /// Hủy kết bạn → reload profile.
  Future<void> unfriend() async {
    final userId = currentUserId;
    if (userId == null) return;
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }
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

  /// Chặn user → reload profile (sẽ thấy `isBlockedByMe = true`).
  Future<void> blockUser() async {
    final userId = currentUserId;
    if (userId == null) return;
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }
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

  /// Bỏ chặn → reload profile.
  Future<void> unblockUser() async {
    final userId = currentUserId;
    if (userId == null) return;
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }
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
    final current = state;
    if (current is FriendProfileLoaded) {
      emit(current.copyWith(isMutating: true, clearActionMessage: true));
    }
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

  /// Người dùng mở rộng mutual list → load full list và lưu vào state.
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

  /// Xóa transient snackbar message sau khi UI đã consume.
  void clearActionMessage() {
    final current = state;
    if (current is FriendProfileLoaded && current.actionMessage != null) {
      emit(current.copyWith(clearActionMessage: true));
    }
  }

  FriendProfileEntity? get _currentProfile {
    final current = state;
    if (current is FriendProfileLoaded) return current.profile;
    if (current is FriendProfileError) return current.profile;
    return null;
  }
}
