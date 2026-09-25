import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/saved_games_cache.dart';
import '../../domain/entities/saved_board_game_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'saved_games_state.dart';

/// Cubit quản lý saved games list + toggle save/unsave.
///
/// UX flow:
/// 1. Mount → load cache → emit [SavedGamesLoadingFromCache] (instant render)
/// 2. Gọi API → emit [SavedGamesRefreshing] hoặc [SavedGamesLoaded]
/// 3. Toggle → optimistic update → emit [SavedGamesLoaded] với trạng thái mới
///    Nếu API lỗi → revert + show toast
class SavedGamesCubit extends Cubit<SavedGamesState> {
  final DiscoveryRepository _repository;
  final SavedGamesCache _cache;

  SavedGamesCubit({
    required DiscoveryRepository repository,
    required SavedGamesCache cache,
  })  : _repository = repository,
        _cache = cache,
        super(const SavedGamesInitial());

  /// Load cache (instant) rồi refresh từ API.
  Future<void> loadSavedGames() async {
    Set<String>? cachedIds;
    try {
      // Bước 1: Load cache ngay (optimistic)
      cachedIds = _cache.read();
      emit(SavedGamesLoadingFromCache(cachedIds: cachedIds));

      // Bước 2: Refresh từ API
      final result = await _repository.getSavedGames();

      if (isClosed) return;

      result.fold(
        (failure) => emit(SavedGamesError(
          message: failure.message,
          savedIds: cachedIds,
        )),
        (games) => emit(SavedGamesLoaded(
          games: games,
          totalCount: games.length,
          savedIds: cachedIds ?? <String>{},
        )),
      );
    } catch (e) {
      if (isClosed) return;
      emit(SavedGamesError(
        message: e.toString(),
        savedIds: cachedIds,
      ));
    }
  }

  /// Refresh từ API (giữ cache hiện tại nếu đang loaded).
  Future<void> refresh() async {
    final current = state;

    if (current is SavedGamesLoaded) {
      emit(SavedGamesRefreshing(
        games: current.games,
        totalCount: current.totalCount,
      ));
    } else if (current is SavedGamesError && current.games != null) {
      emit(SavedGamesRefreshing(
        games: current.games!,
        totalCount: current.games!.length,
      ));
    }

    final result = await _repository.getSavedGames();

    if (isClosed) return;

    result.fold(
      (failure) {
        // Giữ state cũ nếu có
        final prev = state;
        if (prev is SavedGamesRefreshing) {
          emit(SavedGamesLoaded(
            games: prev.games,
            totalCount: prev.totalCount,
            savedIds: _cache.read(),
          ));
        } else {
          emit(SavedGamesError(message: failure.message));
        }
      },
      (games) => emit(SavedGamesLoaded(
        games: games,
        totalCount: games.length,
        savedIds: _cache.read(),
      )),
    );
  }

  /// Toggle save/unsave với optimistic update.
  Future<void> toggleSave(String gameTemplateId) async {
    // Đọc trạng thái hiện tại
    final wasSaved = _cache.isSaved(gameTemplateId);
    final newSavedState = !wasSaved;

    // Cập nhật cache ngay
    if (newSavedState) {
      await _cache.add(gameTemplateId);
    } else {
      await _cache.remove(gameTemplateId);
    }

    // Optimistic update state
    _optimisticUpdate(gameTemplateId, newSavedState);

    // Gọi API
    try {
      final result = await _repository.toggleSave(gameTemplateId);

      if (isClosed) return;

      result.fold(
        (failure) {
          _rollbackToggle(gameTemplateId, wasSaved);
          // Note: Cubit không show toast — UI tự xử lý qua listener
        },
        (saveResult) {
          // Sync với canonical state từ server
          if (saveResult.isSaved) {
            _cache.add(gameTemplateId);
          } else {
            _cache.remove(gameTemplateId);
          }
          // Refresh list nếu đang ở SavedGamesPage
          if (state is SavedGamesLoaded) {
            refresh();
          }
        },
      );
    } catch (e) {
      // API threw exception → rollback
      _rollbackToggle(gameTemplateId, wasSaved);
    }
  }

  /// Helper rollback cache + state sau khi toggle fail.
  void _rollbackToggle(String gameTemplateId, bool wasSaved) {
    if (wasSaved) {
      _cache.add(gameTemplateId);
    } else {
      _cache.remove(gameTemplateId);
    }
    _optimisticUpdate(gameTemplateId, wasSaved);
  }

  /// Kiểm tra game đã save chưa (từ cache).
  bool isSaved(String gameTemplateId) => _cache.isSaved(gameTemplateId);

  void _optimisticUpdate(String gameTemplateId, bool isSavedNow) {
    final current = state;

    if (current is SavedGamesLoaded) {
      if (isSavedNow) {
        // Thêm vào list (nếu chưa có)
        final exists = current.games.any((g) => g.gameTemplateId == gameTemplateId);
        if (!exists) {
          final newGame = SavedBoardGameEntity(
            id: gameTemplateId,
            gameTemplateId: gameTemplateId,
            gameName: '', // placeholder — sẽ được refresh
            categories: const [],
            savedAt: DateTime.now(),
          );
          emit(current.copyWith(
            games: [newGame, ...current.games],
            totalCount: current.totalCount + 1,
            savedIds: {...current.savedIds, gameTemplateId},
          ));
        } else {
          emit(current.copyWith(
            savedIds: {...current.savedIds, gameTemplateId},
          ));
        }
      } else {
        // Xóa khỏi list
        emit(current.copyWith(
          games: current.games
              .where((g) => g.gameTemplateId != gameTemplateId)
              .toList(),
          totalCount: current.totalCount - 1,
          savedIds: current.savedIds.difference({gameTemplateId}),
        ));
      }
    } else if (current is SavedGamesLoadingFromCache) {
      emit(SavedGamesLoadingFromCache(
        cachedIds: isSavedNow
            ? {...current.cachedIds, gameTemplateId}
            : current.cachedIds.difference({gameTemplateId}),
      ));
    }
  }
}
