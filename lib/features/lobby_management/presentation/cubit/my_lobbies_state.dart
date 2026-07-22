import 'package:equatable/equatable.dart';

import '../../domain/entities/lobby_entity.dart';

/// State cho [MyLobbiesCubit] — dùng ở section "Phòng chờ của tôi" trong
/// Discovery → tab "Phòng chờ".
///
/// Luồng lấy dữ liệu: gọi `/api/v1/lobbies/discoverable` rồi filter
/// client-side theo `hostId == currentUserId` (backend chưa có endpoint
/// `/lobbies/mine` riêng). Kết hợp với [LobbyPersistenceService] để lấy
/// active lobby mà user đang tham gia (host hoặc member).
sealed class MyLobbiesState extends Equatable {
  const MyLobbiesState();

  @override
  List<Object?> get props => [];
}

class MyLobbiesInitial extends MyLobbiesState {
  const MyLobbiesInitial();
}

class MyLobbiesLoading extends MyLobbiesState {
  const MyLobbiesLoading();
}

class MyLobbiesLoaded extends MyLobbiesState {
  /// Lobby do current user HOST (hostId == currentUserId).
  final List<LobbyEntity> hosted;

  /// Lobby hiện tại user đang là member (lưu local qua LobbyPersistenceService).
  /// Có thể null nếu user không tham gia lobby nào.
  final LobbyEntity? active;

  const MyLobbiesLoaded({
    required this.hosted,
    this.active,
  });

  /// Có dữ liệu nào để hiển thị hay không (phục vụ empty state).
  bool get isEmpty => hosted.isEmpty && active == null;

  @override
  List<Object?> get props => [hosted, active];
}

class MyLobbiesFailure extends MyLobbiesState {
  final String message;

  const MyLobbiesFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
