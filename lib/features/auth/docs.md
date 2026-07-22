# Auth Feature Module

## Overview

Module xử lý authentication và authorization cho toàn bộ ứng dụng. Bao gồm đăng nhập, đăng ký, OAuth (Google), xác thực email (OTP), và quản lý mật khẩu.

**Tổng số file**: 39 files

---

## 1. Architecture

```
lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart    # API calls via Dio
│   ├── models/                            # Request/Response DTOs
│   │   ├── auth_tokens_model.dart
│   │   ├── login_request_model.dart
│   │   ├── register_request_model.dart
│   │   ├── google_login_request_model.dart
│   │   ├── verify_email_request_model.dart
│   │   ├── change_password_request_model.dart
│   │   ├── request_password_reset_request_model.dart
│   │   └── reset_password_request_model.dart
│   └── auth_repository_impl.dart           # Repository implementation
├── domain/
│   ├── entities/
│   │   └── user_entity.dart              # User entity
│   └── repositories/
│       └── auth_repository.dart           # Repository interface
└── presentation/
    ├── cubit/
    │   ├── auth_cubit.dart               # State management
    │   └── auth_state.dart               # Sealed state classes
    ├── pages/
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   ├── verify_email_page.dart
    │   ├── forgot_password_page.dart
    │   ├── reset_password_page.dart
    │   └── change_password_page.dart
    └── widgets/
        ├── auth_gradient_background.dart
        ├── auth_logo.dart
        ├── auth_text_field.dart
        ├── auth_buttons.dart
        ├── auth_components.dart
        ├── auth_helpers.dart
        └── widgets.dart (barrel export)
```

---

## 2. Key Classes

### AuthCubit

Trung tâm state management cho tất cả authentication operations.

**Methods:**

| Method | Purpose |
|--------|---------|
| `checkAuthStatus()` | Auto-login on app launch if valid JWT exists |
| `login(usernameOrEmail, password)` | Standard credential login |
| `googleLogin(idToken)` | Google OAuth login |
| `register(username, email, phoneNumber, password)` | New account registration |
| `sendEmailVerification(email)` | Resend OTP code |
| `verifyEmail(otpCode)` | Verify OTP; auto-login if tokens pending |
| `logout()` | Clear tokens and revoke refresh token |
| `requestPasswordReset(email)` | Request password reset email |
| `resetPassword(otpCode, newPassword)` | Complete password reset |
| `changePassword(currentPassword, newPassword)` | Change authenticated user's password |

**Key Behavior:**
- Decodes JWT claims using `JwtDecoder` để extract `userId`, `username`, `email`, `role`
- Chỉ cho phép role `User` hoặc `Player` trên mobile
- Stores pending tokens sau registration cho auto-login sau OTP verification
- Persists tokens in `FlutterSecureStorage`

### AuthState (Sealed Classes)

| State | Trigger |
|-------|---------|
| `AuthInitial` | No auth, app start (no token) |
| `AuthLoading` | Any async operation in progress |
| `AuthSuccess` | Login/register/verify successful with user |
| `AuthFailure` | Any operation failed |
| `AuthRegistered` | Registration successful, awaiting OTP |
| `AuthEmailVerificationSent` | OTP email sent |
| `AuthEmailVerified` | OTP verified (no auto-login) |
| `AuthPasswordResetRequested` | Reset email sent |
| `AuthPasswordResetSuccess` | Password reset completed |
| `AuthPasswordChanged` | Password changed successfully |

### UserEntity

```dart
class UserEntity extends Equatable {
  final String userId;      // From JWT 'nameidentifier' claim
  final String username;    // From JWT 'name' claim
  final String email;      // From JWT 'emailaddress' claim
  final String role;        // From JWT 'role' claim (User/Player)
}
```

---

## 3. API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/Auth/login` | POST | Standard credential login |
| `/api/Auth/register` | POST | Create new account |
| `/api/Auth/google-login` | POST | Google OAuth authentication |
| `/api/Auth/refresh-token` | POST | Get new access token |
| `/api/Auth/logout` | POST | Revoke refresh token |
| `/api/Auth/send-email-verification` | POST | Send OTP to email |
| `/api/Auth/verify-email` | POST | Verify OTP code |
| `/api/Auth/request-password-reset` | POST | Request password reset email |
| `/api/Auth/reset-password` | POST | Complete password reset with OTP |
| `/api/Auth/change-password` | POST | Change password (authenticated) |

---

## 4. Business Logic Flow

### Login Flow

```
User enters credentials
       ↓
AuthCubit.login() → AuthRepository.login()
       ↓
AuthRemoteDatasource calls POST /api/Auth/login
       ↓
Server returns { token, refreshToken }
       ↓
JwtDecoder extracts claims (userId, username, email, role)
       ↓
Token role validated (must be User or Player)
       ↓
Tokens persisted to FlutterSecureStorage
       ↓
AuthSuccess(user) emitted
       ↓
UI navigates to MainScaffold
```

### Registration + Email Verification Flow

```
User fills registration form
       ↓
AuthCubit.register() → POST /api/Auth/register
       ↓
Server returns tokens + sends OTP email
       ↓
AuthRegistered state emitted
       ↓
Navigate to VerifyEmailPage
       ↓
User enters 6-digit OTP
       ↓
AuthCubit.verifyEmail() → POST /api/Auth/verify-email
       ↓
Pending tokens from registration used for auto-login
       ↓
AuthSuccess emitted, navigate to MainScaffold
```

---

## 5. File Interactions

```
                    ┌─────────────────────────────┐
                    │          UI Pages          │
                    │  (login_page, register,...)  │
                    └─────────────┬───────────────┘
                                  │ BlocConsumer listens
                                  ↓
                    ┌─────────────────────────────┐
                    │          AuthCubit          │
                    │  (State management, JWT)   │
                    └─────────────┬───────────────┘
                                  │ Calls methods
                                  ↓
                    ┌─────────────────────────────┐
                    │      AuthRepository        │
                    │  (Abstract contract)       │
                    └─────────────┬───────────────┘
                                  │ Implements
                                  ↓
                    ┌─────────────────────────────┐
                    │    AuthRepositoryImpl      │
                    │  (Catches exceptions)      │
                    └─────────────┬───────────────┘
                                  │ Delegates to
                                  ↓
                    ┌─────────────────────────────┐
                    │   AuthRemoteDatasource    │
                    │  (Dio HTTP calls)         │
                    └─────────────────────────────┘
```

---

## 6. Request Models

| Model | Fields |
|-------|--------|
| `LoginRequestModel` | `usernameOrEmail`, `password` |
| `RegisterRequestModel` | `username`, `email`, `phoneNumber`, `password` |
| `GoogleLoginRequestModel` | `idToken` |
| `VerifyEmailRequestModel` | `token` (OTP) |
| `ChangePasswordRequestModel` | `currentPassword`, `newPassword` |
| `RequestPasswordResetRequestModel` | `email` |
| `ResetPasswordRequestModel` | `otpCode` (as 'token'), `newPassword` |
| `AuthTokensModel` | `token`, `refreshToken` (response only) |

---

## 7. Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `dartz` | Functional error handling (`Either<Failure, T>`) |
| `equatable` | Value equality |
| `dio` | HTTP client |
| `flutter_secure_storage` | Encrypted token storage |
| `jwt_decoder` | Client-side JWT parsing |
| `google_sign_in` | OAuth 2.0 integration |

---

## 8. Key Technical Decisions

1. **Dartz `Either`** - Functional error handling without try-catch in presentation
2. **FlutterSecureStorage** - Encrypted token storage (not SharedPreferences)
3. **Role-based access control** - Mobile only allows `User`/`Player` roles
4. **Pending tokens pattern** - Enables auto-login after OTP without re-entering credentials
5. **Dedicated refresh Dio** - Prevents recursive interceptor calls

---

## 9. Quick Reference

| Task | File/Method |
|------|-------------|
| Add new auth endpoint | `api_endpoints.dart` + `auth_remote_datasource.dart` |
| Add new state | `auth_state.dart` |
| Add new request model | `data/models/` + `auth_repository.dart` |
| Change token flow | `auth_interceptor.dart` (core) |
