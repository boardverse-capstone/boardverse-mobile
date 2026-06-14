import 'package:equatable/equatable.dart';

class LobbyEntity extends Equatable {
  final String id;
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;
  final String hostId;
  final String hostName;
  final DateTime scheduledTime;
  final int currentPlayers;
  final int maxPlayers;
  final int minPlayers;
  final bool isPublic;
  final String? inviteCode;
  final LobbyStatus status;
  final List<LobbyPlayer> players;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LobbyEntity({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    required this.hostId,
    required this.hostName,
    required this.scheduledTime,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.minPlayers,
    required this.isPublic,
    this.inviteCode,
    required this.status,
    required this.players,
    required this.createdAt,
    required this.expiresAt,
  });

  int get slotsRemaining => maxPlayers - currentPlayers;
  Duration get remainingTime => expiresAt.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        gameId,
        gameName,
        cafeId,
        cafeName,
        hostId,
        hostName,
        scheduledTime,
        currentPlayers,
        maxPlayers,
        minPlayers,
        isPublic,
        inviteCode,
        status,
        players,
        createdAt,
        expiresAt,
      ];
}

class LobbyPlayer extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;

  const LobbyPlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, isHost, isReady, joinedAt];
}

enum LobbyStatus {
  waiting,
  filling,
  ready,
  cancelled,
  expired,
}
