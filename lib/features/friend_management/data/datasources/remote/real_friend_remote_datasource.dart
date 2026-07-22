import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/constants/api_endpoints.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/data/models/friend_model.dart';
import 'package:boardverse_mobile/features/friend_management/data/datasources/base/friend_remote_datasource.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';

class RealFriendRemoteDatasource implements FriendRemoteDatasource {
  RealFriendRemoteDatasource({required this._dio});

  final Dio _dio;

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriends() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.friends);
      final models = (res.data ?? [])
          .map((json) => FriendModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getFriendsWithActivity() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.friendsActivity);
      final models = (res.data ?? [])
          .map((json) => FriendModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedRequests() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.friendRequestsReceived);
      final models = (res.data ?? [])
          .map((json) => FriendRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendRequestEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendRequestEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendRequestEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentRequests() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.friendRequestsSent);
      final models = (res.data ?? [])
          .map((json) => FriendRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendRequestEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendRequestEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendRequestEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    try {
      final body = <String, dynamic>{'addresseeId': addresseeId};
      if (message != null && message.isNotEmpty) {
        body['message'] = message;
      }
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.friendRequests,
        data: body,
      );
      final model = FriendRequestModel.fromJson(_unwrap(res.data));
      return Right<Failure, FriendRequestEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, FriendRequestEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, FriendRequestEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> acceptFriendRequest(String requestId) async {
    try {
      final path = ApiEndpoints.friendRequestAccept(requestId);
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = FriendRequestModel.fromJson(_unwrap(res.data));
      return Right<Failure, FriendRequestEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, FriendRequestEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, FriendRequestEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, FriendRequestEntity>> declineFriendRequest(String requestId) async {
    try {
      final path = ApiEndpoints.friendRequestDecline(requestId);
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = FriendRequestModel.fromJson(_unwrap(res.data));
      return Right<Failure, FriendRequestEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, FriendRequestEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, FriendRequestEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markRequestAsRead(String requestId) async {
    try {
      final path = ApiEndpoints.friendRequestRead(requestId);
      await _dio.post(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> unfriend(String friendId) async {
    try {
      final path = ApiEndpoints.friendUnfriend(friendId);
      await _dio.delete(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    try {
      final path = ApiEndpoints.friendBlock(userId);
      await _dio.post(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    try {
      final path = ApiEndpoints.friendUnblock(userId);
      await _dio.delete(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<UserSearchEntity>>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.friendSearch,
        queryParameters: {'q': query, 'limit': limit},
      );
      final models = (res.data ?? [])
          .map((json) => UserSearchModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<UserSearchEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<UserSearchEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<UserSearchEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendSuggestionEntity>>> getSuggestions({
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.friendSuggestions,
        queryParameters: {'limit': limit},
      );
      final models = (res.data ?? [])
          .map((json) => FriendSuggestionModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendSuggestionEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendSuggestionEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendSuggestionEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getMutualFriends(String otherUserId) async {
    try {
      final path = ApiEndpoints.friendMutual(otherUserId);
      final res = await _dio.get<List<dynamic>>(path);
      final models = (res.data ?? [])
          .map((json) => FriendModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<FriendEntity>>(
        models.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? data) {
    return data ?? {};
  }

  Failure _mapDioError(DioException e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case 400:
          return BadRequestFailure(
            message: e.response!.data?['message']?.toString() ?? 'Yêu cầu không hợp lệ',
          );
        case 401:
          return UnauthorizedFailure(message: 'Vui lòng đăng nhập lại');
        case 403:
          return ForbiddenFailure(
            message: e.response!.data?['message']?.toString() ?? 'Bạn không có quyền thực hiện',
          );
        case 404:
          return NotFoundFailure(message: 'Không tìm thấy');
        case 409:
          return ConflictFailure(
            message: e.response!.data?['message']?.toString() ?? 'Xung đột dữ liệu',
          );
        case 429:
          return RateLimitFailure(message: 'Quá nhiều yêu cầu, vui lòng thử lại sau');
        default:
          return ServerFailure(
            message: e.response!.data?['message']?.toString() ?? 'Lỗi server',
          );
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message: 'Kết nối quá lâu, vui lòng thử lại');
    }
    return NetworkFailure(message: 'Không có kết nối mạng');
  }
}
