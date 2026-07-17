import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/network/auth_interceptor.dart';
import '../../data/models/auth_tokens_model.dart';
import '../../data/models/change_password_request_model.dart';
import '../../data/models/google_login_request_model.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/request_password_reset_request_model.dart';
import '../../data/models/reset_password_request_model.dart';
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
/// - Registration immediately persists returned tokens; verifying the OTP
///   then triggers an automatic login (no need to re-enter credentials).
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  /// Holds tokens returned from `register()` so a later `verifyEmail()`
  /// can auto-login the user without asking for credentials again.
  AuthTokensModel? _pendingTokens;

  AuthCubit({
    required AuthRepository repository,
    required FlutterSecureStorage storage,
  })  : _repository = repository,
        _storage = storage,
        super(const AuthInitial());

  // ─── Check Auth Status (Auto-login) ────────────────────────────────

  /// Checks if there's a valid stored token and auto-logins the user.
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      emit(const AuthInitial());
      return;
    }

    // Check if token is expired
    if (JwtDecoder.isExpired(token)) {
      await _clearTokens();
      emit(const AuthInitial());
      return;
    }

    // Token is valid, decode and emit success
    try {
      final claims = JwtDecoder.decode(token);

      final userId = claims[_JwtClaimKeys.nameIdentifier] as String? ?? '';
      final username = claims[_JwtClaimKeys.name] as String? ?? '';
      final email = claims[_JwtClaimKeys.email] as String? ?? '';
      final role = claims[_JwtClaimKeys.role] as String? ?? '';

      const allowedRoles = {'User', 'Player'};
      if (!allowedRoles.contains(role)) {
        emit(const AuthFailure(
          message: 'Tài khoản của bạn không có quyền truy cập trên điện thoại.',
        ));
        return;
      }

      final user = UserEntity(
        userId: userId,
        username: username,
        email: email,
        role: role,
      );

      emit(AuthSuccess(user: user));
    } catch (e) {
      await _clearTokens();
      emit(const AuthInitial());
    }
  }

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

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (tokens) async {
        _pendingTokens = null;
        await _handleLoginSuccess(tokens);
      },
    );
  }

  // ─── Google Login ──────────────────────────────────────────────────

  Future<void> googleLogin({required String idToken}) async {
    emit(const AuthLoading());

    final request = GoogleLoginRequestModel(idToken: idToken);
    final result = await _repository.googleLogin(request);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (tokens) async => await _handleLoginSuccess(tokens),
    );
  }

  // ─── Register ──────────────────────────────────────────────────────

  /// Registers a new account. The backend also returns a token pair so we
  /// store them and let the user be auto-logged-in right after OTP
  /// verification.
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

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (tokens) async {
        _pendingTokens = tokens;
        emit(AuthRegistered(message: 'Đăng ký thành công. Vui lòng xác minh OTP.'));
      },
    );
  }

  // ─── Send Email Verification ───────────────────────────────────────

  Future<void> sendEmailVerification({required String email}) async {
    emit(const AuthLoading());

    final result = await _repository.sendEmailVerification(email);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (message) async => emit(AuthEmailVerificationSent(message: message)),
    );
  }

  // ─── Verify Email ──────────────────────────────────────────────────

  /// Verifies the OTP and, if we already received a token from
  /// `register()`, automatically logs the user in.
  Future<void> verifyEmail({required String otpCode}) async {
    emit(const AuthLoading());

    final request = VerifyEmailRequestModel(token: otpCode);
    final result = await _repository.verifyEmail(request);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (message) async {
        // If we got tokens during registration, finish the auto-login flow.
        final pending = _pendingTokens;
        _pendingTokens = null;
        if (pending != null) {
          await _handleLoginSuccess(pending);
        } else {
          emit(AuthEmailVerified(message: message));
        }
      },
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────

  Future<void> logout() async {
    _pendingTokens = null;
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);

    // Call API to revoke refresh token (ignore errors)
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _repository.logout(refreshToken);
    }

    await _clearTokens();
    emit(const AuthInitial());
  }

  // ─── Request Password Reset ─────────────────────────────────────────

  Future<void> requestPasswordReset({required String email}) async {
    emit(const AuthLoading());

    final request = RequestPasswordResetRequestModel(email: email);
    final result = await _repository.requestPasswordReset(request);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (message) async =>
          emit(AuthPasswordResetRequested(message: message)),
    );
  }

  // ─── Reset Password ───────────────────────────────────────────────

  Future<void> resetPassword({
    required String otpCode,
    required String newPassword,
  }) async {
    emit(const AuthLoading());

    final request = ResetPasswordRequestModel(
      otpCode: otpCode,
      newPassword: newPassword,
    );
    final result = await _repository.resetPassword(request);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (message) async => emit(AuthPasswordResetSuccess(message: message)),
    );
  }

  // ─── Change Password ───────────────────────────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const AuthLoading());

    final request = ChangePasswordRequestModel(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final result = await _repository.changePassword(request);

    if (isClosed) return;
    await result.fold(
      (failure) async => emit(AuthFailure(message: failure.message)),
      (message) async => emit(AuthPasswordChanged(message: message)),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Persists tokens, extracts user info from the JWT and emits success.
  Future<void> _handleLoginSuccess(AuthTokensModel tokens) async {
    try {
      final claims = JwtDecoder.decode(tokens.token);

      final userId = claims[_JwtClaimKeys.nameIdentifier] as String? ?? '';
      final username = claims[_JwtClaimKeys.name] as String? ?? '';
      final email = claims[_JwtClaimKeys.email] as String? ?? '';
      final role = claims[_JwtClaimKeys.role] as String? ?? '';

      const allowedRoles = {'User', 'Player'};
      if (!allowedRoles.contains(role)) {
        emit(const AuthFailure(
          message: 'Tài khoản của bạn không có quyền truy cập trên điện thoại.',
        ));
        return;
      }

      // Persist tokens securely.
      await _storage.write(key: StorageKeys.accessToken, value: tokens.token);
      await _storage.write(
          key: StorageKeys.refreshToken, value: tokens.refreshToken);

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
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
