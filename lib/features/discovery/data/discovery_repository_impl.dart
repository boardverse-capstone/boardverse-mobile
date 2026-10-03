import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dual_format_response.dart';
import '../../../../core/storage/saved_games_cache.dart';
import '../domain/entities/board_game_save_result_entity.dart';
import '../domain/entities/discovery_request_entity.dart';
import '../domain/entities/game_category_discovery_entity.dart';
import '../domain/entities/group_board_game_entity.dart';
import '../domain/entities/nearby_cafe_for_game_entity.dart';
import '../domain/entities/open_lobby_summary_entity.dart';
import '../domain/entities/personalized_board_game_entity.dart';
import '../domain/entities/recommended_board_game_entity.dart';
import '../domain/entities/saved_board_game_entity.dart';
import '../domain/entities/solo_personalized_response_entity.dart';
import '../domain/entities/sub_group_score_entity.dart';
import '../domain/entities/user_game_preference_entity.dart';
import '../domain/repositories/discovery_repository.dart';
import 'datasources/base/discovery_datasource.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryDatasource _datasource;
  final SavedGamesCache _cache;

  DiscoveryRepositoryImpl({
    required DiscoveryDatasource datasource,
    required SavedGamesCache cache,
  })  : _datasource = datasource,
        _cache = cache;

  @override
  Future<Either<Failure, List<GameCategoryDiscoveryEntity>>> getCategories() async {
    try {
      final models = await _datasource.getCategories();
      return Right(models.map(_mapCategory).toList());
    } on DioException catch (e) {
      // Lỗi 4xx/5xx từ BE → giữ lại `message` trong envelope để hiển thị UI.
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecommendedBoardGameEntity>>> runSurvey(
    DiscoveryRequestEntity request,
  ) async {
    try {
      final model = await _datasource.runSurvey(
        playerCount: request.playerCount,
        categoryIds: request.categoryIds,
        preferredDurations: request.preferredDurations,
        weightRanges: request.weightRanges,
        experienceLevel: request.experienceLevel,
        searchKeyword: request.searchKeyword,
      );
      return Right(model.games.map(_mapRecommendedGame).toList());
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
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
    try {
      final model = await _datasource.getSoloPersonalized(
        playerCount: request.playerCount,
        categoryIds: request.categoryIds,
        preferredDurations: request.preferredDurations,
        weightRanges: request.weightRanges,
        searchKeyword: request.searchKeyword,
        pageSize: pageSize,
        excludeSavedGames: excludeSavedGames,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(_mapSoloPersonalizedResponse(model));
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupBoardGameEntity>>> discoverForGroup({
    required List<MemberPreferenceRequest> members,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = members.map((m) {
        final map = <String, dynamic>{'playerCount': m.playerCount};
        if (m.userId != null) map['userId'] = m.userId;
        if (m.experienceLevel != null) map['experienceLevel'] = m.experienceLevel;
        if (m.categoryIds != null) map['categoryIds'] = m.categoryIds;
        if (m.preferredDurations != null) {
          map['preferredDurations'] = m.preferredDurations;
        }
        if (m.weightRanges != null) map['weightRanges'] = m.weightRanges;
        if (m.note != null) map['note'] = m.note;
        return map;
      }).toList();

      final model = await _datasource.discoverForGroup(
        members: body,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(model.games.map(_mapGroupGame).toList());
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SavedBoardGameEntity>>> getSavedGames() async {
    try {
      final model = await _datasource.getSavedGames();

      // Sync cache
      await _cache.replaceAll(model.savedGames.map((g) => g.gameTemplateId).toList());

      return Right(model.savedGames.map(_mapSavedGame).toList());
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  ) async {
    try {
      final model = await _datasource.toggleSave(gameTemplateId);
      // Sync cache
      if (model.isSaved) {
        await _cache.add(gameTemplateId);
      } else {
        await _cache.remove(gameTemplateId);
      }
      return Right(_mapSaveResult(model));
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> unsaveGame(String gameTemplateId) async {
    try {
      await _datasource.unsaveGame(gameTemplateId);
      await _cache.remove(gameTemplateId);
      return const Right(true);
    } on DioException catch (e) {
      return Left(DualFormatResponse.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<int> getSavedGamesCount() async {
    return _cache.count;
  }

  // ─── Mappers ────────────────────────────────────────────────────────

  GameCategoryDiscoveryEntity _mapCategory(dynamic model) {
    return GameCategoryDiscoveryEntity(
      id: model.id as String,
      name: model.name as String,
      slug: model.slug as String,
      sortOrder: model.sortOrder as int? ?? 0,
    );
  }

  RecommendedBoardGameEntity _mapRecommendedGame(dynamic model) {
    return RecommendedBoardGameEntity(
      id: model.id as String,
      name: model.name as String,
      imageUrl: model.imageUrl as String?,
      weight: model.weight as double?,
      minPlayers: model.minPlayers as int,
      maxPlayers: model.maxPlayers as int,
      playTimeMinutes: model.playTimeMinutes as int,
      categories: (model.categories as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      score: model.score as double,
      // API `isSaved` la canonical truth tu server (DB dã commit).
      // Neu API tra null (older BE) → fallback cache local (nhu
      // Personalized). Dam bao icon hien thi dung ngay khi render
      // (truoc khi SavedGamesCubit load xong danh sach saved).
      isSaved: model.isSaved as bool? ?? _cache.isSaved(model.id as String),
      matchReasons: (model.matchReasons as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }

  GroupBoardGameEntity _mapGroupGame(dynamic model) {
    final subGroupScores = (model.subGroupScores as List<dynamic>)
        .map((s) => SubGroupScoreEntity(
              subGroupIndex: s.subGroupIndex as int,
              playerCount: s.playerCount as int? ?? 0,
              experienceLevel: s.experienceLevel as int?,
              score: s.score as double,
              reason: s.reason as String?,
            ))
        .toList();

    return GroupBoardGameEntity(
      id: model.id as String,
      name: model.name as String,
      imageUrl: model.imageUrl as String?,
      description: model.description as String?,
      minPlayers: model.minPlayers as int,
      maxPlayers: model.maxPlayers as int,
      playTimeMinutes: model.playTimeMinutes as int,
      weight: model.weight as double?,
      categories: (model.categories as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      aggregateScore: model.aggregateScore as double,
      subGroupScores: subGroupScores,
    );
  }

  SoloPersonalizedResponseEntity _mapSoloPersonalizedResponse(dynamic model) {
    return SoloPersonalizedResponseEntity(
      games: (model.games as List<dynamic>)
          .map((g) => PersonalizedBoardGameEntity(
                id: g.id as String,
                name: g.name as String,
                imageUrl: g.imageUrl as String?,
                weight: g.weight as double?,
                minPlayers: g.minPlayers as int,
                maxPlayers: g.maxPlayers as int,
                playTimeMinutes: g.playTimeMinutes as int,
                categories: (g.categories as List<dynamic>)
                    .map((e) => e.toString())
                    .toList(),
                score: g.personalizedScore as double,
                matchReasons: (g.matchReasons as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                baseScore: g.baseScore as double,
                personalizationBoost: g.personalizationBoost as double,
                playHistoryPenalty: g.playHistoryPenalty as double,
                personalizedScore: g.personalizedScore as double,
                matchReason: g.matchReason as String?,
                isSaved: g.isSaved as bool? ?? _cache.isSaved(g.id as String),
                hasOpenLobby: g.hasOpenLobby as bool? ?? false,
                openLobbyId: g.openLobbyId as String?,
              ))
          .toList(),
      userProfile: model.userProfile != null
          ? UserGamePreferenceEntity(
              userId: model.userProfile!.userId as String,
              topCategoryIds:
                  (model.userProfile!.topCategoryIds as List<dynamic>)
                      .map((e) => e.toString())
                      .toList(),
              averageWeight: model.userProfile!.averageWeight as double,
              averageDuration: model.userProfile!.averageDuration as double,
              savedGameCount: model.userProfile!.savedGameCount as int,
            )
          : null,
      totalCount: model.totalCount as int,
      nearestCafe: model.nearestCafe != null
          ? NearbyCafeForGameEntity(
              cafeId: model.nearestCafe!.cafeId as String,
              cafeName: model.nearestCafe!.cafeName as String,
              cafeAddress: model.nearestCafe!.cafeAddress as String,
              distanceKm: model.nearestCafe!.distanceKm as double,
              availableGameIds:
                  (model.nearestCafe!.availableGameIds as List<dynamic>)
                      .map((e) => e.toString())
                      .toList(),
            )
          : null,
      openLobbies: (model.openLobbies as List<dynamic>)
          .map((l) => OpenLobbySummaryEntity(
                lobbyId: l.lobbyId as String,
                lobbyName: l.lobbyName as String,
                currentMembers: l.currentMembers as int,
                maxMembers: l.maxMembers as int,
                scheduledStartTime: l.scheduledStartTime as DateTime?,
              ))
          .toList(),
    );
  }

  SavedBoardGameEntity _mapSavedGame(dynamic model) {
    return SavedBoardGameEntity(
      id: model.id as String,
      gameTemplateId: model.gameTemplateId as String,
      gameName: model.gameName as String,
      thumbnailUrl: model.thumbnailUrl as String?,
      categories: (model.categories as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      weight: model.weight as double?,
      playTime: model.playTime as int?,
      savedAt: model.savedAt as DateTime,
    );
  }

  BoardGameSaveResultEntity _mapSaveResult(dynamic model) {
    return BoardGameSaveResultEntity(
      gameTemplateId: model.gameTemplateId as String,
      gameName: model.gameName as String,
      isSaved: model.isSaved as bool,
      savedAt: model.savedAt as DateTime?,
      message: model.message as String?,
    );
  }
}
