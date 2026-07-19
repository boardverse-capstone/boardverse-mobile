import 'package:equatable/equatable.dart';

import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../../domain/entities/friend_entity.dart';

sealed class LobbyState extends Equatable {
  const LobbyState();

  @override
  List<Object?> get props => [];
}

class LobbyInitial extends LobbyState {
  const LobbyInitial();
}

class LobbyLoading extends LobbyState {
  const LobbyLoading();
}

class LobbyCreated extends LobbyState {
  final LobbyEntity lobby;

  const LobbyCreated({required this.lobby});

  @override
  List<Object?> get props => [lobby];
}

class LobbyUpdatedRealtime extends LobbyState {
  final LobbyEntity lobby;

  const LobbyUpdatedRealtime({required this.lobby});

  @override
  List<Object?> get props => [lobby];
}

class LobbyDismissed extends LobbyState {
  final String title;
  final String message;
  final String reasonCode;

  const LobbyDismissed({
    required this.title,
    required this.message,
    required this.reasonCode,
  });

  @override
  List<Object?> get props => [title, message, reasonCode];
}

class LobbyReady extends LobbyState {
  final LobbyEntity lobby;

  const LobbyReady({required this.lobby});

  @override
  List<Object?> get props => [lobby];
}

/// Danh sách bạn bè online — dùng cho flow MỜI THỰC (gửi notification).
class LobbyFriendsLoaded extends LobbyState {
  final List<FriendEntity> friends;
  final LobbyEntity lobby;

  const LobbyFriendsLoaded({required this.friends, required this.lobby});

  @override
  List<Object?> get props => [friends, lobby];
}

/// Danh sách bạn bè online — dùng cho flow GIẢ LẬP (thêm thẳng vào lobby).
class LobbySimulateFriendsLoaded extends LobbyState {
  final List<FriendEntity> friends;
  final LobbyEntity lobby;

  const LobbySimulateFriendsLoaded({
    required this.friends,
    required this.lobby,
  });

  @override
  List<Object?> get props => [friends, lobby];
}

class LobbyFailure extends LobbyState {
  final String message;

  const LobbyFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ─── Phase 3 (Task 3) ──────────────────────────────────────────────────────

/// Danh sách lobby khả dụng (BR-10 filter + radius).
class LobbyListLoaded extends LobbyState {
  final List<LobbySummary> lobbies;

  const LobbyListLoaded({required this.lobbies});

  @override
  List<Object?> get props => [lobbies];
}

class LobbyListLoading extends LobbyState {
  const LobbyListLoading();
}

class LobbyListEmpty extends LobbyState {
  final String message;

  const LobbyListEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Luồng A: lobby vừa đầy → đã auto tạo booking [pendingDeposit] cho host.
class LobbyAutoBookingCreated extends LobbyState {
  final LobbyEntity lobby;

  /// Id booking vừa được server trả về (dùng cho resume / persistence).
  final String bookingId;

  const LobbyAutoBookingCreated({required this.lobby, required this.bookingId});

  @override
  List<Object?> get props => [lobby, bookingId];
}
