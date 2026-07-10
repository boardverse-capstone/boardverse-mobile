import 'package:equatable/equatable.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../../domain/entities/game_category_entity.dart';

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

// ─── Search Results ──────────────────────────────────────────────

class MatchmakingSearchResults extends MatchmakingState {
  final List<BoardGameEntity> games;
  final String? query;
  final String? category;
  final int? minPlayers;
  final int? maxPlayers;
  final SearchFilterEntity filter;
  final List<GameCategoryEntity> categories;

  const MatchmakingSearchResults({
    required this.games,
    this.query,
    this.category,
    this.minPlayers,
    this.maxPlayers,
    this.filter = SearchFilterEntity.empty,
    this.categories = const [],
  });

  MatchmakingSearchResults copyWith({
    List<BoardGameEntity>? games,
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
    SearchFilterEntity? filter,
    List<GameCategoryEntity>? categories,
  }) {
    return MatchmakingSearchResults(
      games: games ?? this.games,
      query: query ?? this.query,
      category: category ?? this.category,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      filter: filter ?? this.filter,
      categories: categories ?? this.categories,
    );
  }

  @override
  List<Object?> get props => [games, query, category, minPlayers, maxPlayers, filter, categories];
}

// ─── Game Detail with Seat Info ───────────────────────────────────

class MatchmakingGameDetail extends MatchmakingState {
  final BoardGameEntity game;
  final List<CafeEntity> nearbyCafes;
  final bool isGpsEnabled;
  final bool isOutOfRadius;
  final List<BoardGameEntity>? similarGames;
  
  // Seat-related state
  final SeatAvailabilityEntity? selectedCafeSeats;
  final bool isCheckingSeats;
  final String? seatErrorMessage;
  final String? selectedCafeId;

  const MatchmakingGameDetail({
    required this.game,
    required this.nearbyCafes,
    required this.isGpsEnabled,
    required this.isOutOfRadius,
    this.similarGames,
    this.selectedCafeSeats,
    this.isCheckingSeats = false,
    this.seatErrorMessage,
    this.selectedCafeId,
  });

  MatchmakingGameDetail copyWith({
    BoardGameEntity? game,
    List<CafeEntity>? nearbyCafes,
    bool? isGpsEnabled,
    bool? isOutOfRadius,
    List<BoardGameEntity>? similarGames,
    SeatAvailabilityEntity? selectedCafeSeats,
    bool? isCheckingSeats,
    String? seatErrorMessage,
    String? selectedCafeId,
    bool clearSeatError = false,
  }) {
    return MatchmakingGameDetail(
      game: game ?? this.game,
      nearbyCafes: nearbyCafes ?? this.nearbyCafes,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isOutOfRadius: isOutOfRadius ?? this.isOutOfRadius,
      similarGames: similarGames ?? this.similarGames,
      selectedCafeSeats: selectedCafeSeats ?? this.selectedCafeSeats,
      isCheckingSeats: isCheckingSeats ?? this.isCheckingSeats,
      seatErrorMessage: clearSeatError ? null : (seatErrorMessage ?? this.seatErrorMessage),
      selectedCafeId: selectedCafeId ?? this.selectedCafeId,
    );
  }

  @override
  List<Object?> get props => [
        game, 
        nearbyCafes, 
        isGpsEnabled, 
        isOutOfRadius, 
        similarGames,
        selectedCafeSeats,
        isCheckingSeats,
        seatErrorMessage,
        selectedCafeId,
      ];
}

// ─── Cafe List ──────────────────────────────────────────────────

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

// ─── GPS States ──────────────────────────────────────────────────

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

// ─── Seat Availability States ─────────────────────────────────────

class SeatChecking extends MatchmakingState {
  final String cafeId;
  final int requiredSeats;

  const SeatChecking({
    required this.cafeId,
    required this.requiredSeats,
  });

  @override
  List<Object?> get props => [cafeId, requiredSeats];
}

class SeatCheckSuccess extends MatchmakingState {
  final SeatAvailabilityEntity availability;
  final bool isAvailable;
  final int requiredSeats;

  const SeatCheckSuccess({
    required this.availability,
    required this.isAvailable,
    required this.requiredSeats,
  });

  @override
  List<Object?> get props => [availability, isAvailable, requiredSeats];
}

class SeatCheckFailure extends MatchmakingState {
  final String message;
  final String cafeId;

  const SeatCheckFailure({
    required this.message,
    required this.cafeId,
  });

  @override
  List<Object?> get props => [message, cafeId];
}

// ─── Error State ─────────────────────────────────────────────────

class MatchmakingFailure extends MatchmakingState {
  final String message;

  const MatchmakingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
