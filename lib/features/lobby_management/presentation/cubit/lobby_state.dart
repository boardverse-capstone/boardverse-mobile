import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../../domain/entities/lobby_chat_message.dart';

/// Pre-defined reasons for lobby dismissal.
class LobbyDismissReason extends Equatable {
  final String code;
  final String title;
  final String message;

  const LobbyDismissReason({
    required this.code,
    required this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [code, title, message];
}

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

/// Lobby đã kết thúc (`Closed` / `TimeoutFailed` / `HostCancelled`).
///
/// Phát ra từ `initLobbyState` khi player mở lobby hết hạn từ
/// tab "Phòng của tôi". LobbyPage render UI read-only + action bar
/// (Giải tán / Tạo lại / Gia hạn / Xem chi tiết) thay vì active lobby UI.
class LobbyEnded extends LobbyState {
  final LobbyEntity lobby;

  const LobbyEnded({required this.lobby});

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

/// Đang fetch danh sách bạn bè online cho flow MỜI THỰC (gửi notification).
///
/// Phát ra trước khi [LobbyFriendsLoaded]. UI FriendsSheet dùng state này
/// để hiển thị shimmer skeleton thay vì spinner cũ.
class LobbyFriendsLoading extends LobbyState {
  const LobbyFriendsLoading();
}

/// Danh sách bạn bè online — dùng cho flow MỜI THỰC (gửi notification).
class LobbyFriendsLoaded extends LobbyState {
  final List<FriendEntity> friends;

  /// Lobby hiện tại — null nếu cubit chưa sync được lobby (vd: user mở
  /// sheet ngay khi `initLobbyState` đang chạy). Sheet sẽ tự retry khi
  /// cubit emit `LobbyCreated`/`LobbyUpdatedRealtime`.
  final LobbyEntity? lobby;

  const LobbyFriendsLoaded({required this.friends, this.lobby});

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
  /// List các lobby — có thể là [LobbySummary] (từ `/search`) hoặc
  /// [LobbyEntity] (từ `/discoverable`). Page render dựa vào runtime type.
  final List<LobbySummary> lobbies;

  /// List lobby đầy đủ thông tin từ `/api/v1/lobbies/discoverable`.
  /// Khi caller dùng `/discoverable`, page sẽ ưu tiên [entities] thay vì
  /// [lobbies] để có full data (status, scheduledTime, players, ...).
  /// Mặc định rỗng — chỉ `/discoverable` mới fill.
  final List<LobbyEntity> entities;

  const LobbyListLoaded({
    required this.lobbies,
    this.entities = const [],
  });

  @override
  List<Object?> get props => [lobbies, entities];
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

// ─── Host Actions States ─────────────────────────────────────────────────

/// Host đã giải tán lobby (hard delete thành công).
/// Sau khi lobby bị xoá, danh sách "Phòng của tôi" sẽ không còn
/// hiển thị lobby này nữa.
class LobbyDissolved extends LobbyState {
  final String lobbyId;

  const LobbyDissolved({required this.lobbyId});

  @override
  List<Object?> get props => [lobbyId];
}

/// Host đã chuyển quyền host thành công.
class LobbyHostTransferred extends LobbyState {
  final LobbyEntity lobby;
  final String newHostId;

  const LobbyHostTransferred({required this.lobby, required this.newHostId});

  @override
  List<Object?> get props => [lobby, newHostId];
}

/// Host đã kick thành viên thành công.
class LobbyMemberKicked extends LobbyState {
  final LobbyEntity lobby;
  final String kickedMemberId;

  const LobbyMemberKicked({required this.lobby, required this.kickedMemberId});

  @override
  List<Object?> get props => [lobby, kickedMemberId];
}

/// Member đã thay đổi ready status.
class LobbyReadyStatusChanged extends LobbyState {
  final LobbyEntity lobby;
  final String memberId;
  final bool isReady;

  const LobbyReadyStatusChanged({
    required this.lobby,
    required this.memberId,
    required this.isReady,
  });

  @override
  List<Object?> get props => [lobby, memberId, isReady];
}

/// Report đã được gửi thành công.
class LobbyReportSubmitted extends LobbyState {
  const LobbyReportSubmitted();
}

// ─── My Lobbies States ─────────────────────────────────────────────────

/// Danh sách lobby đã host / đã tham gia.
class LobbyMyLobbiesLoaded extends LobbyState {
  final List<LobbyEntity> hosted;
  final List<LobbyEntity> joined;

  const LobbyMyLobbiesLoaded({
    required this.hosted,
    required this.joined,
  });

  bool get isEmpty => hosted.isEmpty && joined.isEmpty;

  @override
  List<Object?> get props => [hosted, joined];
}

/// Chat messages đã load.
class LobbyChatLoaded extends LobbyState {
  final List<LobbyChatMessage> messages;

  const LobbyChatLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

/// Chat error khi gửi message.
class LobbyChatError extends LobbyState {
  final String message;

  const LobbyChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
