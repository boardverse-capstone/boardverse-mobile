import 'package:equatable/equatable.dart';

import '../../domain/entities/lobby_entity.dart';

/// State cho [MyLobbiesCubit] — dùng ở section "Phòng chờ của tôi" trong
/// Discovery → tab "Phòng chờ".
///
/// Sử dụng real API endpoints:
/// - `GET /api/v1/lobbies/hosted` — lobby do user host
/// - `GET /api/v1/lobbies/joined` — lobby user đã tham gia
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
  /// Lobby do current user HOST.
  final List<LobbyEntity> hosted;

  /// Lobby user đã THAM GIA (không phải host).
  final List<LobbyEntity> joined;

  const MyLobbiesLoaded({
    required this.hosted,
    required this.joined,
  });

  bool get isEmpty => hosted.isEmpty && joined.isEmpty;

  MyLobbiesLoaded copyWith({
    List<LobbyEntity>? hosted,
    List<LobbyEntity>? joined,
  }) {
    return MyLobbiesLoaded(
      hosted: hosted ?? this.hosted,
      joined: joined ?? this.joined,
    );
  }

  @override
  List<Object?> get props => [hosted, joined];
}

class MyLobbiesFailure extends MyLobbiesState {
  final String message;

  const MyLobbiesFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
