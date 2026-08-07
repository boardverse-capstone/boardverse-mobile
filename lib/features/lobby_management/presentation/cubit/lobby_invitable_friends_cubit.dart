import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lobby_invite_entity.dart';
import '../../domain/entities/lobby_invitable_friend.dart';
import '../../domain/repositories/lobby_repository.dart';

/// State cho cubit load danh sách friend có thể mời vào lobby.
class LobbyInvitableFriendsState extends Equatable {
  /// Lobby ID đang load friends.
  final String? lobbyId;

  /// Search keyword hiện tại.
  final String search;

  /// Chỉ hiển thị online.
  final bool onlineOnly;

  /// Min karma filter.
  final int? minKarma;

  /// Loading lần đầu.
  final bool isInitialLoading;

  /// Loading refresh / search.
  final bool isRefreshing;

  /// Loading cho invite action (per invitee).
  final String? sendingInviteId;

  /// Loading cho cancel action (per invitee).
  final String? cancellingInviteId;

  /// Loading cho resend action (per invitee).
  final String? resendingInviteId;

  /// Error message.
  final String? errorMessage;

  /// Success message (vd: "Đã gửi lời mời").
  final String? successMessage;

  /// Danh sách friends.
  final List<LobbyInvitableFriend> friends;

  const LobbyInvitableFriendsState({
    this.lobbyId,
    this.search = '',
    this.onlineOnly = false,
    this.minKarma,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.sendingInviteId,
    this.cancellingInviteId,
    this.resendingInviteId,
    this.errorMessage,
    this.successMessage,
    this.friends = const [],
  });

  bool get hasData => friends.isNotEmpty;
  bool get isEmpty => !isInitialLoading && !isRefreshing && friends.isEmpty;

  LobbyInvitableFriendsState copyWith({
    String? lobbyId,
    String? search,
    bool? onlineOnly,
    int? minKarma,
    bool clearMinKarma = false,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? sendingInviteId,
    bool clearSendingInviteId = false,
    String? cancellingInviteId,
    bool clearCancellingInviteId = false,
    String? resendingInviteId,
    bool clearResendingInviteId = false,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    List<LobbyInvitableFriend>? friends,
  }) {
    return LobbyInvitableFriendsState(
      lobbyId: lobbyId ?? this.lobbyId,
      search: search ?? this.search,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      minKarma: clearMinKarma ? null : (minKarma ?? this.minKarma),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sendingInviteId: clearSendingInviteId
          ? null
          : (sendingInviteId ?? this.sendingInviteId),
      cancellingInviteId: clearCancellingInviteId
          ? null
          : (cancellingInviteId ?? this.cancellingInviteId),
      resendingInviteId: clearResendingInviteId
          ? null
          : (resendingInviteId ?? this.resendingInviteId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      friends: friends ?? this.friends,
    );
  }

  @override
  List<Object?> get props => [
    lobbyId,
    search,
    onlineOnly,
    minKarma,
    isInitialLoading,
    isRefreshing,
    sendingInviteId,
    cancellingInviteId,
    resendingInviteId,
    errorMessage,
    successMessage,
    friends,
  ];
}

/// Cubit load danh sách friend có thể mời + actions (invite/cancel/resend).
class LobbyInvitableFriendsCubit
    extends Cubit<LobbyInvitableFriendsState> {
  final LobbyRepository _repository;

  LobbyInvitableFriendsCubit({required LobbyRepository repository})
    // ignore: prefer_initializing_formals
    : _repository = repository,
      super(const LobbyInvitableFriendsState());

  /// Initial load.
  Future<void> loadFriends(String lobbyId) async {
    emit(state.copyWith(
      lobbyId: lobbyId,
      isInitialLoading: true,
      clearError: true,
    ));

    final result = await _fetch(lobbyId);

    result.fold(
      (failure) => emit(state.copyWith(
        isInitialLoading: false,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        isInitialLoading: false,
        friends: list,
      )),
    );
  }

  /// Refresh (pull-to-refresh).
  Future<void> refresh() async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _fetch(lobbyId);

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        isRefreshing: false,
        friends: list,
      )),
    );
  }

  Future<dynamic> _fetch(String lobbyId) {
    return _repository.getInvitableFriends(
      lobbyId: lobbyId,
      search: state.search.trim().isEmpty ? null : state.search.trim(),
      onlineOnly: state.onlineOnly,
      minKarma: state.minKarma,
      statusFilter: const [],
    );
  }

  /// Search keyword đổi → reload.
  Future<void> search(String keyword) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    emit(state.copyWith(search: keyword, isRefreshing: true));
    final result = await _fetch(lobbyId);

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        isRefreshing: false,
        friends: list,
      )),
    );
  }

  /// Toggle online-only filter.
  Future<void> toggleOnlineOnly() async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    final newValue = !state.onlineOnly;
    emit(state.copyWith(
      onlineOnly: newValue,
      isRefreshing: true,
    ));
    final result = await _fetch(lobbyId);

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        isRefreshing: false,
        friends: list,
      )),
    );
  }

  /// Set min karma filter.
  Future<void> setMinKarma(int? value) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    emit(state.copyWith(
      minKarma: value,
      clearMinKarma: value == null,
      isRefreshing: true,
    ));
    final result = await _fetch(lobbyId);

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (list) => emit(state.copyWith(
        isRefreshing: false,
        friends: list,
      )),
    );
  }

  /// Gửi invite mới (Invitable → InvitePending).
  Future<bool> sendInvite(String inviteeId) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return false;

    emit(state.copyWith(sendingInviteId: inviteeId, clearError: true));

    final result = await _repository.sendLobbyInvite(
      lobbyId: lobbyId,
      inviteeId: inviteeId,
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          clearSendingInviteId: true,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        // Update friend state trong list thành InvitePending.
        final updated = state.friends
            .map(
              (f) => f.userId == inviteeId
                  ? LobbyInvitableFriend(
                      userId: f.userId,
                      username: f.username,
                      avatarUrl: f.avatarUrl,
                      karmaPoints: f.karmaPoints,
                      gamerTier: f.gamerTier,
                      activityStatus: f.activityStatus,
                      lastActiveAt: f.lastActiveAt,
                      friendsSince: f.friendsSince,
                      inviteStatus: LobbyInviteFriendStatus.invitePending,
                      latestInviteId: f.latestInviteId,
                      latestInviteStatus: LobbyInviteStatus.pending,
                      isInLobby: f.isInLobby,
                      hasPendingInvite: true,
                      isBlocked: f.isBlocked,
                    )
                  : f,
            )
            .toList();
        emit(state.copyWith(
          clearSendingInviteId: true,
          friends: updated,
          successMessage: 'Đã gửi lời mời',
        ));
        return true;
      },
    );
  }

  /// Cancel pending invite (cần inviteId từ latestInviteId).
  Future<bool> cancelInvite(String inviteeId) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return false;

    final friend = state.friends.firstWhere(
      (f) => f.userId == inviteeId,
      orElse: () => state.friends.first,
    );
    final inviteId = friend.latestInviteId;
    if (inviteId == null || inviteId.isEmpty) {
      emit(state.copyWith(errorMessage: 'Không tìm thấy invite để huỷ.'));
      return false;
    }

    emit(state.copyWith(cancellingInviteId: inviteeId, clearError: true));

    final result = await _repository.cancelLobbyInvite(inviteId);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          clearCancellingInviteId: true,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        // Reload friends list để có trạng thái mới nhất.
        if (lobbyId.isNotEmpty) {
          _repository
              .getInvitableFriends(lobbyId: lobbyId)
              .then((res) => res.fold((_) {}, (list) {
                if (!isClosed) {
                  emit(state.copyWith(
                    clearCancellingInviteId: true,
                    friends: list,
                    successMessage: 'Đã huỷ lời mời',
                  ));
                }
              }));
        }
        return true;
      },
    );
  }

  /// Resend invite cũ (terminal state).
  Future<bool> resendInvite(String inviteeId) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return false;

    final friend = state.friends.firstWhere(
      (f) => f.userId == inviteeId,
      orElse: () => state.friends.first,
    );
    final inviteId = friend.latestInviteId;
    if (inviteId == null || inviteId.isEmpty) {
      emit(state.copyWith(errorMessage: 'Không tìm thấy invite để gửi lại.'));
      return false;
    }

    emit(state.copyWith(resendingInviteId: inviteeId, clearError: true));

    final result = await _repository.resendInvite(inviteId);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          clearResendingInviteId: true,
          errorMessage: failure.message,
        ));
        return false;
      },
      (newInvite) {
        // Reload list để có trạng thái mới nhất.
        _repository.getInvitableFriends(lobbyId: lobbyId).then(
          (res) => res.fold((_) {}, (list) {
            if (!isClosed) {
              emit(state.copyWith(
                clearResendingInviteId: true,
                friends: list,
                successMessage: 'Đã gửi lại lời mời',
              ));
            }
          }),
        );
        // ignore: avoid_print
        print('resendInvite ok inviteId=${newInvite.inviteId}');
        return true;
      },
    );
  }

  void clearError() => emit(state.copyWith(clearError: true));
  void clearSuccess() => emit(state.copyWith(clearSuccess: true));
}