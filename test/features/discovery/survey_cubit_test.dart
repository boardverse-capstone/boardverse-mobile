// Unit tests cho SurveyCubit.
//
// Verify:
// - loadCategories: default SoloMode.personalized, eligibility flag
// - runSurvey: Solo survey path
// - runPersonalized: personalization path
// - discoverForGroup: Group path
// - searchWithRequest: auto-fallback to survey when not eligible

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/storage/saved_games_cache.dart';
import 'package:boardverse/features/discovery/domain/entities/board_game_save_result_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/discovery_request_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/game_category_discovery_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/group_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/personalized_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/recommended_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/saved_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/solo_personalized_response_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/sub_group_score_entity.dart';
import 'package:boardverse/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:boardverse/features/discovery/presentation/cubit/survey_cubit.dart';
import 'package:boardverse/features/discovery/presentation/cubit/survey_state.dart';

class MockDiscoveryRepository implements DiscoveryRepository {
  List<GameCategoryDiscoveryEntity>? categoriesToReturn;
  List<RecommendedBoardGameEntity>? surveyGamesToReturn;
  SoloPersonalizedResponseEntity? personalizedResponseToReturn;
  List<GroupBoardGameEntity>? groupGamesToReturn;
  int savedCountToReturn = 0;
  Object? errorToThrow;

  int runSurveyCalls = 0;
  int runPersonalizedCalls = 0;
  int discoverForGroupCalls = 0;

  void stubCategories(List<GameCategoryDiscoveryEntity> categories) {
    categoriesToReturn = categories;
  }

  void stubSurveyGames(List<RecommendedBoardGameEntity> games) {
    surveyGamesToReturn = games;
  }

  void stubPersonalized(SoloPersonalizedResponseEntity response) {
    personalizedResponseToReturn = response;
  }

  void stubGroupGames(List<GroupBoardGameEntity> games) {
    groupGamesToReturn = games;
  }

  void stubSavedCount(int count) {
    savedCountToReturn = count;
  }

  void stubError(Object error) {
    errorToThrow = error;
  }

  @override
  Future<Either<Failure, List<GameCategoryDiscoveryEntity>>>
      getCategories() async {
    if (errorToThrow != null) throw errorToThrow!;
    return Right(categoriesToReturn ?? const []);
  }

  @override
  Future<Either<Failure, List<RecommendedBoardGameEntity>>> runSurvey(
    DiscoveryRequestEntity request,
  ) async {
    runSurveyCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return Right(surveyGamesToReturn ?? const []);
  }

  @override
  Future<Either<Failure, SoloPersonalizedResponseEntity>>
      getSoloPersonalized({
    required DiscoveryRequestEntity request,
    double? latitude,
    double? longitude,
    int pageSize = 20,
    bool excludeSavedGames = false,
  }) async {
    runPersonalizedCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return Right(personalizedResponseToReturn ??
        SoloPersonalizedResponseEntity(
          games: const [],
          totalCount: 0,
        ));
  }

  @override
  Future<Either<Failure, List<GroupBoardGameEntity>>> discoverForGroup({
    required List<MemberPreferenceRequest> members,
    double? latitude,
    double? longitude,
  }) async {
    discoverForGroupCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return Right(groupGamesToReturn ?? const []);
  }

  @override
  Future<Either<Failure, List<SavedBoardGameEntity>>> getSavedGames() async =>
      const Right([]);

  @override
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> unsaveGame(String gameTemplateId) async =>
      const Right(true);

  @override
  Future<int> getSavedGamesCount() async => savedCountToReturn;
}

GameCategoryDiscoveryEntity _makeCategory(String id, String name) {
  return GameCategoryDiscoveryEntity(
    id: id,
    name: name,
    slug: name.toLowerCase(),
    sortOrder: 1,
  );
}

RecommendedBoardGameEntity _makeGame(String id, String name, double score) {
  return RecommendedBoardGameEntity(
    id: id,
    name: name,
    minPlayers: 3,
    maxPlayers: 4,
    playTimeMinutes: 60,
    categories: const ['Strategy'],
    score: score,
    matchReasons: const ['Test'],
  );
}

PersonalizedBoardGameEntity _makePersonalized(
    String id, String name, double score) {
  return PersonalizedBoardGameEntity(
    id: id,
    name: name,
    minPlayers: 3,
    maxPlayers: 4,
    playTimeMinutes: 60,
    categories: const ['Strategy'],
    score: score,
    matchReasons: const ['Test'],
    baseScore: score - 5,
    personalizationBoost: 5,
    playHistoryPenalty: 0,
    personalizedScore: score,
    isSaved: false,
    hasOpenLobby: false,
  );
}

GroupBoardGameEntity _makeGroupGame(String id, String name, double score) {
  return GroupBoardGameEntity(
    id: id,
    name: name,
    minPlayers: 3,
    maxPlayers: 4,
    playTimeMinutes: 60,
    categories: const ['Strategy'],
    aggregateScore: score,
    subGroupScores: [
      SubGroupScoreEntity(subGroupIndex: 0, playerCount: 4, score: score),
    ],
  );
}

void main() {
  late MockDiscoveryRepository mockRepo;
  late SavedGamesCache cache;
  late SurveyCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cache = SavedGamesCache(prefs);
    mockRepo = MockDiscoveryRepository();
    cubit = SurveyCubit(repository: mockRepo, cache: cache);
  });

  tearDown(() {
    cubit.close();
  });

  group('loadCategories', () {
    blocTest<SurveyCubit, SurveyState>(
      'emits CategoriesLoaded with default SoloMode.personalized',
      build: () {
        mockRepo.stubCategories([
          _makeCategory('c1', 'Strategy'),
          _makeCategory('c2', 'Family'),
        ]);
        mockRepo.stubSavedCount(5);
        return cubit;
      },
      act: (c) => c.loadCategories(),
      expect: () => [
        isA<SurveyLoading>(),
        isA<SurveyCategoriesLoaded>()
            .having((s) => s.soloMode, 'soloMode', SoloMode.personalized)
            .having((s) => s.hasPersonalizationEligible, 'eligible', true)
            .having((s) => s.categories.length, 'categories', 2),
      ],
    );

    blocTest<SurveyCubit, SurveyState>(
      'hasPersonalizationEligible = false when saved < 3',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSavedCount(2);
        return cubit;
      },
      act: (c) => c.loadCategories(),
      expect: () => [
        isA<SurveyLoading>(),
        isA<SurveyCategoriesLoaded>()
            .having((s) => s.hasPersonalizationEligible, 'eligible', false),
      ],
    );

    blocTest<SurveyCubit, SurveyState>(
      'emits Error when API fails',
      build: () {
        mockRepo.stubError(Exception('Network error'));
        return cubit;
      },
      act: (c) => c.loadCategories(),
      expect: () => [
        isA<SurveyLoading>(),
        isA<SurveyError>(),
      ],
    );
  });

  group('runSurvey', () {
    blocTest<SurveyCubit, SurveyState>(
      'emits Searching → SoloResults with games',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSurveyGames([
          _makeGame('g1', 'Catan', 85),
          _makeGame('g2', 'Carcassonne', 72),
        ]);
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.runSurvey(const DiscoveryRequestEntity(playerCount: 4));
      },
      skip: 2, // skip initial Loading → CategoriesLoaded
      expect: () => [
        isA<SurveySearching>(),
        isA<SurveySoloResults>()
            .having((s) => s.games.length, 'games', 2)
            .having((s) => s.soloMode, 'soloMode', SoloMode.survey),
      ],
      verify: (_) {
        expect(mockRepo.runSurveyCalls, 1);
        expect(mockRepo.runPersonalizedCalls, 0);
      },
    );

    blocTest<SurveyCubit, SurveyState>(
      'emits Empty when no games match',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSurveyGames(const []);
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.runSurvey(const DiscoveryRequestEntity());
      },
      skip: 2,
      expect: () => [
        isA<SurveySearching>(),
        isA<SurveyEmpty>(),
      ],
    );
  });

  group('runPersonalized', () {
    blocTest<SurveyCubit, SurveyState>(
      'emits PersonalizedResults when eligible',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubPersonalized(
          SoloPersonalizedResponseEntity(
            games: [_makePersonalized('g1', 'Catan', 92)],
            totalCount: 1,
          ),
        );
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.runPersonalized(request: const DiscoveryRequestEntity());
      },
      skip: 2,
      expect: () => [
        isA<SurveySearching>(),
        isA<SurveyPersonalizedResults>()
            .having((s) => s.response.games.length, 'games', 1),
      ],
      verify: (_) {
        expect(mockRepo.runPersonalizedCalls, 1);
      },
    );
  });

  group('searchWithRequest', () {
    blocTest<SurveyCubit, SurveyState>(
      'falls back to survey when not eligible',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSavedCount(0); // not eligible
        mockRepo.stubSurveyGames([_makeGame('g1', 'Catan', 80)]);
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.searchWithRequest(const DiscoveryRequestEntity());
      },
      verify: (_) {
        // Despite default SoloMode.personalized, the cubit
        // detects no eligibility and falls back to runSurvey.
        expect(mockRepo.runSurveyCalls, 1);
        expect(mockRepo.runPersonalizedCalls, 0);
      },
    );

    blocTest<SurveyCubit, SurveyState>(
      'uses personalized when eligible',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSavedCount(5); // eligible
        mockRepo.stubPersonalized(
          SoloPersonalizedResponseEntity(
            games: const [],
            totalCount: 0,
          ),
        );
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.searchWithRequest(const DiscoveryRequestEntity());
      },
      verify: (_) {
        expect(mockRepo.runPersonalizedCalls, 1);
        expect(mockRepo.runSurveyCalls, 0);
      },
    );
  });

  group('discoverForGroup', () {
    blocTest<SurveyCubit, SurveyState>(
      'emits GroupResults with games',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubGroupGames([_makeGroupGame('g1', 'Catan', 88)]);
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.discoverForGroup(const [
          MemberPreferenceRequest(playerCount: 4),
        ]);
      },
      skip: 2,
      expect: () => [
        isA<SurveySearching>(),
        isA<SurveyGroupResults>()
            .having((s) => s.games.length, 'games', 1),
      ],
      verify: (_) {
        expect(mockRepo.discoverForGroupCalls, 1);
      },
    );
  });

  group('switchSoloMode', () {
    blocTest<SurveyCubit, SurveyState>(
      'updates soloMode in CategoriesLoaded',
      build: () {
        mockRepo.stubCategories([_makeCategory('c1', 'Strategy')]);
        mockRepo.stubSavedCount(0);
        return cubit;
      },
      act: (c) async {
        await c.loadCategories();
        await c.switchSoloMode(SoloMode.survey);
      },
      skip: 2, // skip Loading + CategoriesLoaded (personalized)
      expect: () => [
        isA<SurveyCategoriesLoaded>()
            .having((s) => s.soloMode, 'soloMode', SoloMode.survey),
      ],
    );
  });
}
