import 'package:equatable/equatable.dart';

import '../../domain/entities/lobby_invite_entity.dart';

sealed class LobbyInviteState extends Equatable {
  const LobbyInviteState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu.
class LobbyInviteInitial extends LobbyInviteState {
  const LobbyInviteInitial();
}

/// Đang tải danh sách lời mời.
class LobbyInviteLoading extends LobbyInviteState {
  const LobbyInviteLoading();
}

/// Danh sách lời mời đã tải thành công.
class LobbyInviteLoaded extends LobbyInviteState {
  final List<LobbyInviteEntity> pendingInvites;
  final List<LobbyInviteEntity> allInvites;

  const LobbyInviteLoaded({
    required this.pendingInvites,
    this.allInvites = const [],
  });

  @override
  List<Object?> get props => [pendingInvites, allInvites];
}

/// Empty state - không có lời mời nào.
class LobbyInviteEmpty extends LobbyInviteState {
  const LobbyInviteEmpty();
}

/// Đang xử lý action (accept/decline/cancel).
class LobbyInviteActionLoading extends LobbyInviteState {
  final String inviteId;
  final List<LobbyInviteEntity> pendingInvites;
  final List<LobbyInviteEntity> allInvites;

  const LobbyInviteActionLoading({
    required this.inviteId,
    required this.pendingInvites,
    this.allInvites = const [],
  });

  @override
  List<Object?> get props => [inviteId, pendingInvites, allInvites];
}

/// Invite đã được accept thành công - navigate tới lobby.
class LobbyInviteAccepted extends LobbyInviteState {
  final LobbyInviteEntity invite;
  final String lobbyId;

  const LobbyInviteAccepted({
    required this.invite,
    required this.lobbyId,
  });

  @override
  List<Object?> get props => [invite, lobbyId];
}

/// Invite đã được decline thành công.
class LobbyInviteDeclined extends LobbyInviteState {
  final String inviteId;

  const LobbyInviteDeclined({required this.inviteId});

  @override
  List<Object?> get props => [inviteId];
}

/// Invite đã được cancel thành công.
class LobbyInviteCancelled extends LobbyInviteState {
  final String inviteId;

  const LobbyInviteCancelled({required this.inviteId});

  @override
  List<Object?> get props => [inviteId];
}

/// Lỗi xảy ra.
class LobbyInviteError extends LobbyInviteState {
  final String message;
  final List<LobbyInviteEntity> pendingInvites;
  final List<LobbyInviteEntity> allInvites;

  const LobbyInviteError({
    required this.message,
    this.pendingInvites = const [],
    this.allInvites = const [],
  });

  @override
  List<Object?> get props => [message, pendingInvites, allInvites];
}
