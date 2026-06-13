import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/auth_tokens_model.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/verify_email_request_model.dart';

/// Contract for auth operations consumed by the domain / presentation layers.
///
/// Returns [Either<Failure, T>] so callers can handle errors in a
/// type-safe, functional way without try-catch.
abstract class AuthRepository {
  /// Authenticates a user and returns the token pair on success.
  Future<Either<Failure, AuthTokensModel>> login(LoginRequestModel request);

  /// Registers a new account. Returns the server success message.
  Future<Either<Failure, String>> register(RegisterRequestModel request);

  /// Sends an OTP verification email. Returns the server message.
  Future<Either<Failure, String>> sendEmailVerification(String email);

  /// Verifies the OTP code. Returns the server message.
  Future<Either<Failure, String>> verifyEmail(VerifyEmailRequestModel request);
}
