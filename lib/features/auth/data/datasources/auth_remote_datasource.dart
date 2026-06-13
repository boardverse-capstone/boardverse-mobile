import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_tokens_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/verify_email_request_model.dart';

/// Contract for remote auth operations.
abstract class AuthRemoteDatasource {
  /// Authenticates a user and returns the token pair.
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestModel request);

  /// Creates a new account. Returns the server message.
  Future<ApiResponse<void>> register(RegisterRequestModel request);

  /// Sends an OTP verification email. Returns the server message.
  Future<ApiResponse<void>> sendEmailVerification(String email);

  /// Verifies the OTP code. Returns the server message.
  Future<ApiResponse<void>> verifyEmail(VerifyEmailRequestModel request);
}

/// Implementation that talks to the BoardVerse REST API via [Dio].
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasourceImpl({required this._dio});

  // ─── Login ─────────────────────────────────────────────────────────

  @override
  Future<ApiResponse<AuthTokensModel>> login(
    LoginRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<AuthTokensModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (json) =>
          AuthTokensModel.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.isSuccess) {
      throw ServerException(
        message: apiResponse.message,
        statusCode: apiResponse.statusCode,
      );
    }

    return apiResponse;
  }

  // ─── Register ──────────────────────────────────────────────────────

  @override
  Future<ApiResponse<void>> register(RegisterRequestModel request) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<void>.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw ServerException(
        message: apiResponse.message,
        statusCode: apiResponse.statusCode,
      );
    }

    return apiResponse;
  }

  // ─── Send Email Verification ───────────────────────────────────────

  @override
  Future<ApiResponse<void>> sendEmailVerification(String email) async {
    final response = await _dio.post(
      ApiEndpoints.sendEmailVerification,
      data: {'email': email},
    );

    final apiResponse = ApiResponse<void>.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (!apiResponse.isSuccess) {
      throw ServerException(
        message: apiResponse.message,
        statusCode: apiResponse.statusCode,
      );
    }

    return apiResponse;
  }

  // ─── Verify Email ──────────────────────────────────────────────────

  @override
  Future<ApiResponse<void>> verifyEmail(
    VerifyEmailRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.verifyEmail,
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<void>.fromJson(
      response.data as Map<String, dynamic>,
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
