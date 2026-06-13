import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../domain/repositories/auth_repository.dart';
import 'datasources/auth_remote_datasource.dart';
import 'models/auth_tokens_model.dart';
import 'models/login_request_model.dart';
import 'models/register_request_model.dart';
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

  // ─── Register ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> register(
    RegisterRequestModel request,
  ) async {
    try {
      final response = await _remoteDatasource.register(request);
      return Right(response.message);
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

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Converts [DioException] to the appropriate [Failure].
  ///
  /// Network-level errors (no connectivity, timeout) become [NetworkFailure].
  /// Server-level errors extract the backend message from the response envelope.
  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        // Try to extract the backend message from the envelope.
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return ServerFailure(
            message: data['message'] as String,
            statusCode: e.response?.statusCode,
          );
        }
        return ServerFailure(
          message: e.message ?? 'Đã xảy ra lỗi không mong muốn.',
          statusCode: e.response?.statusCode,
        );
      default:
        return ServerFailure(
          message: e.message ?? 'Đã xảy ra lỗi không mong muốn.',
        );
    }
  }
}
