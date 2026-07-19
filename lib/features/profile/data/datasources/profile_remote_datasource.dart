import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/constants/api_endpoints.dart';
import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/core/network/api_response.dart';
import 'package:boardverse_mobile/features/profile/data/models/create_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/karma_history_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/player_location_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/profile_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_avatar_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_location_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_progress_request_model.dart';

abstract class ProfileRemoteDatasource {
  Future<ApiResponse<ProfileModel> > getProfile();
  Future<ApiResponse<ProfileModel> > createProfile(CreateProfileRequestModel request);
  Future<ApiResponse<ProfileModel> > updateProfile(UpdateProfileRequestModel request);
  Future<ApiResponse<ProfileModel> > updateAvatar(UpdateAvatarRequestModel request);
  Future<ApiResponse<ProfileModel> > deleteProfile();
  Future<ApiResponse<PlayerLocationModel> > getLocation();
  Future<ApiResponse<PlayerLocationModel> > updateLocation(UpdateLocationRequestModel request);
  Future<ApiResponse<void> > deleteLocation();
  Future<ApiResponse<KarmaHistoryModel> > getKarmaHistory();
  Future<ApiResponse<ProfileModel> > updateProgress(UpdateProgressRequestModel request);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final Dio dio;

  ProfileRemoteDatasourceImpl({required this.dio});

  // ─── Helpers ─────────────────────────────────────────────────────────────

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final apiResponse = ApiResponse<T>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => fromJson(data as Map<String, dynamic>),
    );
    return apiResponse;
  }

  ServerException _createParseException(dynamic e, DioException? dioException) {
    if (e is DioException) {
      return ServerException(
        message: e.message ?? 'Lỗi kết nối. Vui lòng thử lại.',
        statusCode: e.response?.statusCode,
      );
    }
    if (e is FormatException || e is TypeError) {
      return ServerException(
        message: 'Dữ liệu phản hồi không hợp lệ. Chi tiết: ${e.toString()}',
        statusCode: dioException?.response?.statusCode,
      );
    }
    return ServerException(
      message: 'Đã xảy ra lỗi không mong muốn. Chi tiết: $e',
      statusCode: dioException?.response?.statusCode,
    );
  }

  // ─── Existing methods ─────────────────────────────────────────────────────

  @override
  Future<ApiResponse<ProfileModel> > getProfile() async {
    try {
      final response = await dio.get(ApiEndpoints.userProfile);
      final apiResponse = _parseResponse<ProfileModel>(
        response,
        ProfileModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi lấy thông tin cá nhân.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<ProfileModel> > createProfile(
    CreateProfileRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.userProfile,
        data: request.toJson(),
      );
      final apiResponse = _parseResponse<ProfileModel>(
        response,
        ProfileModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi tạo hồ sơ.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  // ─── New methods ─────────────────────────────────────────────────────────

  @override
  Future<ApiResponse<ProfileModel> > updateProfile(
    UpdateProfileRequestModel request,
  ) async {
    try {
      final response = await dio.put(
        ApiEndpoints.userProfile,
        data: request.toJson(),
      );
      final apiResponse = _parseResponse<ProfileModel>(
        response,
        ProfileModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi cập nhật hồ sơ.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<ProfileModel> > updateAvatar(
    UpdateAvatarRequestModel request,
  ) async {
    try {
      final response = await dio.put(
        ApiEndpoints.userProfileAvatar,
        data: request.toJson(),
      );
      final apiResponse = _parseResponse<ProfileModel>(
        response,
        ProfileModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi cập nhật ảnh đại diện.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<ProfileModel> > deleteProfile() async {
    try {
      final response = await dio.delete(ApiEndpoints.userProfile);
      final apiResponse = ApiResponse<ProfileModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => data == null
            ? null as dynamic
            : ProfileModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Lỗi kết nối khi xoá hồ sơ.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<PlayerLocationModel> > getLocation() async {
    try {
      final response = await dio.get(ApiEndpoints.userProfileLocation);
      final apiResponse = _parseResponse<PlayerLocationModel>(
        response,
        PlayerLocationModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi lấy vị trí.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<PlayerLocationModel> > updateLocation(
    UpdateLocationRequestModel request,
  ) async {
    try {
      final response = await dio.put(
        ApiEndpoints.userProfileLocation,
        data: request.toJson(),
      );
      final apiResponse = _parseResponse<PlayerLocationModel>(
        response,
        PlayerLocationModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi cập nhật vị trí.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<void> > deleteLocation() async {
    try {
      final response = await dio.delete(ApiEndpoints.userProfileLocation);
      final apiResponse = ApiResponse<void>.fromJson(
        response.data as Map<String, dynamic>,
      );
      return apiResponse;
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Lỗi kết nối khi xoá vị trí.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<KarmaHistoryModel> > getKarmaHistory() async {
    try {
      final response = await dio.get(ApiEndpoints.userProfileKarmaHistory);
      final apiResponse = _parseResponse<KarmaHistoryModel>(
        response,
        KarmaHistoryModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi lấy lịch sử karma.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }

  @override
  Future<ApiResponse<ProfileModel> > updateProgress(
    UpdateProgressRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.userProfileProgress,
        data: request.toJson(),
      );
      final apiResponse = _parseResponse<ProfileModel>(
        response,
        ProfileModel.fromJson,
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
        message: e.message ?? 'Lỗi kết nối khi cập nhật tiến trình.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw _createParseException(e, null);
    }
  }
}
