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
  Future<void> acceptInvite(String inviteId) async {
    final currentInvites = _pendingInvites.toList();
    emit(LobbyInviteActionLoading(
      inviteId: inviteId,
      pendingInvites: currentInvites,
      allInvites: _allInvites,
    ));

    final result = await _remoteDatasource.acceptInvite(inviteId);

    result.fold(
      (failure) => emit(LobbyInviteError(
        message: failure.message,
        pendingInvites: currentInvites,
        allInvites: _allInvites,
      )),
      (lobby) {
        _pendingInvites.removeWhere((i) => i.inviteId == inviteId);
        emit(LobbyInviteAccepted(
          invite: currentInvites.firstWhere((i) => i.inviteId == inviteId),
          lobbyId: lobby.id,
        ));
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
