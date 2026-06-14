import '../../domain/entities/in_game_session_entity.dart';

enum InGameSessionStatusModel {
  active,
  checkingOut,
  completed,
  cancelled,
}

class InGamePlayerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isPresent;

  const InGamePlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isPresent,
  });

  factory InGamePlayerModel.fromJson(Map<String, dynamic> json) {
    return InGamePlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isPresent: json['isPresent'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isPresent': isPresent,
    };
  }

  InGamePlayer toEntity() => InGamePlayer(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        isPresent: isPresent,
      );
}

class InGameSessionModel {
  final String sessionId;
  final String bookingId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final int tableNumber;
  final List<InGamePlayerModel> players;
  final DateTime startTime;
  final InGameSessionStatusModel status;
  final Duration playDuration;
  final bool isCheckingInventory;

  const InGameSessionModel({
    required this.sessionId,
    required this.bookingId,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.tableNumber,
    required this.players,
    required this.startTime,
    required this.status,
    required this.playDuration,
    this.isCheckingInventory = false,
  });

  factory InGameSessionModel.fromJson(Map<String, dynamic> json) {
    return InGameSessionModel(
      sessionId: json['sessionId'] as String,
      bookingId: json['bookingId'] as String,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      gameId: json['gameId'] as String,
      gameName: json['gameName'] as String,
      tableNumber: json['tableNumber'] as int,
      players: (json['players'] as List)
          .map((e) => InGamePlayerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      status: InGameSessionStatusModel.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InGameSessionStatusModel.active,
      ),
      playDuration: Duration(seconds: json['playDuration'] as int),
      isCheckingInventory: json['isCheckingInventory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'bookingId': bookingId,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'gameId': gameId,
      'gameName': gameName,
      'tableNumber': tableNumber,
      'players': players.map((e) => e.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'status': status.name,
      'playDuration': playDuration.inSeconds,
      'isCheckingInventory': isCheckingInventory,
    };
  }

  InGameSessionEntity toEntity() => InGameSessionEntity(
        sessionId: sessionId,
        bookingId: bookingId,
        cafeId: cafeId,
        cafeName: cafeName,
        gameId: gameId,
        gameName: gameName,
        tableNumber: tableNumber,
        players: players.map((p) => p.toEntity()).toList(),
        startTime: startTime,
        status: _statusToEntity(status),
        playDuration: playDuration,
        isCheckingInventory: isCheckingInventory,
      );

  static InGameSessionStatus _statusToEntity(InGameSessionStatusModel status) {
    switch (status) {
      case InGameSessionStatusModel.active:
        return InGameSessionStatus.active;
      case InGameSessionStatusModel.checkingOut:
        return InGameSessionStatus.checkingOut;
      case InGameSessionStatusModel.completed:
        return InGameSessionStatus.completed;
      case InGameSessionStatusModel.cancelled:
        return InGameSessionStatus.cancelled;
    }
  }
}
