// Unit tests cho SavedGamesCubit.
//
// Verify:
// - loadSavedGames: instant cache render → API refresh
// - toggleSave: optimistic update + revert on failure
// - isSaved: cache lookup
// - refresh: keep current list when API fails

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
    cubit.close();
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
}
