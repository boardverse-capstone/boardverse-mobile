import 'package:equatable/equatable.dart';

class FriendEntity extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final bool isInLobby;

  const FriendEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    this.isInLobby = false,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, isOnline, isInLobby];
}

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
