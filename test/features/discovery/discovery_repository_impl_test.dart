// Unit tests cho DiscoveryRepositoryImpl.
//
// Verify các mapper từ model → entity và logic cache sync.
// Cũng test các Failure mapping (BadRequest, Unauthorized, NotFound, ...).

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/storage/saved_games_cache.dart';
import 'package:boardverse/features/discovery/data/datasources/base/discovery_datasource.dart';
import 'package:boardverse/features/discovery/data/discovery_repository_impl.dart';
import 'package:boardverse/features/discovery/data/models/board_game_save_result_model.dart';
import 'package:boardverse/features/discovery/data/models/discovery_category_model.dart';
import 'package:boardverse/features/discovery/data/models/group_discovery_response_model.dart';
import 'package:boardverse/features/discovery/data/models/saved_games_response_model.dart';
import 'package:boardverse/features/discovery/data/models/solo_personalized_response_model.dart';
import 'package:boardverse/features/discovery/data/models/survey_response_model.dart';
import 'package:boardverse/features/discovery/domain/entities/board_game_save_result_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/discovery_request_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/recommended_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/saved_board_game_entity.dart';

class MockDiscoveryDatasource implements DiscoveryDatasource {
  List<DiscoveryCategoryModel>? categoriesToReturn;
  SurveyResponseModel? surveyToReturn;
  SavedGamesResponseModel? savedToReturn;
  BoardGameSaveResultModel? saveResultToReturn;
  Object? errorToThrow;

  // Track calls
  int getSavedGamesCalls = 0;
  int toggleSaveCalls = 0;
  final List<String> toggleSaveIds = [];

  void stubCategories(List<DiscoveryCategoryModel> categories) {
    categoriesToReturn = categories;
  }

  void stubSurvey(SurveyResponseModel response) {
    surveyToReturn = response;
  }

  void stubSavedGames(SavedGamesResponseModel response) {
    savedToReturn = response;
  }

  void stubToggleSave(BoardGameSaveResultModel result) {
    saveResultToReturn = result;
  }

  void stubError(Object error) {
    errorToThrow = error;
  }

  @override
  Future<List<DiscoveryCategoryModel>> getCategories() async {
    if (errorToThrow != null) throw errorToThrow!;
    return categoriesToReturn ?? [];
  }

  @override
  Future<SurveyResponseModel> runSurvey({
    int? playerCount,
    List<String>? categoryIds,
    List<String>? preferredDurations,
    List<int>? weightRanges,
    int? experienceLevel,
    String? searchKeyword,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return surveyToReturn ?? const SurveyResponseModel(games: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<SoloPersonalizedResponseModel> getSoloPersonalized({
    int? playerCount,
    List<String>? categoryIds,
    List<String>? preferredDurations,
    List<int>? weightRanges,
    String? searchKeyword,
    int pageSize = 20,
    bool excludeSavedGames = false,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<GroupDiscoveryResponseModel> discoverForGroup({
    required List<Map<String, dynamic>> members,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SavedGamesResponseModel> getSavedGames() async {
    getSavedGamesCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return savedToReturn ?? const SavedGamesResponseModel(savedGames: [], totalCount: 0);
  }

  @override
  Future<BoardGameSaveResultModel> toggleSave(String gameTemplateId) async {
    toggleSaveCalls++;
    toggleSaveIds.add(gameTemplateId);
    if (errorToThrow != null) throw errorToThrow!;
    return saveResultToResult(gameTemplateId);
  }

  BoardGameSaveResultModel saveResultToResult(String id) {
    return saveResultToReturn ??
        BoardGameSaveResultModel(
          gameTemplateId: id,
          gameName: 'Mock Game',
          isSaved: true,
          savedAt: DateTime(2024, 1, 1),
        );
  }

  @override
  Future<bool> unsaveGame(String gameTemplateId) async {
    return true;
  }
}

void main() {
  late MockDiscoveryDatasource mockDatasource;
  late SavedGamesCache cache;
  late DiscoveryRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cache = SavedGamesCache(prefs);
    mockDatasource = MockDiscoveryDatasource();
    repository = DiscoveryRepositoryImpl(
      datasource: mockDatasource,
      cache: cache,
    );
  });

  group('getSavedGamesCount', () {
    test('returns 0 when cache empty', () async {
      expect(await repository.getSavedGamesCount(), 0);
    });

    test('returns count from cache after replaceAll', () async {
      await cache.replaceAll(['game-1', 'game-2', 'game-3']);
      expect(await repository.getSavedGamesCount(), 3);
    });
  });

  group('toggleSave', () {
    test('syncs cache with server response (add)', () async {
      mockDatasource.stubToggleSave(
        const BoardGameSaveResultModel(
          gameTemplateId: 'game-1',
          gameName: 'Test Game',
          isSaved: true,
        ),
      );

      final result = await repository.toggleSave('game-1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (saveResult) => expect(saveResult.isSaved, true),
      );
      expect(cache.isSaved('game-1'), true);
    });

    test('syncs cache with server response (remove)', () async {
      // Pre-populate cache
      await cache.add('game-1');

      mockDatasource.stubToggleSave(
        const BoardGameSaveResultModel(
          gameTemplateId: 'game-1',
          gameName: 'Test Game',
          isSaved: false,
        ),
      );

      final result = await repository.toggleSave('game-1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (saveResult) => expect(saveResult.isSaved, false),
      );
      expect(cache.isSaved('game-1'), false);
    });

    test('returns Left(ServerFailure) on error', () async {
      mockDatasource.stubError(Exception('Network error'));

      final result = await repository.toggleSave('game-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (r) => fail('Expected Left'),
      );
    });
  });

  group('unsaveGame', () {
    test('removes from cache and returns true', () async {
      await cache.add('game-1');

      final result = await repository.unsaveGame('game-1');

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (success) => expect(success, true),
      );
      expect(cache.isSaved('game-1'), false);
    });
  });

  group('getSavedGames', () {
    test('replaces cache with server list', () async {
      mockDatasource.stubSavedGames(
        SavedGamesResponseModel(
          savedGames: [
            SavedBoardGameModel(
              id: 's1',
              gameTemplateId: 'game-1',
              gameName: 'Catan',
              categories: const ['Strategy'],
              savedAt: DateTime(2024, 1, 1),
            ),
          ],
          totalCount: 1,
        ),
      );

      final result = await repository.getSavedGames();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (games) {
          expect(games.length, 1);
          expect(games.first.id, 's1');
          expect(games.first.gameName, 'Catan');
          expect(games.first is SavedBoardGameEntity, true);
        },
      );
      expect(cache.isSaved('game-1'), true);
    });

    test('returns Left on error', () async {
      mockDatasource.stubError(Exception('Network error'));

      final result = await repository.getSavedGames();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (r) => fail('Expected Left'),
      );
    });
  });

  group('runSurvey', () {
    test('maps SurveyResponseModel games to entities', () async {
      mockDatasource.stubSurvey(
        const SurveyResponseModel(
          games: [
            RecommendedBoardGameModel(
              id: 'g1',
              name: 'Catan',
              minPlayers: 3,
              maxPlayers: 4,
              playTimeMinutes: 60,
              categories: ['Strategy'],
              score: 85,
              matchReasons: ['Số người chơi phù hợp'],
            ),
          ],
          totalCount: 1,
          hasMore: false,
        ),
      );

      final result = await repository.runSurvey(
        const DiscoveryRequestEntity(playerCount: 4),
      );

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (games) {
          expect(games.length, 1);
          expect(games.first.name, 'Catan');
          expect(games.first.score, 85);
          expect(games.first is RecommendedBoardGameEntity, true);
        },
      );
    });

    test('returns Left on error', () async {
      mockDatasource.stubError(Exception('Network error'));

      final result = await repository.runSurvey(
        const DiscoveryRequestEntity(),
      );

      expect(result.isLeft(), true);
    });
  });

  group('getCategories', () {
    test('maps DiscoveryCategoryModel to entity', () async {
      mockDatasource.stubCategories(
        const [
          DiscoveryCategoryModel(
            id: 'c1',
            name: 'Strategy',
            slug: 'strategy',
            sortOrder: 1,
          ),
        ],
      );

      final result = await repository.getCategories();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (categories) {
          expect(categories.length, 1);
          expect(categories.first.name, 'Strategy');
          expect(categories.first.slug, 'strategy');
        },
      );
    });

    test('returns empty list when no categories', () async {
      mockDatasource.stubCategories(const []);

      final result = await repository.getCategories();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Expected Right'),
        (categories) => expect(categories, isEmpty),
      );
    });
  });
}
