import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../models/auth_tokens_model.dart';
import '../models/change_password_request_model.dart';
import '../models/google_login_request_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/request_password_reset_request_model.dart';
import '../models/reset_password_request_model.dart';
import '../models/verify_email_request_model.dart';

/// Contract for remote auth operations.
abstract class AuthRemoteDatasource {
  /// Authenticates a user and returns the token pair.
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestModel request);

  /// Authenticates via Google and returns the token pair.
  Future<ApiResponse<AuthTokensModel>> googleLogin(GoogleLoginRequestModel request);

  /// Creates a new account and returns the token pair.
  Future<ApiResponse<AuthTokensModel>> register(RegisterRequestModel request);

  /// Sends an OTP verification email. Returns the server message.
  Future<ApiResponse<void>> sendEmailVerification(String email);

  /// Verifies the OTP code. Returns the server message.
  Future<ApiResponse<void>> verifyEmail(VerifyEmailRequestModel request);

  /// Logs out the user by revoking the refresh token.
  Future<ApiResponse<void>> logout(String refreshToken);

  /// Requests a password reset email. Returns the server message.
  Future<ApiResponse<void>> requestPasswordReset(RequestPasswordResetRequestModel request);

  /// Resets the password using OTP. Returns the server message.
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequestModel request);

  /// Changes the user's password. Requires authorization header.
  Future<ApiResponse<void>> changePassword(ChangePasswordRequestModel request);
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

  // ─── Google Login ─────────────────────────────────────────────────

  @override
  Future<ApiResponse<AuthTokensModel>> googleLogin(
    GoogleLoginRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.googleLogin,
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
  Future<ApiResponse<AuthTokensModel>> register(
    RegisterRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.register,
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

  // ─── Logout ───────────────────────────────────────────────────────

  @override
  Future<ApiResponse<void>> logout(String refreshToken) async {
    final response = await _dio.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
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

  // ─── Request Password Reset ─────────────────────────────────────────

  @override
  Future<ApiResponse<void>> requestPasswordReset(
    RequestPasswordResetRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.requestPasswordReset,
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

  // ─── Reset Password ────────────────────────────────────────────────

  @override
  Future<ApiResponse<void>> resetPassword(
    ResetPasswordRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.resetPassword,
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

  // ─── Change Password ───────────────────────────────────────────────

  @override
  Future<ApiResponse<void>> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.changePassword,
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
