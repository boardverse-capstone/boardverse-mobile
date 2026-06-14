import 'package:equatable/equatable.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_entity.dart';

sealed class MatchmakingState extends Equatable {
  const MatchmakingState();

  @override
  List<Object?> get props => [];
}

class MatchmakingInitial extends MatchmakingState {
  const MatchmakingInitial();
}

class MatchmakingLoading extends MatchmakingState {
  const MatchmakingLoading();
}

class MatchmakingSearchResults extends MatchmakingState {
  final List<BoardGameEntity> games;
  final String? query;
  final String? category;
  final int? minPlayers;
  final int? maxPlayers;

  const MatchmakingSearchResults({
    required this.games,
    this.query,
    this.category,
    this.minPlayers,
    this.maxPlayers,
  });

  @override
  List<Object?> get props => [games, query, category, minPlayers, maxPlayers];
}

class MatchmakingGameDetail extends MatchmakingState {
  final BoardGameEntity game;
  final List<CafeEntity> nearbyCafes;
  final bool isGpsEnabled;
  final bool isOutOfRadius;
  final List<BoardGameEntity>? similarGames;

  const MatchmakingGameDetail({
    required this.game,
    required this.nearbyCafes,
    required this.isGpsEnabled,
    required this.isOutOfRadius,
    this.similarGames,
  });

  @override
  List<Object?> get props => [game, nearbyCafes, isGpsEnabled, isOutOfRadius, similarGames];
}

class MatchmakingCafeList extends MatchmakingState {
  final BoardGameEntity selectedGame;
  final List<CafeEntity> cafes;
  final bool isGpsEnabled;

  const MatchmakingCafeList({
    required this.selectedGame,
    required this.cafes,
    required this.isGpsEnabled,
  });

  @override
  List<Object?> get props => [selectedGame, cafes, isGpsEnabled];
}

class MatchmakingGpsDisabled extends MatchmakingState {
  final String message;
  final BoardGameEntity? selectedGame;

  const MatchmakingGpsDisabled({
    this.message = 'Vui lòng bật GPS để xem quán gần bạn',
    this.selectedGame,
  });

  @override
  List<Object?> get props => [message, selectedGame];
}

class MatchmakingOutOfRadius extends MatchmakingState {
  final BoardGameEntity selectedGame;
  final List<BoardGameEntity> similarGames;

  const MatchmakingOutOfRadius({
    required this.selectedGame,
    required this.similarGames,
  });

  @override
  List<Object?> get props => [selectedGame, similarGames];
}

class MatchmakingFailure extends MatchmakingState {
  final String message;

  const MatchmakingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
