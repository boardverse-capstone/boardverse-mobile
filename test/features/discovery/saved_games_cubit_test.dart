// Unit tests cho SavedGamesCubit.
//
// Verify:
// - loadSavedGames: instant cache render → API refresh
// - toggleSave: optimistic update + revert on failure
// - isSaved: cache lookup
// - refresh: keep current list when API fails
// - race condition: cubit.close() trong khi toggleSave đang await

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/storage/saved_games_cache.dart';
import 'package:boardverse/features/discovery/data/models/board_game_save_result_model.dart';
import 'package:boardverse/features/discovery/data/models/saved_games_response_model.dart';
import 'package:boardverse/features/discovery/domain/entities/board_game_save_result_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/discovery_request_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/game_category_discovery_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/group_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/recommended_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/saved_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/solo_personalized_response_entity.dart';
import 'package:boardverse/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_cubit.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_state.dart';

class MockDiscoveryRepository implements DiscoveryRepository {
  List<SavedBoardGameEntity>? savedGamesToReturn;
  BoardGameSaveResultModel? toggleResultToReturn;
  Object? errorToThrow;
  int toggleSaveCalls = 0;

  void stubGetSavedGames(List<SavedBoardGameEntity> games) {
    savedGamesToReturn = games;
  }

  void stubToggleSave(BoardGameSaveResultModel result) {
    toggleResultToReturn = result;
  }

  void stubError(Object error) {
    errorToThrow = error;
  }

  @override
  Future<Either<Failure, List<SavedBoardGameEntity>>> getSavedGames() async {
    if (errorToThrow != null) throw errorToThrow!;
    return Right(savedGamesToReturn ?? const []);
  }

  @override
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  ) async {
    toggleSaveCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final result = toggleResultToReturn ??
        BoardGameSaveResultModel(
          gameTemplateId: gameTemplateId,
          gameName: 'Mock Game',
          isSaved: !_savedStatus(gameTemplateId),
        );
    return Right(BoardGameSaveResultEntity(
      gameTemplateId: result.gameTemplateId,
      gameName: result.gameName,
      isSaved: result.isSaved,
      savedAt: result.savedAt,
      message: result.message,
    ));
  }

  bool _savedStatus(String id) {
    return savedGamesToReturn?.any((g) => g.gameTemplateId == id) ?? false;
  }

  @override
  Future<Either<Failure, bool>> unsaveGame(String gameTemplateId) async {
    return const Right(true);
  }

  @override
  Future<int> getSavedGamesCount() async => 0;

  @override
  Future<Either<Failure, List<GameCategoryDiscoveryEntity>>> getCategories() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<RecommendedBoardGameEntity>>> runSurvey(
    DiscoveryRequestEntity request,
  ) async => const Right([]);

  @override
  Future<Either<Failure, SoloPersonalizedResponseEntity>> getSoloPersonalized({
    required DiscoveryRequestEntity request,
    double? latitude,
    double? longitude,
    int pageSize = 20,
    bool excludeSavedGames = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<GroupBoardGameEntity>>> discoverForGroup({
    required List<MemberPreferenceRequest> members,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }
}

SavedBoardGameEntity _makeGame(String id, String name) {
  return SavedBoardGameEntity(
    id: 's-$id',
    gameTemplateId: id,
    gameName: name,
    categories: const ['Strategy'],
    savedAt: DateTime(2024, 1, 1),
  );
}

/// Mock đặc biệt cho race condition test: `toggleSave` return
/// `Completer.future` để test control chính xác thời điểm API
/// "trả về" — cho phép gọi `cubit.close()` TRƯỚC khi API complete.
class _RaceConditionMock extends MockDiscoveryRepository {
  final Future<Either<Failure, BoardGameSaveResultEntity>> _toggleFuture;

  _RaceConditionMock(this._toggleFuture);

  @override
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  ) {
    toggleSaveCalls++;
    return _toggleFuture;
  }
}

void main() {
  late MockDiscoveryRepository mockRepo;
  late SavedGamesCache cache;
  late SavedGamesCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cache = SavedGamesCache(prefs);
    mockRepo = MockDiscoveryRepository();
    cubit = SavedGamesCubit(repository: mockRepo, cache: cache);
  });

  tearDown(() {
    // Cubit có thể đã được close trong test (test "actions getter KHÔNG
    // throw sau khi cubit close"). Bỏ qua lỗi close-again để tearDown
    // không fail toàn bộ test suite.
    try {
      cubit.close();
    } catch (_) {
      // already closed
    }
  });

  group('loadSavedGames', () {
    blocTest<SavedGamesCubit, SavedGamesState>(
      'emits LoadingFromCache → Loaded when API succeeds',
      build: () {
        mockRepo.stubGetSavedGames([
          _makeGame('game-1', 'Catan'),
          _makeGame('game-2', 'Carcassonne'),
        ]);
        return cubit;
      },
      act: (c) => c.loadSavedGames(),
      expect: () => [
        isA<SavedGamesLoadingFromCache>()
            .having((s) => s.cachedIds, 'cachedIds', isEmpty),
        isA<SavedGamesLoaded>()
            .having((s) => s.games.length, 'games count', 2)
            .having((s) => s.savedIds, 'savedIds', isEmpty),
      ],
    );

    blocTest<SavedGamesCubit, SavedGamesState>(
      'emits Error with cached ids when API fails',
      build: () {
        // Pre-populate cache
        cache.add('cached-1');
        mockRepo.stubError(Exception('Network error'));
        return cubit;
      },
      act: (c) => c.loadSavedGames(),
      expect: () => [
        isA<SavedGamesLoadingFromCache>()
            .having((s) => s.cachedIds, 'cachedIds', {'cached-1'}),
        isA<SavedGamesError>()
            .having((s) => s.savedIds, 'savedIds', {'cached-1'}),
      ],
    );

    test(
      'loadSavedGames KHÔNG crash khi model parse lỗi (BE trả data sai format)',
      () async {
        // Regression test cho bug 2026-10-03: nếu `_repository.getSavedGames()`
        // throw exception (vd: TypeError khi model parse data BE trả về),
        // cubit phải catch và emit SavedGamesError thay vì crash.
        // Dùng Exception thay vì TypeError vì Dart's TypeError constructor
        // không nhận positional arg trên mọi platform.
        mockRepo.stubError(
          Exception(
            "TypeError: type 'List<dynamic>' is not a subtype of "
            "type 'Map<String, dynamic>'",
          ),
        );

        // loadSavedGames KHÔNG được throw ra ngoài.
        await cubit.loadSavedGames();

        // State phải là SavedGamesError với message chứa error.
        expect(cubit.state, isA<SavedGamesError>());
        final err = cubit.state as SavedGamesError;
        expect(
          err.message,
          contains('List<dynamic>'),
          reason: 'Message phải chứa lỗi gốc để debug',
        );
      },
    );
  });

  group('toggleSave', () {
    blocTest<SavedGamesCubit, SavedGamesState>(
      'optimistic update: adds game to list on success',
      build: () {
        mockRepo.stubToggleSave(
          const BoardGameSaveResultModel(
            gameTemplateId: 'game-1',
            gameName: 'Catan',
            isSaved: true,
          ),
        );
        return cubit;
      },
      seed: () => const SavedGamesLoaded(
        games: [],
        totalCount: 0,
        savedIds: {},
      ),
      act: (c) => c.toggleSave('game-1'),
      verify: (_) {
        expect(cache.isSaved('game-1'), true);
        expect(mockRepo.toggleSaveCalls, 1);
      },
    );

    blocTest<SavedGamesCubit, SavedGamesState>(
      'rollback: removes game from cache on API error',
      build: () {
        // Start: game-1 is already saved
        cache.add('game-1');
        mockRepo.stubError(Exception('Toggle failed'));
        return cubit;
      },
      seed: () => SavedGamesLoaded(
        games: [_makeGame('game-1', 'Catan')],
        totalCount: 1,
        savedIds: const {'game-1'},
      ),
      act: (c) => c.toggleSave('game-1'),
      verify: (_) {
        // After rollback, cache should still have game-1 (was saved)
        expect(cache.isSaved('game-1'), true);
      },
    );
  });

  group('isSaved', () {
    test('returns true when gameId is in cache', () async {
      await cache.add('game-1');
      expect(cubit.isSaved('game-1'), true);
    });

    test('returns false when gameId is not in cache', () {
      expect(cubit.isSaved('game-99'), false);
    });
  });

  group('race condition: cubit close() during pending toggleSave', () {
    test(
      'toggleSave KHÔNG throw khi cubit close() chạy giữa lúc API đợi',
      () async {
        // Custom mock dùng Completer để control timing — block API
        // response cho đến khi test gọi `completeResponse()`.
        final completer = Completer<Either<Failure, BoardGameSaveResultEntity>>();
        final raceRepo = _RaceConditionMock(completer.future);
        final raceCubit = SavedGamesCubit(
          repository: raceRepo,
          cache: cache,
        );

        // Fire-and-forget toggleSave — sẽ block ở await API.
        final pendingToggle = raceCubit.toggleSave('game-race');
        await Future<void>.delayed(
          const Duration(milliseconds: 20),
        ); // đảm bảo toggleSave đã vào await

        // Cubit close() NGAY khi API chưa trả về.
        await raceCubit.close();

        // Giờ cho API trả success.
        completer.complete(
          const Right(BoardGameSaveResultEntity(
            gameTemplateId: 'game-race',
            gameName: 'Race Game',
            isSaved: true,
            message: 'Đã lưu.',
          )),
        );

        // Await toggleSave — phải hoàn thành mà KHÔNG throw, dù cubit
        // đã close và `_actionsController` đã dispose.
        await pendingToggle;

        // Nếu đến đây mà không throw → fix thành công.
        // Verify controller đã close thật.
        expect(
          raceRepo.toggleSaveCalls,
          1,
          reason: 'API phải được gọi đúng 1 lần',
        );
      },
    );

    test(
      'toggleSave KHÔNG throw khi cubit close() và API trả về failure',
      () async {
        final completer = Completer<Either<Failure, BoardGameSaveResultEntity>>();
        final raceRepo = _RaceConditionMock(completer.future);
        final raceCubit = SavedGamesCubit(
          repository: raceRepo,
          cache: cache,
        );

        final pendingToggle = raceCubit.toggleSave('game-fail');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await raceCubit.close();

        // API trả failure (Left).
        completer.complete(
          const Left(ServerFailure(message: 'Toggle failed.')),
        );

        // Không được throw.
        await pendingToggle;
      },
    );
  });

  group('actions stream (side-effect events for toast)', () {
    test(
      'emits SaveActionMessage with BE message when toggleSave succeeds',
      () async {
        mockRepo.stubToggleSave(
          const BoardGameSaveResultModel(
            gameTemplateId: 'game-1',
            gameName: 'Catan',
            isSaved: true,
            message: 'Đã lưu board game.',
          ),
        );
        // Listen stream TRƯỚC khi gọi toggleSave.
        final emittedMessages = <SaveActionMessage>[];
        final sub = cubit.actions.listen(emittedMessages.add);

        // Pre-load state để cubit không refresh sau toggle.
        await cubit.loadSavedGames();
        await Future<void>.delayed(Duration.zero);

        await cubit.toggleSave('game-1');
        // Cho phép microtask xử lý xong.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(emittedMessages, hasLength(1));
        expect(emittedMessages.first.gameTemplateId, 'game-1');
        expect(emittedMessages.first.message, 'Đã lưu board game.');
        expect(emittedMessages.first.isSaved, true);
        expect(emittedMessages.first.isSuccess, true);
      },
    );

    test(
      'falls back to default Vietnamese message when BE message is null',
      () async {
        // Mock trả về message = null.
        mockRepo.stubToggleSave(
          const BoardGameSaveResultModel(
            gameTemplateId: 'game-1',
            gameName: 'Catan',
            isSaved: true,
            // message: null
          ),
        );
        final emittedMessages = <SaveActionMessage>[];
        final sub = cubit.actions.listen(emittedMessages.add);

        await cubit.toggleSave('game-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(emittedMessages, hasLength(1));
        expect(emittedMessages.first.isSuccess, true);
        expect(
          emittedMessages.first.message,
          'Đã lưu board game.',
          reason: 'Fallback khi BE không trả message',
        );
      },
    );

    test(
      'emits failure message on rollback (API exception)',
      () async {
        mockRepo.stubError(Exception('Network failed'));
        final emittedMessages = <SaveActionMessage>[];
        final sub = cubit.actions.listen(emittedMessages.add);

        await cubit.toggleSave('game-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(emittedMessages, hasLength(1));
        expect(emittedMessages.first.isSuccess, false);
        expect(emittedMessages.first.isSaved, false,
            reason: 'isSaved = wasSaved = false (game chưa save, rollback về false)');
      },
    );

    test(
      'is a broadcast stream (multiple listeners)',
      () async {
        mockRepo.stubToggleSave(
          const BoardGameSaveResultModel(
            gameTemplateId: 'game-1',
            gameName: 'Catan',
            isSaved: true,
            message: 'Đã lưu board game.',
          ),
        );
        final listener1 = <SaveActionMessage>[];
        final listener2 = <SaveActionMessage>[];
        final sub1 = cubit.actions.listen(listener1.add);
        final sub2 = cubit.actions.listen(listener2.add);

        await cubit.toggleSave('game-1');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub1.cancel();
        await sub2.cancel();

        expect(listener1, hasLength(1));
        expect(listener2, hasLength(1),
            reason: 'Broadcast stream phải nhận ở nhiều listener');
      },
    );

    test(
      'actions getter KHÔNG throw sau khi cubit close (closed stream safe)',
      () async {
        // Đóng cubit trước.
        await cubit.close();

        // Tạo cubit mới để test fresh instance (cubit đã close ở trên
        // sẽ được dùng). Khi gọi `.actions` getter sau khi controller
        // đã close, KHÔNG được throw.
        // Note: cubit.close() đã được gọi ở trên, nên truy cập `.actions`
        // phải trả về empty stream thay vì throw.
        late final Stream<SaveActionMessage> stream;
        try {
          stream = cubit.actions;
        } catch (e) {
          fail('actions getter KHÔNG được throw sau close: $e');
        }

        // Listen trên closed stream phải complete silently, không throw.
        final received = <SaveActionMessage>[];
        final completed = <bool>[false];
        final sub = stream.listen(
          received.add,
          onDone: () => completed[0] = true,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(received, isEmpty);
        expect(
          completed[0],
          true,
          reason: 'Closed stream phải complete onDone ngay lập tức',
        );
      },
    );
  });

  group('BoardGameSaveResultModel.fromJson', () {
    test(
      'KHÔNG throw khi BE response thiếu gameName (DDC web safe)',
      () {
        // BE hiện tại trả envelope với data chỉ có gameTemplateId +
        // isSaved + savedAt, KHÔNG có gameName. Trước fix: `as String`
        // throw `TypeError: null is not subtype of String` trên web.
        final json = <String, dynamic>{
          'gameTemplateId': '88888888-8888-8888-8888-888888888888',
          'isSaved': true,
          'savedAt': '2026-10-02T17:56:30.5726411Z',
        };

        late final BoardGameSaveResultModel model;
        try {
          model = BoardGameSaveResultModel.fromJson(json);
        } catch (e) {
          fail('fromJson KHÔNG được throw khi gameName null: $e');
        }

        expect(model.gameTemplateId, '88888888-8888-8888-8888-888888888888');
        expect(model.gameName, '', reason: 'Fallback empty string');
        expect(model.isSaved, true);
        expect(model.savedAt, isA<DateTime>());
      },
    );
  });

  group('refresh error handling (2026-10-03 fix)', () {
    test(
      'refresh KHÔNG throw khi repository throw exception — emit SavedGamesError thay vì crash',
      () async {
        // Regression test cho bug ngày 2026-10-03: trước đây `refresh()`
        // KHÔNG có try-catch. Nếu repository throw (vd: model parse lỗi
        // do BE trả data không như expected), exception propagate lên
        // widget tree → Flutter render đỏ. Sau fix: bọc try-catch,
        // emit SavedGamesError để UI show ErrorStateWidget.

        // Seed Loaded state trước để có games list để giữ khi lỗi.
        mockRepo.stubGetSavedGames([
          _makeGame('game-loaded-1', 'Catan'),
        ]);
        await cubit.loadSavedGames();
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state, isA<SavedGamesLoaded>());

        // Setup repo để throw exception (giả lập model parse lỗi).
        mockRepo.stubError(
          Exception(
            "TypeError: type 'List<dynamic>' is not a subtype of "
            "type 'Map<String, dynamic>'",
          ),
        );

        // refresh KHÔNG được throw — nó phải catch và emit SavedGamesError.
        await cubit.refresh();

        // Verify state chuyển sang SavedGamesError (không crash).
        expect(cubit.state, isA<SavedGamesError>());
        final errorState = cubit.state as SavedGamesError;
        expect(
          errorState.message,
          contains('List<dynamic>'),
          reason: 'Message phải chứa error message gốc để debug',
        );
        // Games list cũ vẫn được giữ để user không mất context.
        expect(
          errorState.games,
          isNotNull,
          reason: 'Giữ games list cũ khi refresh fail',
        );
        expect(errorState.games!.length, 1);
        expect(errorState.games!.first.gameName, 'Catan');
      },
    );

    test(
      'refresh với state Loaded + exception → emit Refreshing → Error (giữ games cũ)',
      () async {
        // Setup Loaded state với 1 game.
        mockRepo.stubGetSavedGames([
          _makeGame('game-keep', 'Pandemic'),
        ]);
        await cubit.loadSavedGames();
        await Future<void>.delayed(Duration.zero);

        // Repo sẽ throw ở lần refresh tiếp theo.
        mockRepo.stubError(
          const FormatException('Invalid response format'),
        );

        await cubit.refresh();

        // State cuối phải là SavedGamesError với games list cũ.
        final s = cubit.state;
        expect(s, isA<SavedGamesError>());
        final err = s as SavedGamesError;
        expect(err.games, isNotNull);
        expect(err.games!.length, 1);
        expect(err.games!.first.gameName, 'Pandemic');
      },
    );
  });
}
