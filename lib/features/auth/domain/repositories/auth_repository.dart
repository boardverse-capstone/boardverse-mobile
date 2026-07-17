import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/auth_tokens_model.dart';
import '../../data/models/change_password_request_model.dart';
import '../../data/models/google_login_request_model.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/request_password_reset_request_model.dart';
import '../../data/models/reset_password_request_model.dart';
import '../../data/models/verify_email_request_model.dart';

/// Contract for auth operations consumed by the domain / presentation layers.
///
/// Returns [Either<Failure, T>] so callers can handle errors in a
/// type-safe, functional way without try-catch.
abstract class AuthRepository {
  /// Authenticates a user and returns the token pair on success.
  Future<Either<Failure, AuthTokensModel>> login(LoginRequestModel request);

  /// Authenticates via Google and returns the token pair.
  Future<Either<Failure, AuthTokensModel>> googleLogin(GoogleLoginRequestModel request);

  /// Registers a new account and returns the token pair for auto-login.
  Future<Either<Failure, AuthTokensModel>> register(RegisterRequestModel request);

  /// Sends an OTP verification email. Returns the server message.
  Future<Either<Failure, String>> sendEmailVerification(String email);

  /// Verifies the OTP code. Returns the server message.
  Future<Either<Failure, String>> verifyEmail(VerifyEmailRequestModel request);

  /// Logs out the user by revoking the refresh token.
  Future<Either<Failure, void>> logout(String refreshToken);

  /// Requests a password reset email. Returns the server message.
  Future<Either<Failure, String>> requestPasswordReset(RequestPasswordResetRequestModel request);

  /// Resets the password using OTP. Returns the server message.
  Future<Either<Failure, String>> resetPassword(ResetPasswordRequestModel request);

  /// Changes the user's password. Returns the server message.
  Future<Either<Failure, String>> changePassword(ChangePasswordRequestModel request);
}
