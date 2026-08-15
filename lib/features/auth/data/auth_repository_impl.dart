import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../domain/repositories/auth_repository.dart';
import 'datasources/auth_remote_datasource.dart';
import 'models/auth_tokens_model.dart';
import 'models/change_password_request_model.dart';
import 'models/google_login_request_model.dart';
import 'models/login_request_model.dart';
import 'models/register_request_model.dart';
import 'models/request_password_reset_request_model.dart';
import 'models/reset_password_request_model.dart';
import 'models/verify_email_request_model.dart';

/// Concrete implementation of [AuthRepository].
///
/// Delegates to [AuthRemoteDatasource] and maps exceptions into typed
/// [Failure] objects so the domain/presentation layers never see raw errors.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({required this._remoteDatasource});

  // ─── Login ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthTokensModel>> login(
    LoginRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.login(request);
      return Right(response.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Google Login ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthTokensModel>> googleLogin(
    GoogleLoginRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.googleLogin(request);
      return Right(response.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Register ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthTokensModel>> register(
    RegisterRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.register(request);
      return Right(response.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Send Email Verification ───────────────────────────────────────

  @override
  Future<Either<Failure, String>> sendEmailVerification(String email) async {
    try {
      final response = await _remoteDatasource.sendEmailVerification(email);
      return Right(response.message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Verify Email ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> verifyEmail(
    VerifyEmailRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.verifyEmail(request);
      return Right(response.message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> logout(String refreshToken) async {
    try {
      await _remoteDatasource.logout(refreshToken);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Request Password Reset ─────────────────────────────────────────

  @override
  Future<Either<Failure, String>> requestPasswordReset(
    RequestPasswordResetRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.requestPasswordReset(request);
      return Right(response.message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Reset Password ────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> resetPassword(
    ResetPasswordRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.resetPassword(request);
      return Right(response.message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Change Password ───────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> changePassword(
    ChangePasswordRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.changePassword(request);
      return Right(response.message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────

/// Converts [DioException] to the appropriate [Failure].
///
/// Network-level errors (no connectivity, timeout) become [NetworkFailure].
/// Server-level errors extract the backend message from the response envelope.
///
/// **Lưu ý quan trọng về format message**:
/// Backend trả về envelope chuẩn:
/// ```json
/// { "statusCode": 401, "message": "...", "data": null, ... }
/// ```
/// Field `message` là text hiển thị cho user (có thể kèm ký tự Unicode).
///
/// Nếu Dio trả về `response.data` không phải JSON hợp lệ (vd: HTML error
/// page từ proxy) → fallback sang `DioException.message` (tiếng Anh từ
/// Dio). Nếu cả 2 đều rỗng → dùng fallback tiếng Việt thân thiện.
Failure _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      // Case 1: response.data là Map (envelope chuẩn của backend).
      if (data is Map<String, dynamic>) {
        final rawMessage = data['message'];
        final messageStr = rawMessage is String ? rawMessage : null;
        if (messageStr != null && messageStr.isNotEmpty) {
          return ServerFailure(
            message: messageStr,
            statusCode: e.response?.statusCode,
          );
        }
      }
      // Case 2: response.data là String (vd: backend trả text thuần).
      if (data is String && data.isNotEmpty) {
        return ServerFailure(
          message: data,
          statusCode: e.response?.statusCode,
        );
      }
      // Case 3: Không parse được message — fallback Dio exception message
      // (tiếng Anh) hoặc generic tiếng Việt.
      return ServerFailure(
        message: e.message ??
            'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
        statusCode: e.response?.statusCode,
      );
    default:
      return ServerFailure(
        message: e.message ?? 'Đã xảy ra lỗi không mong muốn.',
      );
  }
}
}
