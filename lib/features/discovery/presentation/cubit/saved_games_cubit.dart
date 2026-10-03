import 'dart:async';

import 'package:flutter/foundation.dart';
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
///    Nếu API lỗi → revert + emit action message để UI show toast
///
/// **Side-effect events**: cubit còn expose [actions] stream để UI listen
/// và show toast/snackbar khi save/unsave thành công. Message lấy từ
/// BE envelope (`message` field) hoặc fallback tiếng Việt.
class SavedGamesCubit extends Cubit<SavedGamesState> {
  final DiscoveryRepository _repository;
  final SavedGamesCache _cache;

  /// Stream emit [SaveActionMessage] mỗi khi save/unsave có kết quả
  /// (thành công/thất bại) để UI show toast.
  final StreamController<SaveActionMessage> _actionsController =
      StreamController<SaveActionMessage>.broadcast();

  /// Public stream cho UI listen.
  ///
  /// **Robustness**: cache stream reference khi controller còn mở.
  /// Khi controller đã đóng (cubit disposed), cached stream là
  /// "closed stream" — listen() sẽ complete ngay thay vì throw
  /// `Bad state: Cannot use a closed StreamController`.
  ///
  /// Race condition thực tế trên web: cubit có thể bị close sớm
  /// (do BlocProvider.value disposal) nhưng widget con vẫn cố
  /// subscribe trong `initState`. Nếu không cache, getter `.actions`
  /// throw và widget crash đỏ.
  Stream<SaveActionMessage>? _cachedActions;
  Stream<SaveActionMessage> get actions {
    final cached = _cachedActions;
    if (cached != null) return cached;
    if (_actionsController.isClosed) {
      // Controller đã đóng trước khi ai kịp cache → trả stream rỗng
      // để listen() complete silently.
      return const Stream<SaveActionMessage>.empty();
    }
    _cachedActions = _actionsController.stream;
    return _cachedActions!;
  }

  SavedGamesCubit({
    required DiscoveryRepository repository,
    required SavedGamesCache cache,
  })  : _repository = repository,
        _cache = cache,
        super(const SavedGamesInitial());

  @override
  Future<void> close() {
    _actionsController.close();
    return super.close();
  }

  /// Load cache (instant) rồi refresh từ API.
  /// Load cache (instant) rồi refresh từ API.
  ///
  /// **Quan trọng — defense-in-depth:** Check `isClosed` NGAY ĐẦU
  /// method. Nếu cubit đã bị close (vd: do app session trước gọi
  /// `close()` qua `BlocProvider(create:)` đã bị dispose), `emit(...)`
  /// ngay sau đó sẽ throw `"Cannot emit new states after calling
  /// close"` TRƯỚC khi gọi `_repository.getSavedGames()` → API
  /// `/api/v1/discovery/saved` không bao giờ được gọi → UI treo
  /// loading mãi. Bail out early để tránh throw vô ích; giao diện
  /// sẽ tự retry ở lần hot-restart kế tiếp khi cubit được tái tạo.
  Future<void> loadSavedGames() async {
    if (isClosed) return;
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
    } catch (e, stack) {
      // Bắt mọi exception (model parse lỗi, network error, v.v.) để
      // cubit không crash → widget tree nhận SavedGamesError thay vì
      // exception. Log stack trace để debug.
      if (isClosed) return;
      debugPrint('[SavedGamesCubit] loadSavedGames() threw: $e\n$stack');
      emit(SavedGamesError(
        message: e.toString(),
        savedIds: cachedIds,
      ));
    }
  }

  /// Refresh từ API (giữ cache hiện tại nếu đang loaded).
  ///
  /// **Defense-in-depth:** tương tự [loadSavedGames], check `isClosed`
  /// trước khi gọi `state`/emit để tránh throw khi cubit đã đóng.
  ///
  /// **Try-catch wrap (2026-10-03 fix):** trước đây `refresh` KHÔNG có
  /// try-catch → nếu `_repository.getSavedGames()` throw (vd: model
  /// parse lỗi do BE trả data không như expected), exception propagate
  /// lên widget tree → Flutter render đỏ. Fix: bọc toàn bộ body trong
  /// try-catch và emit `SavedGamesError` để UI show `ErrorStateWidget`
  /// thay vì crash. Giữ state cũ (games list) nếu có để user không
  /// bị mất danh sách đã load.
  Future<void> refresh() async {
    if (isClosed) return;
    final current = state;

    try {
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
    } catch (e, stack) {
      // Catch mọi exception (model parse lỗi, repository throw, v.v.)
      // và emit SavedGamesError. Log stack trace để debug.
      if (isClosed) return;
      debugPrint('[SavedGamesCubit] refresh() threw: $e\n$stack');
      // Giữ games list cũ (nếu có) để user không bị mất danh sách
      // đã load. savedIds vẫn từ cache local.
      final prevGames = current is SavedGamesLoaded
          ? current.games
          : (current is SavedGamesError ? current.games : null);
      emit(SavedGamesError(
        message: e.toString(),
        games: prevGames,
        savedIds: _cache.read(),
      ));
    }
  }

  /// Toggle save/unsave với optimistic update.
  Future<void> toggleSave(String gameTemplateId) async {
    debugPrint(
      '[SavedGamesCubit] toggleSave called for gameTemplateId=$gameTemplateId',
    );
    // Đọc trạng thái hiện tại
    final wasSaved = _cache.isSaved(gameTemplateId);
    final newSavedState = !wasSaved;
    debugPrint(
      '[SavedGamesCubit] wasSaved=$wasSaved, newSavedState=$newSavedState',
    );

    // Cập nhật cache ngay
    if (newSavedState) {
      await _cache.add(gameTemplateId);
    } else {
      await _cache.remove(gameTemplateId);
    }

    // Optimistic update state.
    //
    // Lưu ý: nếu user back ra khỏi page ngay sau khi nhấn save, cubit có
    // thể đã bị close trong khi `await _cache.add(...)` đang chạy → emit
    // dưới đây sẽ throw "Cannot emit new states after calling close".
    // Check `isClosed` ngay tại đây (và bên trong `_optimisticUpdate` /
    // `_rollbackToggle`) để bail out an toàn.
    if (isClosed) return;
    _optimisticUpdate(gameTemplateId, newSavedState);
    debugPrint(
      '[SavedGamesCubit] optimistic update done, new state=${state.runtimeType}',
    );

    // Capture controller reference TRƯỚC khi await. Sau `close()`,
    // trên DDC (web) một số field có thể bị nullify qua reflection nội
    // bộ của package bloc. Dùng local reference tránh bị null trong
    // callback khi `close()` chạy giữa chừng.
    final controller = _actionsController;

    // Gọi API
    try {
      debugPrint('[SavedGamesCubit] calling API toggleSave...');
      final result = await _repository.toggleSave(gameTemplateId);
      debugPrint(
        '[SavedGamesCubit] API response received, isClosed=$isClosed',
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          _rollbackToggle(gameTemplateId, wasSaved);
          _safeAddAction(
            controller,
            SaveActionMessage(
              gameTemplateId: gameTemplateId,
              message: failure.message,
              isSaved: wasSaved, // rolled back
              isSuccess: false,
            ),
          );
        },
        (saveResult) {
          // Sync cache với canonical state từ server
          if (saveResult.isSaved) {
            _cache.add(gameTemplateId);
          } else {
            _cache.remove(gameTemplateId);
          }
          // Sync state emit voi server truth (truong hop cache local
          // bi lech server do API response khac voi optimistic).
          // Neu cache da dung, emit nay la no-op (set giong set).
          //
          // `_optimisticUpdate` tự check `isClosed` bên trong nhưng vẫn
          // check ở đây để tránh gọi thừa + match pattern phòng thủ.
          if (isClosed) return;
          _optimisticUpdate(gameTemplateId, saveResult.isSaved);
          if (isClosed) return;
          // Emit action message cho UI show success toast.
          // Message từ BE có dạng: "Đã lưu board game." / "Đá bỏ lưu..."
          final msg = saveResult.message ??
              (saveResult.isSaved
                  ? 'Đã lưu board game.'
                  : 'Đã bỏ lưu board game.');
          _safeAddAction(
            controller,
            SaveActionMessage(
              gameTemplateId: gameTemplateId,
              message: msg,
              isSaved: saveResult.isSaved,
              isSuccess: true,
            ),
          );
          // Refresh list nếu đang ở SavedGamesPage. `refresh()` tự check
          // `isClosed` bên trong — không cần guard ở đây.
          if (state is SavedGamesLoaded) {
            refresh();
          }
        },
      );
    } catch (e) {
      // API threw exception → rollback
      _rollbackToggle(gameTemplateId, wasSaved);
      _safeAddAction(
        controller,
        SaveActionMessage(
          gameTemplateId: gameTemplateId,
          message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
          isSaved: wasSaved,
          isSuccess: false,
        ),
      );
    }
  }

  /// Add action message an toàn vào controller, tránh crash khi:
  /// - Controller đã đóng (cubit disposed)
  /// - Controller bị nullify trên DDC/web sau `close()`
  /// - Broadcast stream listener chưa sẵn sàng
  ///
  /// Lỗi được nuốt im lặng vì đây là side-effect (toast), không ảnh
  /// hưởng logic chính của save/unsave.
  void _safeAddAction(
    StreamController<SaveActionMessage>? controller,
    SaveActionMessage message,
  ) {
    if (controller == null) return;
    if (controller.isClosed) return;
    try {
      controller.add(message);
    } catch (_) {
      // Swallow: side-effect failure should not crash cubit.
    }
  }

  /// Helper rollback cache + state sau khi toggle fail.
  void _rollbackToggle(String gameTemplateId, bool wasSaved) {
    // Cubit có thể đã bị close trong khi API đang await (user back ra
    // khỏi page). Skip cache write + emit nếu closed để tránh throw.
    if (isClosed) return;
    if (wasSaved) {
      _cache.add(gameTemplateId);
    } else {
      _cache.remove(gameTemplateId);
    }
    _optimisticUpdate(gameTemplateId, wasSaved);
  }

  /// Kiểm tra game đã save chưa (từ cache).
  bool isSaved(String gameTemplateId) => _cache.isSaved(gameTemplateId);

  /// Optimistic update local state khi user tap save/unsave.
  ///
  /// **Quan trọng**: ham nay LUON emit state moi (tru cac truong hop
  /// state Closed). Truoc day chi xu ly `SavedGamesLoaded` va
  /// `SavedGamesLoadingFromCache` → neu cubit dang `Initial` (do
  /// `discovery_results_page` khong goi `loadSavedGames`), tap se
  /// "im lang" → user khong thay UI thay doi. Fix: them branch cho
  /// `Initial` / `Refreshing` / `Error` → emit state co chua savedIds
  /// de button BlocBuilder rebuild.
  ///
  /// Cac state emission:
  /// - [SavedGamesLoaded]: giu nguyen logic placeholder neu game chua
  ///   co trong list (de SavedGamesPage show optimistic).
  /// - [SavedGamesLoadingFromCache]: cap nhat `cachedIds` truc tiep.
  /// - [SavedGamesRefreshing]: chuyen sang Loaded voi derived savedIds
  ///   (ghep tu games list hien tai + cache).
  /// - [SavedGamesError] co savedIds: cap nhat savedIds truc tiep.
  /// - [SavedGamesInitial] / [SavedGamesError] khong co savedIds:
  ///   emit [SavedGamesLoadingFromCache] voi cache truth (se duoc
  ///   `loadSavedGames` / `refresh` thay the khi API tra ve).
  void _optimisticUpdate(String gameTemplateId, bool isSavedNow) {
    // CRITICAL: Cubit có thể đã bị close trong khi `await _cache.add(...)`
    // (line 124 của `toggleSave`) hoặc trong các closure của `result.fold`
    // phía dưới. Nếu không check `isClosed` ở đây → `emit()` throw
    // "Cannot emit new states after calling close" (xảy ra thực tế trên
    // web khi user back ra khỏi DiscoveryResultsPage ngay sau khi tap save).
    if (isClosed) return;

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
    } else if (current is SavedGamesRefreshing) {
      // Refreshing: keep games, transition sang Loaded voi derived
      // savedIds tu games + cache (de button va list deu dung).
      final gameIds = current.games.map((g) => g.gameTemplateId).toSet();
      final newIds = isSavedNow
          ? {...gameIds, gameTemplateId}
          : gameIds.difference({gameTemplateId});
      emit(SavedGamesLoaded(
        games: current.games,
        totalCount: current.totalCount,
        savedIds: newIds,
      ));
    } else if (current is SavedGamesError && current.savedIds != null) {
      // Dùng local var để vượt qua Dart rule "non-promo-public-field"
      // (`current.savedIds` là public field nên compiler không promote
      // được sau khi null-check trong cùng dòng `is` check).
      final ids = current.savedIds!;
      emit(SavedGamesError(
        message: current.message,
        games: current.games,
        savedIds: isSavedNow
            ? {...ids, gameTemplateId}
            : ids.difference({gameTemplateId}),
      ));
    } else {
      // SavedGamesInitial / SavedGamesError khong co savedIds →
      // emit SavedGamesLoadingFromCache voi cache truth. Button
      // BlocBuilder dung `_idsOf` lay cachedIds → rebuild va UI flip.
      // State se duoc `loadSavedGames` / `refresh` thay the khi API
      // call tiep theo hoan tat.
      final ids = _cache.read();
      final newIds = isSavedNow
          ? {...ids, gameTemplateId}
          : ids.difference({gameTemplateId});
      emit(SavedGamesLoadingFromCache(cachedIds: newIds));
    }
  }
}

/// Side-effect event từ [SavedGamesCubit.toggleSave] — UI listen qua
/// `actions` stream để show toast/snackbar.
///
/// - [isSuccess] = true: hiển thị success toast (message từ BE).
/// - [isSuccess] = false: hiển thị error toast (message lỗi).
/// - [isSaved]: trạng thái CUỐI CÙNG sau toggle (false nếu đã rollback).
class SaveActionMessage {
  final String gameTemplateId;
  final String message;
  final bool isSaved;
  final bool isSuccess;

  const SaveActionMessage({
    required this.gameTemplateId,
    required this.message,
    required this.isSaved,
    required this.isSuccess,
  });
}
