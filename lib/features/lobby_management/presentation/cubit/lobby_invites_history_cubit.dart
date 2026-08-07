import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lobby_invite_entity.dart';
import '../../domain/repositories/lobby_repository.dart';

/// State cho `LobbyInvitesHistoryCubit` — load lịch sử invite của 1 lobby
/// cụ thể (host view "Lời mời tôi đã gửi").
class LobbyInvitesHistoryState extends Equatable {
  /// Lobby ID đang xem.
  final String? lobbyId;

  /// Status filter hiện tại.
  final LobbyInviteStatus? statusFilter;

  /// Loading lần đầu.
  final bool isInitialLoading;

  /// Loading refresh / filter change.
  final bool isRefreshing;

  /// Loading cho action (resend).
  final String? actionInviteId;

  /// Error message nếu có.
  final String? errorMessage;

  /// Danh sách invites.
  final List<LobbyInviteEntity> invites;

  const LobbyInvitesHistoryState({
    this.lobbyId,
    this.statusFilter,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.actionInviteId,
    this.errorMessage,
    this.invites = const [],
  });

  bool get hasData => invites.isNotEmpty;
  bool get isEmpty => !isInitialLoading && !isRefreshing && invites.isEmpty;

  /// Count theo từng status — dùng cho tabs.
  int get totalCount => invites.length;

  int pendingCount(int fullLength) => invites
      .where((i) => i.status == LobbyInviteStatus.pending)
      .length;
  int acceptedCount(int fullLength) => invites
      .where((i) => i.status == LobbyInviteStatus.accepted)
      .length;
  int declinedCount(int fullLength) => invites
      .where((i) => i.status == LobbyInviteStatus.declined)
      .length;
  int cancelledCount(int fullLength) => invites
      .where((i) => i.status == LobbyInviteStatus.cancelled)
      .length;
  int expiredCount(int fullLength) => invites
      .where((i) => i.status == LobbyInviteStatus.expired)
      .length;

  LobbyInvitesHistoryState copyWith({
    String? lobbyId,
    LobbyInviteStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? actionInviteId,
    bool clearActionInviteId = false,
    String? errorMessage,
    bool clearError = false,
    List<LobbyInviteEntity>? invites,
  }) {
    return LobbyInvitesHistoryState(
      lobbyId: lobbyId ?? this.lobbyId,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionInviteId: clearActionInviteId
          ? null
          : (actionInviteId ?? this.actionInviteId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      invites: invites ?? this.invites,
    );
  }

  @override
  List<Object?> get props => [
    lobbyId,
    statusFilter,
    isInitialLoading,
    isRefreshing,
    actionInviteId,
    errorMessage,
    invites,
  ];
}

/// Cubit load lịch sử invite của 1 lobby + filter theo status + resend action.
class LobbyInvitesHistoryCubit extends Cubit<LobbyInvitesHistoryState> {
  final LobbyRepository _repository;

  LobbyInvitesHistoryCubit({required LobbyRepository repository})
    // ignore: prefer_initializing_formals
    : _repository = repository,
      super(const LobbyInvitesHistoryState());

  /// Lần load đầu (initial loading screen).
  Future<void> loadHistory(String lobbyId, {LobbyInviteStatus? status}) async {
    emit(state.copyWith(
      lobbyId: lobbyId,
      statusFilter: status,
      isInitialLoading: true,
      clearError: true,
    ));

    final result = await _repository.getLobbyInvites(
      lobbyId: lobbyId,
      status: status,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isInitialLoading: false,
        errorMessage: failure.message,
      )),
      (invites) => emit(state.copyWith(
        isInitialLoading: false,
        invites: invites,
      )),
    );
  }

  /// Refresh (pull-to-refresh) — giữ nguyên filter hiện tại.
  Future<void> refresh() async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    emit(state.copyWith(isRefreshing: true, clearError: true));

    final result = await _repository.getLobbyInvites(
      lobbyId: lobbyId,
      status: state.statusFilter,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (invites) => emit(state.copyWith(
        isRefreshing: false,
        invites: invites,
      )),
    );
  }

  /// Đổi filter → reload.
  Future<void> changeFilter(LobbyInviteStatus? status) async {
    final lobbyId = state.lobbyId;
    if (lobbyId == null) return;

    emit(state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      isRefreshing: true,
      clearError: true,
    ));

    final result = await _repository.getLobbyInvites(
      lobbyId: lobbyId,
      status: status,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        errorMessage: failure.message,
      )),
      (invites) => emit(state.copyWith(
        isRefreshing: false,
        invites: invites,
      )),
    );
  }

  /// Resend một invite (Declined/Expired/Cancelled).
  Future<bool> resendInvite(String inviteId) async {
    emit(state.copyWith(actionInviteId: inviteId, clearError: true));

    final result = await _repository.resendInvite(inviteId);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          clearActionInviteId: true,
          errorMessage: failure.message,
        ));
        return false;
      },
      (newInvite) {
        // Thay invite cũ bằng invite mới trong list.
        final updated = state.invites
            .map((i) => i.inviteId == inviteId ? newInvite : i)
            .toList();
        emit(state.copyWith(
          clearActionInviteId: true,
          invites: updated,
        ));
        return true;
      },
    );
  }

  /// Cancel một invite đã gửi (chỉ áp dụng cho pending).
  Future<bool> cancelInvite(String inviteId) async {
    emit(state.copyWith(actionInviteId: inviteId, clearError: true));

    final result = await _repository.cancelLobbyInvite(inviteId);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          clearActionInviteId: true,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        // Xoá khỏi list.
        final updated = state.invites
            .where((i) => i.inviteId != inviteId)
            .toList();
        emit(state.copyWith(
          clearActionInviteId: true,
          invites: updated,
        ));
        return true;
      },
    );
  }

  /// Clear error (sau khi show snackbar).
  void clearError() => emit(state.copyWith(clearError: true));
}