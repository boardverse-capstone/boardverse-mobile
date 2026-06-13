import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../models/create_profile_request_model.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDatasource {
  Future<ApiResponse<ProfileModel>> getProfile();
  Future<ApiResponse<ProfileModel>> createProfile(CreateProfileRequestModel request);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final Dio dio;

  ProfileRemoteDatasourceImpl({required this.dio});

  @override
  Future<ApiResponse<ProfileModel>> getProfile() async {
    final response = await dio.get(ApiEndpoints.userProfile);

    try {
      final apiResponse = ApiResponse<ProfileModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (json) => ProfileModel.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess) {
        throw ServerException(
          message: apiResponse.message,
          statusCode: apiResponse.statusCode,
        );
      }

      return apiResponse;
    } catch (e) {
      throw ServerException(
        message: 'Lỗi parse JSON. Response: ${response.data}. Chi tiết: $e',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<ApiResponse<ProfileModel>> createProfile(
    CreateProfileRequestModel request,
  ) async {
    final response = await dio.post(
      ApiEndpoints.userProfile,
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<ProfileModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (json) => ProfileModel.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.isSuccess) {
      throw ServerException(
        message: apiResponse.message,
        statusCode: apiResponse.statusCode,
      );
    }

    return apiResponse;
  }
}
