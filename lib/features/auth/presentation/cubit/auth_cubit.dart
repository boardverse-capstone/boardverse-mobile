import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/network/auth_interceptor.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/verify_email_request_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// JWT claim keys used by the .NET backend (XML Soap format).
class _JwtClaimKeys {
  _JwtClaimKeys._();

  static const String nameIdentifier =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  static const String name =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
  static const String email =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';
  static const String role =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
}

/// Cubit managing the authentication lifecycle.
///
/// Key behaviour:
/// - After a successful login, the JWT is decoded and the role is checked.
/// - Only `"User"` role is allowed on mobile. Any other role triggers
///   [AuthFailure] with a warning message and tokens are **not** persisted.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthCubit({
    required this._repository,
    required this._storage,
  })  : super(const AuthInitial());

  // ─── Login ─────────────────────────────────────────────────────────

  Future<void> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    emit(const AuthLoading());

    final request = LoginRequestModel(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );

    final result = await _repository.login(request);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (tokens) async {
        try {
          // Decode the JWT to extract claims.
          final claims = JwtDecoder.decode(tokens.token);

          final userId =
              claims[_JwtClaimKeys.nameIdentifier] as String? ?? '';
          final username = claims[_JwtClaimKeys.name] as String? ?? '';
          final email = claims[_JwtClaimKeys.email] as String? ?? '';
          final role = claims[_JwtClaimKeys.role] as String? ?? '';

          // ── Role gate: mobile app only allows "User" or "Player" ──
          const allowedRoles = {'User', 'Player'};
          if (!allowedRoles.contains(role)) {
            emit(const AuthFailure(
              message:
                  'Tài khoản của bạn không có quyền truy cập trên điện thoại.',
            ));
            return;
          }

          // Persist tokens securely.
          await _storage.write(
            key: StorageKeys.accessToken,
            value: tokens.token,
          );
          await _storage.write(
            key: StorageKeys.refreshToken,
            value: tokens.refreshToken,
          );

          final user = UserEntity(
            userId: userId,
            username: username,
            email: email,
            role: role,
          );

          emit(AuthSuccess(user: user));
        } catch (e) {
          emit(AuthFailure(message: 'Lỗi xử lý token: ${e.toString()}'));
        }
      },
    );
  }

  // ─── Register ──────────────────────────────────────────────────────

  Future<void> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    emit(const AuthLoading());

    final request = RegisterRequestModel(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );

    final result = await _repository.register(request);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (message) => emit(AuthRegistered(message: message)),
    );
  }

  // ─── Send Email Verification ───────────────────────────────────────

  Future<void> sendEmailVerification({required String email}) async {
    emit(const AuthLoading());

    final result = await _repository.sendEmailVerification(email);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (message) => emit(AuthEmailVerificationSent(message: message)),
    );
  }

  // ─── Verify Email ──────────────────────────────────────────────────

  Future<void> verifyEmail({required String otpCode}) async {
    emit(const AuthLoading());

    final request = VerifyEmailRequestModel(token: otpCode);
    final result = await _repository.verifyEmail(request);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (message) => emit(AuthEmailVerified(message: message)),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    emit(const AuthInitial());
  }
}
