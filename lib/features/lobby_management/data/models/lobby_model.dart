import '../../domain/entities/lobby_entity.dart';

enum LobbyStatusModel { waiting, filling, ready, cancelled, expired }

class LobbyPlayerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final String joinedAt;

  const LobbyPlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
  });

  factory LobbyPlayerModel.fromJson(Map<String, dynamic> json) {
    return LobbyPlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isHost: json['isHost'] as bool,
      isReady: json['isReady'] as bool,
      joinedAt: json['joinedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isHost': isHost,
      'isReady': isReady,
      'joinedAt': joinedAt,
    };
  }

  LobbyPlayer toEntity() => LobbyPlayer(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        isHost: isHost,
        isReady: isReady,
        joinedAt: DateTime.parse(joinedAt),
      );
}

class LobbyModel {
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
  final LobbyStatusModel status;
  final List<LobbyPlayerModel> players;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LobbyModel({
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

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    return LobbyModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      gameName: json['gameName'] as String,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      currentPlayers: json['currentPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      minPlayers: json['minPlayers'] as int,
      isPublic: json['isPublic'] as bool,
      inviteCode: json['inviteCode'] as String?,
      status: LobbyStatusModel.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LobbyStatusModel.waiting,
      ),
      players: (json['players'] as List)
          .map((e) => LobbyPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'gameName': gameName,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'hostId': hostId,
      'hostName': hostName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'currentPlayers': currentPlayers,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'isPublic': isPublic,
      'inviteCode': inviteCode,
      'status': status.name,
      'players': players.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  int get slotsRemaining => maxPlayers - currentPlayers;

  LobbyEntity toEntity() => LobbyEntity(
        id: id,
        gameId: gameId,
        gameName: gameName,
        cafeId: cafeId,
        cafeName: cafeName,
        hostId: hostId,
        hostName: hostName,
        scheduledTime: scheduledTime,
        currentPlayers: currentPlayers,
        maxPlayers: maxPlayers,
        minPlayers: minPlayers,
        isPublic: isPublic,
        inviteCode: inviteCode,
        status: _statusToEntity(status),
        players: players.map((p) => p.toEntity()).toList(),
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

  static LobbyStatus _statusToEntity(LobbyStatusModel status) {
    switch (status) {
      case LobbyStatusModel.waiting:
        return LobbyStatus.waiting;
      case LobbyStatusModel.filling:
        return LobbyStatus.filling;
      case LobbyStatusModel.ready:
        return LobbyStatus.ready;
      case LobbyStatusModel.cancelled:
        return LobbyStatus.cancelled;
      case LobbyStatusModel.expired:
        return LobbyStatus.expired;
    }
  }
}
