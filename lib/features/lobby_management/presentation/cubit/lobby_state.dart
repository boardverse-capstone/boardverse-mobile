import 'package:equatable/equatable.dart';
import '../../domain/entities/lobby_entity.dart';
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

class LobbyFriendsLoaded extends LobbyState {
  final List<FriendEntity> friends;
  final LobbyEntity lobby;

  const LobbyFriendsLoaded({
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
