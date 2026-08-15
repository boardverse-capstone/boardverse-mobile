import 'package:dio/dio.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/exceptions.dart';
import 'package:boardverse/core/network/api_response.dart';
import 'package:boardverse/features/profile/data/models/create_profile_request_model.dart';
import 'package:boardverse/features/profile/data/models/karma_history_model.dart';
import 'package:boardverse/features/profile/data/models/player_location_model.dart';
import 'package:boardverse/features/profile/data/models/profile_model.dart';
import 'package:boardverse/features/profile/data/models/update_avatar_request_model.dart';
import 'package:boardverse/features/profile/data/models/update_location_request_model.dart';
import 'package:boardverse/features/profile/data/models/update_profile_request_model.dart';
import 'package:boardverse/features/profile/data/models/update_progress_request_model.dart';

/// Thin abstraction over the REST API for the User Profile feature.
///
/// All methods translate transport errors (`DioException`) and parse errors
/// (`FormatException`, `TypeError`) into a single [ServerException] so the
/// repository layer can map to a [Failure] without re-implementing the
/// translation logic.
abstract class ProfileRemoteDatasource {
  Future<ApiResponse<ProfileModel>> getProfile();
  Future<ApiResponse<ProfileModel>> createProfile(
    CreateProfileRequestModel request,
  );
  Future<ApiResponse<ProfileModel>> updateProfile(
    UpdateProfileRequestModel request,
  );
  Future<ApiResponse<ProfileModel>> updateAvatar(
    UpdateAvatarRequestModel request,
  );
  Future<ApiResponse<ProfileModel>> deleteProfile();
  Future<ApiResponse<PlayerLocationModel>> getLocation();
  Future<ApiResponse<PlayerLocationModel>> updateLocation(
    UpdateLocationRequestModel request,
  );
  Future<ApiResponse<void>> deleteLocation();
  Future<ApiResponse<KarmaHistoryModel>> getKarmaHistory();
  Future<ApiResponse<ProfileModel>> updateProgress(
    UpdateProgressRequestModel request,
  );
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final Dio dio;

  ProfileRemoteDatasourceImpl({required this.dio});

  @override
  Future<ApiResponse<ProfileModel>> getProfile() => _request<ProfileModel>(
        RequestType.get,
        ApiEndpoints.userProfile,
        fromJson: ProfileModel.fromJson,
      );

  @override
  Future<ApiResponse<ProfileModel>> createProfile(
    CreateProfileRequestModel request,
  ) =>
      _request<ProfileModel>(
        RequestType.post,
        ApiEndpoints.userProfile,
        body: request.toJson(),
        fromJson: ProfileModel.fromJson,
      );

  @override
  Future<ApiResponse<ProfileModel>> updateProfile(
    UpdateProfileRequestModel request,
  ) =>
      _request<ProfileModel>(
        RequestType.put,
        ApiEndpoints.userProfile,
        body: request.toJson(),
        fromJson: ProfileModel.fromJson,
      );

  @override
  Future<ApiResponse<ProfileModel>> updateAvatar(
    UpdateAvatarRequestModel request,
  ) =>
      _request<ProfileModel>(
        RequestType.put,
        ApiEndpoints.userProfileAvatar,
        body: request.toJson(),
        fromJson: ProfileModel.fromJson,
      );

  @override
  Future<ApiResponse<ProfileModel>> deleteProfile() =>
      _request<ProfileModel>(RequestType.delete, ApiEndpoints.userProfile);

  @override
  Future<ApiResponse<PlayerLocationModel>> getLocation() => _request(
        RequestType.get,
        ApiEndpoints.userProfileLocation,
        fromJson: PlayerLocationModel.fromJson,
      );

  @override
  Future<ApiResponse<PlayerLocationModel>> updateLocation(
    UpdateLocationRequestModel request,
  ) =>
      _request<PlayerLocationModel>(
        RequestType.put,
        ApiEndpoints.userProfileLocation,
        body: request.toJson(),
        fromJson: PlayerLocationModel.fromJson,
      );

  @override
  Future<ApiResponse<void>> deleteLocation() =>
      _request<void>(RequestType.delete, ApiEndpoints.userProfileLocation);

  @override
  Future<ApiResponse<KarmaHistoryModel>> getKarmaHistory() => _request(
        RequestType.get,
        ApiEndpoints.userProfileKarmaHistory,
        fromJson: KarmaHistoryModel.fromJson,
      );

  @override
  Future<ApiResponse<ProfileModel>> updateProgress(
    UpdateProgressRequestModel request,
  ) =>
      _request<ProfileModel>(
        RequestType.post,
        ApiEndpoints.userProfileProgress,
        body: request.toJson(),
        fromJson: ProfileModel.fromJson,
      );

  /// Single central pipeline that:
  /// 1. Executes the HTTP call against [path].
  /// 2. Parses the response into an [ApiResponse] using [fromJson].
  /// 3. Throws a [ServerException] for any non-2xx, network, or parse error.
  ///
  /// [fromJson] is required when the response body carries typed data. It
  /// can be omitted for endpoints (e.g. `delete*`) that return `null` data.
  Future<ApiResponse<T>> _request<T>(
    RequestType method,
    String path, {
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dispatch(method, path, body);
      final data = response.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<T>.fromJson(
        data,
        fromJsonT: fromJson == null
            ? null
            : (dynamic json) => fromJson(json as Map<String, dynamic>),
      );
      if (!apiResponse.isSuccess) {
        throw ServerException(
          message: apiResponse.message,
          statusCode: apiResponse.statusCode,
        );
      }
      return apiResponse;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Lỗi kết nối. Vui lòng thử lại.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(
        message: 'Dữ liệu phản hồi không hợp lệ. Chi tiết: $e',
      );
    }
  }

  Future<Response<dynamic>> _dispatch(
    RequestType method,
    String path,
    Object? body,
  ) {
    switch (method) {
      case RequestType.get:
        return dio.get(path);
      case RequestType.post:
        return dio.post(path, data: body);
      case RequestType.put:
        return dio.put(path, data: body);
      case RequestType.delete:
        return dio.delete(path);
    }
  }
}

enum RequestType { get, post, put, delete }
