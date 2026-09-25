import 'package:equatable/equatable.dart';

import '../../domain/entities/saved_board_game_entity.dart';

/// Sealed states cho [SavedGamesCubit].
sealed class SavedGamesState extends Equatable {
  const SavedGamesState();

  @override
  List<Object?> get props => [];
}

/// Initial — chưa load.
class SavedGamesInitial extends SavedGamesState {
  const SavedGamesInitial();
}

/// Đang load từ cache (instant render).
class SavedGamesLoadingFromCache extends SavedGamesState {
  final Set<String> cachedIds;

  const SavedGamesLoadingFromCache({required this.cachedIds});

  @override
  List<Object?> get props => [cachedIds];
}

/// Đang refresh từ API.
class SavedGamesRefreshing extends SavedGamesState {
  final List<SavedBoardGameEntity> games;
  final int totalCount;

  const SavedGamesRefreshing({
    required this.games,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [games, totalCount];
}

/// Loaded thành công.
class SavedGamesLoaded extends SavedGamesState {
  final List<SavedBoardGameEntity> games;
  final int totalCount;
  final Set<String> savedIds; // cache local

  const SavedGamesLoaded({
    required this.games,
    required this.totalCount,
    required this.savedIds,
  });

  SavedGamesLoaded copyWith({
    List<SavedBoardGameEntity>? games,
    int? totalCount,
    Set<String>? savedIds,
  }) {
    return SavedGamesLoaded(
      games: games ?? this.games,
      totalCount: totalCount ?? this.totalCount,
      savedIds: savedIds ?? this.savedIds,
    );
  }

  @override
  List<Object?> get props => [games, totalCount, savedIds];
}

/// Lỗi.
class SavedGamesError extends SavedGamesState {
  final String message;
  final List<SavedBoardGameEntity>? games;
  final Set<String>? savedIds;

  const SavedGamesError({
    required this.message,
    this.games,
    this.savedIds,
  });

  @override
  List<Object?> get props => [message, games, savedIds];
}
