import 'package:equatable/equatable.dart';

class InGameSessionEntity extends Equatable {
  final String sessionId;
  final String bookingId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final int tableNumber;
  final List<InGamePlayer> players;
  final DateTime startTime;
  final InGameSessionStatus status;
  final Duration playDuration;
  final bool isCheckingInventory;

  const InGameSessionEntity({
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

  @override
  List<Object?> get props => [
        sessionId,
        bookingId,
        cafeId,
        cafeName,
        gameId,
        gameName,
        tableNumber,
        players,
        startTime,
        status,
        playDuration,
        isCheckingInventory,
      ];
}

class InGamePlayer extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isPresent;

  const InGamePlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isPresent,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, isPresent];
}

enum InGameSessionStatus {
  active,
  checkingOut,
  completed,
  cancelled,
}
