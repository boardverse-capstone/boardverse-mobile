# API Integration Guidelines

> Hướng dẫn tích hợp API endpoints cho BoardVerse Mobile Flutter app.
> File này là **nguồn tri thức chính** (source of truth) cho việc implement và maintain API integration.

---

## Table of Contents

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Cấu trúc thư mục](#2-cấu-trúc-thư-mục)
3. [Quy tắc đặt tên](#3-quy-tắc-đặt-tên)
4. [Luồng dữ liệu (Data Flow)](#4-luồng-dữ-liệu-data-flow)
5. [Cách implement feature mới](#5-cách-implement-feature-mới)
6. [API Response Structure](#6-api-response-structure)
7. [Error Handling](#7-error-handling)
8. [Dependency Injection](#8-dependency-injection)
9. [OpenAPI Codegen (Tương lai)](#9-openapi-codegen-tương-lai)
10. [Checklist trước khi commit](#10-checklist-trước-khi-commit)

---

## 1. Tổng quan kiến trúc

### Clean Architecture (3 Layers)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │    Cubit    │  │   Widget    │  │    Page     │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
│         ↓               ↑                                        │
│         ↓               │ State Management (Cubit)              │
│         ↓               │                                        │
├─────────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                               │
│  ┌─────────────────────────────────────────────┐               │
│  │           Repository (Abstract)             │               │
│  │   - Định nghĩa contract interface           │               │
│  │   - KHÔNG có logic xử lý                    │               │
│  │   - KHÔNG gọi API trực tiếp                 │               │
│  └─────────────────────────────────────────────┘               │
│         ↓               ↑                                        │
│         ↓               │                                       │
├─────────────────────────────────────────────────────────────────┤
│                       DATA LAYER                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │  Datasource │  │ Repository  │  │   Models    │           │
│  │  (Remote)   │  │   (Impl)    │  │             │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
│         ↓               ↑                                        │
│         ↓               │ Implement Repository, call API       │
│         ↓               │ Map Exception → Failure               │
└─────────────────────────────────────────────────────────────────┘
```

### Nguyên tắc cốt lõi

| Nguyên tắc | Giải thích |
|------------|------------|
| **Dependency Inversion** | Presentation → Domain → Data (ngược chiều) |
| **Single Responsibility** | Mỗi layer/class chỉ làm 1 việc |
| **Data Flow một chiều** | Cubit → Repository → Datasource → API |
| **Error Mapping** | Exception (Data) → Failure (Domain) |

---

## 2. Cấu trúc thư mục

```
lib/
├── core/                           # Shared infrastructure
│   ├── constants/
│   │   └── api_endpoints.dart      # ⭐ SINGLE SOURCE OF TRUTH
│   │                                # cho tất cả API paths
│   ├── network/
│   │   ├── dio_client.dart         # Dio singleton
│   │   ├── api_response.dart        # API response envelope
│   │   └── auth_interceptor.dart   # JWT token handling
│   ├── error/
│   │   ├── exceptions.dart         # Data layer exceptions
│   │   └── failures.dart           # Domain layer failures
│   └── di/
│       └── injection.dart          # GetIt dependency injection
│
├── features/                       # Feature modules
│   └── [feature_name]/
│       ├── domain/                 # Business logic (pure Dart)
│       │   ├── entities/           # Business objects
│       │   └── repositories/       # Abstract interfaces
│       │       └── [feature]_repository.dart
│       │
│       ├── data/                   # Data access
│       │   ├── models/             # DTOs, JSON serialization
│       │   │   ├── [model].dart
│       │   │   ├── [model].freezed.dart
│       │   │   └── [model].g.dart
│       │   ├── datasources/
│       │   │   ├── base/           # Abstract datasource
│       │   │   │   └── [feature]_datasource.dart
│       │   │   └── remote/        # Concrete Dio implementation
│       │   │       └── real_[feature]_datasource.dart
│       │   ├── repositories/      # Repository implementation
│       │   │   └── [feature]_repository_impl.dart
│       │   └── realtime/           # SignalR realtime (nếu có)
│       │       └── [feature]_realtime_service.dart
│       │
│       └── presentation/           # UI layer
│           ├── cubit/              # State management
│           │   ├── [feature]_cubit.dart
│           │   └── [feature]_state.dart
│           ├── pages/              # Full screens
│           └── widgets/            # Reusable UI components
│
└── main.dart
```

### Quy tắc đặt tên feature

| Feature | Thư mục | Ví dụ |
|---------|---------|-------|
| Auth | `features/auth/` | Login, Register, Password reset |
| Profile | `features/profile/` | User profile, Avatar, Location |
| Lobby | `features/lobby_management/` | Lobby CRUD, Join/Leave |
| Tournament | `features/tournament/` | Tournament list, Registration |
| Friends | `features/friend_management/` | Friend list, Requests |

---

## 3. Quy tắc đặt tên

### 3.1 Model Classes

```dart
// Request models: [Feature][Action]RequestModel
LoginRequestModel
RegisterRequestModel
CreateLobbyRequestModel
JoinLobbyRequestModel

// Response models: [Feature][Entity]Model
AuthTokensModel
LobbyModel
UserProfileModel

// Use Freezed cho immutable models
@freezed
abstract class LoginRequestModel with _$LoginRequestModel {
  const factory LoginRequestModel({
    required String usernameOrEmail,
    required String password,
  }) = _LoginRequestModel;

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);
}
```

### 3.2 Repository Interface

```dart
// File: domain/repositories/[feature]_repository.dart
abstract class [Feature]Repository {
  // CRUD operations
  Future<Either<Failure, ReturnType>> actionName(RequestModel request);

  // Queries
  Future<Either<Failure, Entity>> getEntity(String id);

  // Streams (cho realtime)
  Stream<Entity> watchEntity(String id);
}
```

### 3.3 Datasource Interface

```dart
// File: data/datasources/base/[feature]_datasource.dart
abstract class [Feature]Datasource {
  Future<ApiResponse<Model>> actionName(RequestModel request);
}
```

### 3.4 Biến và hàm

```dart
// endpoints - static const
static const String login = '/api/Auth/login';

// functions - camelCase, mô tả rõ action
static String lobbyDetail(String id) => '/api/v1/lobbies/$id';

// Cubit state - dùng prefix theo action
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState {}
```

---

## 4. Luồng dữ liệu (Data Flow)

### 4.1 Gọi API thành công

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. Cubit gọi Repository method                                   │
│    cubit.login(request)                                           │
│                         ↓                                        │
│ 2. Repository (Impl) gọi Datasource                              │
│    _remote.login(request)                                        │
│                         ↓                                        │
│ 3. Datasource gọi Dio với endpoint + data                        │
│    _dio.post(ApiEndpoints.login, data: request.toJson())         │
│                         ↓                                        │
│ 4. API trả về JSON → ApiResponse.fromJson()                      │
│                         ↓                                        │
│ 5. Datasource parse data → Model                                 │
│                         ↓                                        │
│ 6. Repository trả Either<Failure, Model>                        │
│                         ↓                                        │
│ 7. Cubit nhận result → emit new state                            │
│                                                                  │
│ State flow: AuthInitial → AuthLoading → AuthSuccess              │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Xử lý lỗi

```
┌──────────────────────────────────────────────────────────────────┐
│ API trả về lỗi                                                   │
│                         ↓                                        │
│ DioException thrown                                                │
│                         ↓                                        │
│ Datasource catch → ServerException(message, statusCode)         │
│                         ↓                                        │
│ Repository catch(ServerException) → Left(ServerFailure(...))     │
│                         ↓                                        │
│ Repository catch(DioException) → Left(NetworkFailure/...)       │
│                         ↓                                        │
│ Cubit nhận Left → emit AuthFailure(state)                       │
│                                                                  │
│ State flow: AuthInitial → AuthLoading → AuthFailure              │
└──────────────────────────────────────────────────────────────────┘
```

### 4.3 Ví dụ code flow

```dart
// ============================================================
// STEP 1: Model (data/models/login_request_model.dart)
// ============================================================
import 'package:freezed_annotation/freezed_annotation.dart';
part 'login_request_model.freezed.dart';
part 'login_request_model.g.dart';

@freezed
abstract class LoginRequestModel with _$LoginRequestModel {
  const factory LoginRequestModel({
    required String usernameOrEmail,
    required String password,
  }) = _LoginRequestModel;

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);
}

// ============================================================
// STEP 2: Repository Interface (domain/repositories/xxx_repository.dart)
// ============================================================
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/login_request_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthTokensModel>> login(LoginRequestModel request);
}

// ============================================================
// STEP 3: Datasource Interface (data/datasources/base/xxx_datasource.dart)
// ============================================================
import '../../../../core/network/api_response.dart';
abstract class AuthRemoteDatasource {
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestModel request);
}

// ============================================================
// STEP 4: Datasource Implementation (data/datasources/remote/real_xxx_datasource.dart)
// ============================================================
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_response.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final Dio _dio;

  @override
  Future<ApiResponse<AuthTokensModel>> login(LoginRequestModel request) async {
    final response = await _dio.post(
      ApiEndpoints.login,  // ⭐ Dùng centralized endpoints
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<AuthTokensModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (json) => AuthTokensModel.fromJson(json),
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

// ============================================================
// STEP 5: Repository Implementation (data/xxx_repository_impl.dart)
// ============================================================
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;

  @override
  Future<Either<Failure, AuthTokensModel>> login(LoginRequestModel request) async {
    try {
      final response = await _remote.login(request);
      return Right(response.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));  // Helper method
    }
  }

  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        // Parse backend error message
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return ServerFailure(
            message: data['message'] as String,
            statusCode: e.response?.statusCode,
          );
        }
        return ServerFailure(
          message: e.message ?? 'Unknown error',
          statusCode: e.response?.statusCode,
        );
      default:
        return ServerFailure(message: e.message ?? 'Unknown error');
    }
  }
}

// ============================================================
// STEP 6: Cubit (presentation/cubit/xxx_cubit.dart)
// ============================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/login_request_model.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final request = LoginRequestModel(
      usernameOrEmail: email,
      password: password,
    );

    final result = await repository.login(request);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (tokens) => emit(AuthSuccess(tokens: tokens)),
    );
  }
}
```

---

## 5. Cách implement feature mới

### 5.1 Workflow từng bước

```
┌─────────────────────────────────────────────────────────────────┐
│ BƯỚC 1: Đọc swagger.json                                        │
│ ├── Tìm endpoint cần implement                                   │
│ ├── Xác định request/response schema                            │
│ └── Note: path params, query params, headers                     │
│                              ↓                                   │
│ BƯỚC 2: Thêm endpoint vào api_endpoints.dart                    │
│ ├── Static const cho fixed endpoints                            │
│ └── Static function cho dynamic endpoints (path params)          │
│                              ↓                                   │
│ BƯỚC 3: Tạo Model classes                                       │
│ ├── Request model với freezed_annotation                        │
│ ├── Response model với freezed_annotation                       │
│ └── Chạy: flutter pub run build_runner build                    │
│                              ↓                                   │
│ BƯỚC 4: Tạo Domain Layer                                        │
│ ├── Entity (nếu cần business logic khác response)               │
│ └── Repository interface                                         │
│                              ↓                                   │
│ BƯỚC 5: Tạo Data Layer                                          │
│ ├── Datasource interface (base/)                               │
│ ├── Datasource implementation (remote/)                         │
│ └── Repository implementation                                    │
│                              ↓                                   │
│ BƯỚC 6: Đăng ký DI trong injection.dart                         │
│                              ↓                                   │
│ BƯỚC 7: Tạo Cubit + State                                       │
│                              ↓                                   │
│ BƯỚC 8: Tạo UI (Pages + Widgets)                                │
│                              ↓                                   │
│ BƯỚC 9: Test + Verify                                           │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Ví dụ: Thêm API cho Friend feature

```dart
// ============================================================
// BƯỚC 1: Thêm vào api_endpoints.dart
// ============================================================
// File: lib/core/constants/api_endpoints.dart

// Static endpoint
static const String friends = '/api/v1/friends';

// Dynamic endpoint (cần parameter)
static String friendDetail(String id) => '/api/v1/friends/$id';
static String friendUnfriend(String id) => '/api/v1/friends/$id';

// ============================================================
// BƯỚC 2: Tạo Model
// ============================================================
// File: lib/features/friend_management/data/models/friend_model.dart

@freezed
abstract class FriendModel with _$FriendModel {
  const factory FriendModel({
    required String id,
    required String username,
    required String displayName,
    String? avatarUrl,
    @Default(false) bool isOnline,
  }) = _FriendModel;

  factory FriendModel.fromJson(Map<String, dynamic> json) =>
      _$FriendModelFromJson(json);
}

// ============================================================
// BƯỚC 3: Tạo Repository Interface
// ============================================================
// File: lib/features/friend_management/domain/repositories/friend_repository.dart

abstract class FriendRepository {
  Future<Either<Failure, List<FriendModel>>> getFriends();
  Future<Either<Failure, FriendModel>> getFriendById(String id);
  Future<Either<Failure, void>> unfriend(String friendId);
}

// ============================================================
// BƯỚC 4: Tạo Datasource Interface
// ============================================================
// File: lib/features/friend_management/data/datasources/base/friend_datasource.dart

abstract class FriendDatasource {
  Future<ApiResponse<List<FriendModel>>> getFriends();
  Future<ApiResponse<FriendModel>> getFriendById(String id);
  Future<ApiResponse<void>> unfriend(String friendId);
}

// ============================================================
// BƯỚC 5: Tạo Datasource Implementation
// ============================================================
// File: lib/features/friend_management/data/datasources/remote/real_friend_datasource.dart

class RealFriendDatasource implements FriendDatasource {
  final Dio _dio;

  @override
  Future<ApiResponse<List<FriendModel>>> getFriends() async {
    final response = await _dio.get(ApiEndpoints.friends);

    return ApiResponse<List<FriendModel>>.fromJson(
      response.data,
      fromJsonT: (json) => (json as List)
          .map((e) => FriendModel.fromJson(e))
          .toList(),
    );
  }

  @override
  Future<ApiResponse<FriendModel>> getFriendById(String id) async {
    final response = await _dio.get(ApiEndpoints.friendDetail(id));

    return ApiResponse<FriendModel>.fromJson(
      response.data,
      fromJsonT: FriendModel.fromJson,
    );
  }

  @override
  Future<ApiResponse<void>> unfriend(String friendId) async {
    final response = await _dio.delete(ApiEndpoints.friendUnfriend(friendId));

    return ApiResponse<void>.fromJson(response.data);
  }
}

// ============================================================
// BƯỚC 6: Tạo Repository Implementation
// ============================================================
// File: lib/features/friend_management/data/friend_repository_impl.dart

class FriendRepositoryImpl implements FriendRepository {
  final FriendDatasource _datasource;

  @override
  Future<Either<Failure, List<FriendModel>>> getFriends() async {
    try {
      final response = await _datasource.getFriends();
      return Right(response.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    }
  }

  // ... implement other methods
}

// ============================================================
// BƯỚC 7: Đăng ký DI
// ============================================================
// File: lib/core/di/injection.dart

sl.registerLazySingleton<FriendDatasource>(
  () => RealFriendDatasource(dio: sl<Dio>()),
);

sl.registerLazySingleton<FriendRepository>(
  () => FriendRepositoryImpl(datasource: sl<FriendDatasource>()),
);
```

---

## 6. API Response Structure

### 6.1 Backend Response Format

Tất cả API responses tuân theo format:

```json
{
  "statusCode": 200,
  "message": "OK",
  "data": {
    // Response data here
  },
  "timestamp": "2026-05-31T12:34:56Z",
  "path": "/api/Auth/login"
}
```

### 6.2 ApiResponse Class

```dart
// File: lib/core/network/api_response.dart

class ApiResponse<T> {
  final int statusCode;
  final String message;
  final T? data;
  final String? timestamp;
  final String? path;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return ApiResponse<T>(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      timestamp: json['timestamp'] as String?,
      path: json['path'] as String?,
    );
  }
}
```

### 6.3 Sử dụng ApiResponse

```dart
// Single object
final response = await _dio.get(ApiEndpoints.userProfile);
final apiResponse = ApiResponse<UserModel>.fromJson(
  response.data,
  fromJsonT: UserModel.fromJson,
);

// List
final response = await _dio.get(ApiEndpoints.friends);
final apiResponse = ApiResponse<List<FriendModel>>.fromJson(
  response.data,
  fromJsonT: (json) => (json as List)
      .map((e) => FriendModel.fromJson(e))
      .toList(),
);

// No data (void response)
final response = await _dio.post(ApiEndpoints.logout);
final apiResponse = ApiResponse<void>.fromJson(response.data);
```

---

## 7. Error Handling

### 7.1 Failure Types

```dart
// File: lib/core/error/failures.dart

sealed class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Không có kết nối mạng.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Lỗi lưu trữ cục bộ.'});
}

class BadRequestFailure extends Failure { ... }      // 400
class UnauthorizedFailure extends Failure { ... }    // 401
class ForbiddenFailure extends Failure { ... }       // 403
class NotFoundFailure extends Failure { ... }        // 404
class ConflictFailure extends Failure { ... }        // 409
class RateLimitFailure extends Failure { ... }       // 429
```

### 7.2 Exception Types

```dart
// File: lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Không có kết nối mạng.'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Lỗi lưu trữ cục bộ.'});
}
```

### 7.3 Error Mapping Pattern

```dart
// Luôn luôn map exceptions → failures trong Repository Implementation

Failure _mapDioException(DioException e) {
  switch (e.type) {
    // Network errors
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();

    // HTTP errors
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      // Parse backend error message
      String message = 'Đã xảy ra lỗi.';
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        message = data['message'] as String;
      }

      return switch (statusCode) {
        400 => BadRequestFailure(message: message),
        401 => UnauthorizedFailure(message: message),
        403 => ForbiddenFailure(message: message),
        404 => NotFoundFailure(message: message),
        409 => ConflictFailure(message: message),
        429 => RateLimitFailure(message: message),
        _ => ServerFailure(message: message, statusCode: statusCode),
      };

    // Other errors
    default:
      return ServerFailure(message: e.message ?? 'Unknown error');
  }
}
```

### 7.4 Handling in Cubit

```dart
// Presentation layer KHÔNG BAO GIỜ catch exceptions
// Chỉ nhận và xử lý Failure

class AuthCubit extends Cubit<AuthState> {
  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final request = LoginRequestModel(
      usernameOrEmail: email,
      password: password,
    );

    final result = await repository.login(request);

    result.fold(
      (failure) => emit(AuthFailure(
        message: failure.message,
        // Có thể thêm logic xử lý theo failure type
        isNetworkError: failure is NetworkFailure,
      )),
      (tokens) => emit(AuthSuccess(tokens: tokens)),
    );
  }
}
```

---

## 8. Dependency Injection

### 8.1 Setup với GetIt

```dart
// File: lib/core/di/injection.dart

final sl = GetIt.instance;

// External dependencies
sl.registerLazySingleton<FlutterSecureStorage>(
  () => const FlutterSecureStorage(),
);

// Network
sl.registerLazySingleton<DioClient>(
  () => DioClient(authInterceptor: sl<AuthInterceptor>()),
);
sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

// Feature: Auth
sl.registerLazySingleton<AuthRemoteDatasource>(
  () => AuthRemoteDatasourceImpl(dio: sl<Dio>()),
);
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(remoteDatasource: sl<AuthRemoteDatasource>()),
);
sl.registerFactory<AuthCubit>(
  () => AuthCubit(
    repository: sl<AuthRepository>(),
    storage: sl<FlutterSecureStorage>(),
  ),
);
```

### 8.2 Singleton vs Factory

| Loại | Use case | Ví dụ |
|------|----------|-------|
| `registerLazySingleton` | Repository, Service (shared state) | AuthRepository, DioClient |
| `registerFactory` | Cubit, Page instances (new each time) | AuthCubit, ProfileCubit |

### 8.3 Sử dụng trong Widget

```dart
// Lấy instance từ GetIt
final cubit = sl<AuthCubit>();

// Hoặc dùng BlocProvider trong widget tree
BlocProvider(
  create: (_) => sl<AuthCubit>(),
  child: LoginPage(),
)
```

---

## 9. OpenAPI Codegen (Tương lai)

### 9.1 Khi nào nên dùng

| Nên dùng | Không nên dùng |
|----------|----------------|
| Module mới (Tournament, Chat, ...) | Auth, Profile (đã ổn định) |
| Backend API phức tạp, nhiều endpoints | API đơn giản, ít endpoints |
| Team lớn, cần consistency | Prototype, POC |

### 9.2 Setup OpenAPI Generator

```bash
# 1. Cài đặt Node.js (required)
# 2. Cài openapi-generator
npm install @openapitools/openapi-generator-cli -g

# Hoặc dùng Docker
docker pull openapitools/openapi-generator-cli
```

### 9.3 Cấu hình

```yaml
# openapi-config.yaml
input: .agents/docs/swagger.json
output: lib/api/generated
generator: dart-dio
additionalProperties:
  pubName: boardverse_api
  pubVersion: 1.0.0
  nullSafety: true
```

### 9.4 Generated output structure

```
lib/api/generated/
├── api.dart                    # Main API entry
├── api/
│   ├── lobby_api.dart         # Lobby endpoints (26 endpoints)
│   ├── auth_api.dart          # Auth endpoints
│   └── ...
├── model/
│   ├── create_lobby_request.dart
│   ├── lobby_detail_response.dart
│   └── ...
└── entity/
    └── ...
```

### 9.5 Integration với kiến trúc hiện tại

```dart
// Generated API thay thế DataSource
// Nhưng Repository interface vẫn giữ nguyên

// Generated code
import 'package:boardverse_api/api.dart';

// Repository implementation
class LobbyRepositoryImpl implements LobbyRepository {
  final LobbyApi _api;

  @override
  Future<Either<Failure, LobbyEntity>> getLobbyById(String lobbyId) async {
    try {
      final response = await _api.getLobbyDetail(lobbyId);
      return Right(LobbyEntity.fromModel(response.data));
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

### 9.6 Khi backend update swagger

```bash
# 1. Pull swagger mới
git pull origin main

# 2. Regenerate code
openapi-generator-cli generate

# 3. Review changes
git diff lib/api/generated/

# 4. Commit nếu OK
git add lib/api/generated/
git commit -m "chore: regenerate API from updated swagger"
```

---

## 10. Checklist trước khi commit

### 10.1 Code quality

- [ ] Model có `fromJson` và `toJson` (dùng freezed)
- [ ] Repository interface có đầy đủ methods
- [ ] Datasource implementation parse đúng ApiResponse envelope
- [ ] Error mapping đầy đủ (ServerException, DioException)
- [ ] Endpoint paths dùng centralized `ApiEndpoints`

### 10.2 Architecture

- [ ] Không gọi Dio trực tiếp từ Cubit/UI
- [ ] KHÔNG có business logic trong Data layer
- [ ] KHÔNG có API calls trong Domain layer
- [ ] State management dùng Cubit pattern

### 10.3 Testing

- [ ] Model serialization test
- [ ] Repository method test (mock datasource)
- [ ] Datasource method test (mock Dio)

### 10.4 Documentation

- [ ] Doc comments cho public methods
- [ ] Endpoint comment reference swagger
- [ ] README.md cho feature mới

---

## Quick Reference

### Common patterns

```dart
// Lấy endpoint với path param
ApiEndpoints.lobbyDetail(lobbyId)  // "/api/v1/lobbies/{lobbyId}"
ApiEndpoints.tournamentDetail(id)  // "/api/v1/tournaments/{id}"

// Parse list response
ApiResponse<List<Model>>.fromJson(
  response.data,
  fromJsonT: (json) => (json as List)
      .map((e) => Model.fromJson(e))
      .toList(),
)

// Handle optional data
ApiResponse<Model?>.fromJson(
  response.data,
  fromJsonT: (json) => json != null ? Model.fromJson(json) : null,
)

// Error handling
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (data) => emit(LoadedState(data)),
)
```

### File paths thường dùng

| File | Path |
|------|------|
| API Endpoints | `lib/core/constants/api_endpoints.dart` |
| Dio Client | `lib/core/network/dio_client.dart` |
| Failures | `lib/core/error/failures.dart` |
| Exceptions | `lib/core/error/exceptions.dart` |
| DI Setup | `lib/core/di/injection.dart` |
| Swagger | `.agents/docs/swagger.json` |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-23 | AI Agent | Initial document |

---

*Document generated for BoardVerse Mobile Flutter project*
*Last updated: 2026-07-23*
