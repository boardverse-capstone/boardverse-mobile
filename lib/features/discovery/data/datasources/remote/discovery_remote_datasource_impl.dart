import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/dual_format_response.dart';
import '../../models/board_game_save_result_model.dart';
import '../../models/discovery_category_model.dart';
import '../../models/group_discovery_response_model.dart';
import '../../models/saved_games_response_model.dart';
import '../../models/solo_personalized_response_model.dart';
import '../../models/survey_response_model.dart';
import '../base/discovery_datasource.dart';

/// Remote implementation của [DiscoveryDatasource].
///
/// Gọi trực tiếp Discovery API qua Dio.
/// AuthInterceptor tự động attach Bearer token cho endpoints yêu cầu auth.
class DiscoveryRemoteDatasourceImpl implements DiscoveryDatasource {
  final Dio _dio;

  DiscoveryRemoteDatasourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<DiscoveryCategoryModel>> getCategories() async {
    final response = await _dio.get(ApiEndpoints.discoveryCategories);
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) {
        final list = (data as List<dynamic>? ?? []);
        return list
            .map((e) => DiscoveryCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
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
    final body = <String, dynamic>{};
    if (playerCount != null) body['playerCount'] = playerCount;
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['categoryIds'] = categoryIds;
    }
    if (preferredDurations != null && preferredDurations.isNotEmpty) {
      body['preferredDurations'] = preferredDurations;
    }
    if (weightRanges != null && weightRanges.isNotEmpty) {
      body['weightRanges'] = weightRanges;
    }
    if (experienceLevel != null) body['experienceLevel'] = experienceLevel;
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      body['searchKeyword'] = searchKeyword;
    }

    final response = await _dio.post(
      ApiEndpoints.discoverySurvey,
      data: body,
    );
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) => SurveyResponseModel.fromJson(data as Map<String, dynamic>),
    );
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
    final body = <String, dynamic>{
      'pageSize': pageSize,
      'excludeSavedGames': excludeSavedGames,
    };
    if (playerCount != null) body['playerCount'] = playerCount;
    if (categoryIds != null && categoryIds.isNotEmpty) {
      body['categoryIds'] = categoryIds;
    }
    if (preferredDurations != null && preferredDurations.isNotEmpty) {
      body['preferredDurations'] = preferredDurations;
    }
    if (weightRanges != null && weightRanges.isNotEmpty) {
      body['weightRanges'] = weightRanges;
    }
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      body['searchKeyword'] = searchKeyword;
    }

    final queryParams = <String, dynamic>{};
    if (latitude != null) queryParams['latitude'] = latitude;
    if (longitude != null) queryParams['longitude'] = longitude;

    final response = await _dio.post(
      ApiEndpoints.discoverySoloPersonalized,
      data: body,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) => SoloPersonalizedResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<GroupDiscoveryResponseModel> discoverForGroup({
    required List<Map<String, dynamic>> members,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'members': members};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _dio.post(
      ApiEndpoints.discoveryGroup,
      data: body,
    );
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) => GroupDiscoveryResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<SavedGamesResponseModel> getSavedGames() async {
    final response = await _dio.get(ApiEndpoints.discoverySavedList);
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) => SavedGamesResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<BoardGameSaveResultModel> toggleSave(String gameTemplateId) async {
    final response = await _dio.post(
      ApiEndpoints.discoverySavedToggle(gameTemplateId),
    );
    final parsed = DualFormatResponse.parse(response);

    return parsed.fold(
      (failure) => throw Exception(failure.message),
      (data) => BoardGameSaveResultModel.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<bool> unsaveGame(String gameTemplateId) async {
    final response = await _dio.delete(
      ApiEndpoints.discoverySavedDelete(gameTemplateId),
    );
    return DualFormatResponse.parseNoContent(response).fold(
      (failure) => throw Exception(failure.message),
      (_) => true,
    );
  }
}
