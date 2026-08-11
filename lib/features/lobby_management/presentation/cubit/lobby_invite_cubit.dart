import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/base/lobby_remote_datasource.dart';
import '../../domain/entities/lobby_invite_entity.dart';
import 'lobby_invite_state.dart';

class LobbyInviteCubit extends Cubit<LobbyInviteState> {
  final LobbyRemoteDatasource _remoteDatasource;

  List<LobbyInviteEntity> _pendingInvites = [];
  List<LobbyInviteEntity> _allInvites = [];

  LobbyInviteCubit({required this._remoteDatasource}) : super(const LobbyInviteInitial());

  /// Load pending invites - gọi khi user mở invite inbox.
  Future<void> loadPendingInvites() async {
    emit(const LobbyInviteLoading());

    final result = await _remoteDatasource.getPendingInvites();

    result.fold(
      (failure) => emit(LobbyInviteError(message: failure.message)),
      (invites) {
        _pendingInvites = invites;
        if (invites.isEmpty) {
          emit(const LobbyInviteEmpty());
        } else {
          emit(LobbyInviteLoaded(pendingInvites: invites));
        }
      },
    );
  }

  /// Load all invites với filter status.
  Future<void> loadAllInvites({LobbyInviteStatus? status}) async {
    emit(const LobbyInviteLoading());

    final result = await _remoteDatasource.getAllInvites(status);

    result.fold(
      (failure) => emit(LobbyInviteError(message: failure.message)),
      (invites) {
        _allInvites = invites;
        _pendingInvites = invites
            .where((i) => i.status == LobbyInviteStatus.pending)
            .toList();
        if (invites.isEmpty) {
          emit(const LobbyInviteEmpty());
        } else {
          emit(LobbyInviteLoaded(
            pendingInvites: _pendingInvites,
            allInvites: invites,
          ));
        }
      },
    );
  }

  /// Refresh danh sách invites.
  Future<void> refresh() async {
    await loadPendingInvites();
  }

  /// Accept một lời mời - tự động join lobby.
  ///
  /// Flow:
  /// 1. Emit `LobbyInviteActionLoading` (giữ danh sách cũ để UI không
  ///    "flash" trắng).
  /// 2. Gọi `acceptInvite` ở datasource. Backend trả
  ///    `LobbyInviteResponseDto` (xem `real_lobby_remote_datasource.acceptInvite`).
  /// 3. Nếu success → remove invite khỏi list → emit `LobbyInviteAccepted`
  ///    để BlocConsumer navigate sang LobbyPage.
  /// 4. **Quan trọng**: emit tiếp `LobbyInviteLoaded` / `LobbyInviteEmpty`
  ///    để UI danh sách invite về đúng trạng thái (trước đây chỉ dừng
  ///    ở `LobbyInviteAccepted` → UI "kẹt" phải reload mới thấy invite
  ///    biến mất).
  Future<void> acceptInvite(String inviteId) async {
    final currentInvites = _pendingInvites.toList();
    emit(LobbyInviteActionLoading(
      inviteId: inviteId,
      pendingInvites: currentInvites,
      allInvites: _allInvites,
    ));

    final result = await _remoteDatasource.acceptInvite(inviteId);

    result.fold(
      (failure) {
        // Failure: emit error NHƯNG vẫn giữ danh sách cũ (currentInvites)
        // → UI vẫn hiển thị invite để user retry hoặc thao tác khác.
        emit(LobbyInviteError(
          message: failure.message,
          pendingInvites: currentInvites,
          allInvites: _allInvites,
        ));
      },
      (lobby) {
        // Save invite trước khi remove — dùng cho `LobbyInviteAccepted`.
        final acceptedInvite = currentInvites.firstWhere(
          (i) => i.inviteId == inviteId,
          orElse: () => _emptyInvitePlaceholder,
        );
        _pendingInvites.removeWhere((i) => i.inviteId == inviteId);

        // 1) Emit Accepted để BlocConsumer navigate sang LobbyPage.
        emit(LobbyInviteAccepted(
          invite: acceptedInvite,
          lobbyId: lobby.id,
        ));

        // 2) Emit Loaded / Empty để UI danh sách invite về đúng trạng
        // thái sau khi action xong (nếu chỉ emit Accepted, list UI
        // sẽ "kẹt" cho tới khi user reload).
        if (_pendingInvites.isEmpty) {
          emit(const LobbyInviteEmpty());
        } else {
          emit(LobbyInviteLoaded(
            pendingInvites: List<LobbyInviteEntity>.from(_pendingInvites),
            allInvites: List<LobbyInviteEntity>.from(_allInvites),
          ));
        }
      },
    );
  }

  /// Decline một lời mời.
  Future<void> declineInvite(String inviteId) async {
    final currentInvites = _pendingInvites.toList();
    emit(LobbyInviteActionLoading(
      inviteId: inviteId,
      pendingInvites: currentInvites,
      allInvites: _allInvites,
    ));

    final result = await _remoteDatasource.declineInvite(inviteId);

    result.fold(
      (failure) => emit(LobbyInviteError(
        message: failure.message,
        pendingInvites: currentInvites,
        allInvites: _allInvites,
      )),
      (_) {
        _pendingInvites.removeWhere((i) => i.inviteId == inviteId);
        emit(LobbyInviteDeclined(inviteId: inviteId));
        if (_pendingInvites.isEmpty) {
          emit(const LobbyInviteEmpty());
        } else {
          emit(LobbyInviteLoaded(pendingInvites: _pendingInvites));
        }
      },
    );
  }

  /// Cancel một lời mời đã gửi (host/inviter action).
  Future<void> cancelInvite(String inviteId) async {
    final currentInvites = _allInvites.toList();
    emit(LobbyInviteActionLoading(
      inviteId: inviteId,
      pendingInvites: _pendingInvites,
      allInvites: currentInvites,
    ));

    final result = await _remoteDatasource.cancelInvite(inviteId);

    result.fold(
      (failure) => emit(LobbyInviteError(
        message: failure.message,
        pendingInvites: _pendingInvites,
        allInvites: currentInvites,
      )),
      (_) {
        _allInvites.removeWhere((i) => i.inviteId == inviteId);
        emit(LobbyInviteCancelled(inviteId: inviteId));
        emit(LobbyInviteLoaded(
          pendingInvites: _pendingInvites,
          allInvites: _allInvites,
        ));
      },
    );
  }

  /// Get số lượng pending invites (dùng cho badge).
  int get pendingCount => _pendingInvites.length;
}

/// Fallback `LobbyInviteEntity` dùng khi `acceptInvite` race-condition
/// không tìm thấy invite trong list cũ (vd: UI đã reload giữa chừng).
/// Không nên hiển thị — chỉ dùng làm payload cho `LobbyInviteAccepted`.
final LobbyInviteEntity _emptyInvitePlaceholder = LobbyInviteEntity(
  inviteId: '',
  lobbyId: '',
  inviterId: '',
  inviterName: '',
  inviterAvatar: '',
  inviteeId: '',
  status: LobbyInviteStatus.pending,
  createdAt: _epochStart,
  expiresAt: _epochStart,
  gameName: '',
  cafeName: '',
  currentMembers: 0,
  maxMembers: 0,
);

final DateTime _epochStart = DateTime.fromMillisecondsSinceEpoch(0);
