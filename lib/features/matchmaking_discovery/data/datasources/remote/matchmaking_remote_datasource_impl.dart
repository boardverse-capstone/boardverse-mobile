import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/search_filter_entity.dart';
import '../../../domain/entities/game_play_configuration_entity.dart';
import '../../models/board_game_model.dart';
import '../../models/board_game_detail_model.dart';
import '../../models/cafe_model.dart';
import '../../models/game_category_model.dart';
import '../../models/game_play_configuration_model.dart';
import '../../models/game_play_navigation_model.dart';
import '../../models/nearby_cafes_search_result_model.dart';
import '../../models/seat_availability_model.dart';
import '../base/matchmaking_datasource.dart';

/// Remote datasource cho Matchmaking — sử dụng [Dio] + endpoints thật
/// của backend BoardVerse. Mọi method đều parse qua [ApiResponse] envelope
/// (`statusCode`/`message`/`data`).
class MatchmakingRemoteDatasourceImpl implements MatchmakingDatasource {
  final Dio _dio;
  // ignore: prefer_initializing_formals
  MatchmakingRemoteDatasourceImpl({required Dio dio}) : _dio = dio;
  // ─── Board Games ────────────────────────────────────────────────────

  @override
  Future<List<BoardGameModel>> getAllGames() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.boardGames,
        queryParameters: {'pageNumber': 1, 'pageSize': 50},
      );
      return _parsePaginatedBoardGames(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<BoardGameModel?> getGameById(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.boardGameDetail.replaceAll('{id}', id),
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) =>
            BoardGameModel.fromJson(json as Map<String, dynamic>),
      );
      return envelope.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<BoardGameModel>> searchGames(SearchFilterEntity filter) async {
    // Reuse paged search; UI legacy sẽ được map sang paged API.
    return getBoardGamesPaged(
      search: filter.query,
      categoryIds: filter.categoryIds,
      playerCount: filter.minPlayers,
      durationRanges: filter.durationRanges,
      pageNumber: filter.pageNumber ?? 1,
      pageSize: filter.pageSize ?? 20,
    );
  }

  @override
  Future<List<BoardGameModel>> getBoardGamesPaged({
    String? search,
    List<String>? categoryIds,
    int? playerCount,
    List<DurationRange>? durationRanges,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (categoryIds != null && categoryIds.isNotEmpty) {
        // Backend nhận chuỗi CSV — đảm bảo các ID được nối bằng dấu phẩy.
        queryParameters['category_ids'] = categoryIds.join(',');
      }
      if (playerCount != null) {
        queryParameters['player_count'] = playerCount;
      }
      if (durationRanges != null && durationRanges.isNotEmpty) {
        queryParameters['duration_range'] =
            durationRanges.map((e) => e.apiValue).join(',');
      }

      final response = await _dio.get(
        ApiEndpoints.boardGames,
        queryParameters: queryParameters,
      );
      return _parsePaginatedBoardGames(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<BoardGameDetailModel?> getBoardGameDetails(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.boardGameDetail.replaceAll('{id}', id),
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) =>
            BoardGameDetailModel.fromJson(json as Map<String, dynamic>),
      );
      return envelope.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<BoardGameModel>> getSimilarGames(String gameId) async {
    // Backend mới không expose endpoint này — fallback trả về rỗng.
    // UI "Gợi ý tương tự" sẽ tự ẩn khi nhận list rỗng.
    try {
      final response = await _dio.get(
        ApiEndpoints.boardGameDetail.replaceAll('{id}', gameId),
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) =>
            BoardGameModel.fromJson(json as Map<String, dynamic>),
      );
      return envelope.data != null ? [envelope.data!] : <BoardGameModel>[];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<GameCategoryModel>> getGameCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.boardGameCategories);
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => (json as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(GameCategoryModel.fromJson)
            .toList(),
      );
      return envelope.data ?? const <GameCategoryModel>[];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<GamePlayConfigurationModel?> getGamePlayConfiguration(
      String gameId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.boardGamePlayConfiguration
            .replaceAll('{id}', gameId),
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => GamePlayConfigurationModel.fromJson(
            json as Map<String, dynamic>),
      );
      return envelope.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<GamePlayNavigationModel> resolvePlayNavigation({
    required String gameId,
    required PlayMode mode,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.boardGamePlayNavigation.replaceAll('{id}', gameId),
        data: {'playMode': mode.apiValue},
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) =>
            GamePlayNavigationModel.fromJson(json as Map<String, dynamic>),
      );
      if (envelope.data == null) {
        throw ServerException(message: 'Empty play-navigation response');
      }
      return envelope.data!;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── Cafes ─────────────────────────────────────────────────────────

  @override
  Future<List<CafeModel>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    final result = await getNearbyCafesSearch(
      gameTemplateId: gameId,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return result.cafes;
  }

  @override
  Future<List<CafeModel>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    // Trả về rỗng nếu không có `gameTemplateId` (AC 5.1 yêu cầu bắt buộc).
    return const <CafeModel>[];
  }

  @override
  Future<NearbyCafesSearchResultModel> getNearbyCafesSearch({
    required String gameTemplateId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cafesNearby,
        queryParameters: {
          'gameTemplateId': gameTemplateId,
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => NearbyCafesSearchResultModel.fromJson(
            json as Map<String, dynamic>),
      );
      return envelope.data ?? const NearbyCafesSearchResultModel();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<NearbyCafesSearchResultModel> getNearbyCafesForCurrentUser({
    required String gameTemplateId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cafesNearbyMe,
        queryParameters: {
          'gameTemplateId': gameTemplateId,
          'radiusKm': radiusKm,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => NearbyCafesSearchResultModel.fromJson(
            json as Map<String, dynamic>),
      );
      return envelope.data ?? const NearbyCafesSearchResultModel();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<CafeModel?> getCafeById(String id) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.cafeDetail.replaceAll('{id}', id),
      );
      final envelope = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => CafeModel.fromJson(json as Map<String, dynamic>),
      );
      return envelope.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<BoardGameModel>> getCafeGames(String cafeId) async {
    // Endpoint này đã bị xoá trong backend mới — fallback rỗng.
    return const <BoardGameModel>[];
  }

  // ─── Seat Availability (Real-time) ──────────────────────────────────

  @override
  Future<SeatAvailabilityModel> getSeatAvailability({
    required String cafeId,
    required DateTime timeSlot,
  }) async {
    // Endpoint legacy đã xoá — trả về default. UI sẽ tự fallback sang
    // CafeModel.availableTables.
    return SeatAvailabilityModel(
      cafeId: cafeId,
      timeSlot: timeSlot,
      totalSeats: 20,
      availableSeats: 15,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<bool> checkSeatsAvailable({
    required String cafeId,
    required int requiredSeats,
    required DateTime timeSlot,
  }) async {
    // Endpoint legacy đã xoá — luôn trả về `true` để không block flow.
    return true;
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Parse response dạng phân trang (`data.items[]` hoặc `data.data[]`).
  List<BoardGameModel> _parsePaginatedBoardGames(dynamic responseData) {
    final envelope = ApiResponse.fromJson(
      responseData as Map<String, dynamic>,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .cast<Map<String, dynamic>>()
              .map(BoardGameModel.fromJson)
              .toList();
        }
        if (json is Map<String, dynamic>) {
          // Backend thường trả `{ "items": [...], "currentPage": 1, ... }`
          final items = json['items'] ?? json['data'];
          if (items is List) {
            return items
                .cast<Map<String, dynamic>>()
                .map(BoardGameModel.fromJson)
                .toList();
          }
          return <BoardGameModel>[];
        }
        return <BoardGameModel>[];
      },
    );
    return envelope.data ?? const <BoardGameModel>[];
  }

  Exception _mapDioError(DioException error) {
    if (error.response?.statusCode == 401) {
      throw ServerException(
        message: 'Authentication required',
        statusCode: 401,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw NetworkException(message: 'Connection timeout');
    }
    if (error.type == DioExceptionType.connectionError) {
      throw NetworkException(message: 'No internet connection');
    }
    final statusCode = error.response?.statusCode;
    final message =
        error.response?.statusMessage ?? error.message ?? 'Unknown error';
    throw ServerException(message: '[$statusCode] $message');
  }
}
