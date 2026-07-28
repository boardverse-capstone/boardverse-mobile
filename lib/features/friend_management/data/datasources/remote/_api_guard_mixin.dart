import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/error/failures.dart';

/// Abstract class cung cấp helper để giảm lặp code trong các RemoteDatasource:
///
/// - [guardApiCall]: bọc một lời gọi Dio, bắt [DioException] + exception chung
///   và trả về [Either] chuẩn. Tránh lặp try/catch ở mỗi method.
/// - [unwrapEnvelope]: unwrap response body (backend wrap trong
///   `{ statusCode, message, data }`).
/// - [parseListEnvelope]: parse list endpoint, lấy `data[]` rồi map qua model.
///
/// Datasource cụ thể `extends ApiGuardMixin` rồi `with` các mixin theo
/// concern (friends, notes, privacy, ...). Subclass phải implement [dio]
/// getter — đây là dependency injection cho Dio client.
///
/// File này là internal helper trong feature. Có thể promote thành core helper
/// (`lib/core/network/`) khi cần share giữa các feature.
abstract class ApiGuardMixin {
  /// Trả về Dio instance. Subclass phải implement.
  Dio get dio;

  /// Chạy [call] và convert mọi exception thành [Failure]. Trả về
  /// `Right(value)` khi thành công, `Left(failure)` khi lỗi.
  Future<Either<Failure, T>> guardApiCall<T>(
    Future<T> Function() call,
  ) async {
    try {
      final result = await call();
      return Right<Failure, T>(result);
    } on DioException catch (e) {
      return Left<Failure, T>(mapDioError(e));
    } catch (e) {
      return Left<Failure, T>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  /// Unwrap response body — backend trả envelope
  /// `{ statusCode, message, data, ... }`; với single-object endpoint,
  /// parser.fromJson nhận thẳng body đã unwrap.
  Map<String, dynamic> unwrapEnvelope(Map<String, dynamic>? data) =>
      data ?? {};

  /// Parse list endpoint: lấy `data[]` rồi map qua model. Model có method
  /// `toEntity()` trả về entity. Kết quả là `List<Entity>`.
  ///
  /// Parser trả về `dynamic` vì Dart không cho phép ép kiểu giữa
  /// `FriendModel Function(...)` và `FriendEntity Function(...)` mặc dù
  /// FriendModel có method `toEntity()` trả FriendEntity.
  Future<List<T>> parseListEnvelope<T>(
    Map<String, dynamic>? response,
    dynamic Function(Map<String, dynamic>) parser,
  ) async {
    final data = response?['data'] as List<dynamic>? ?? [];
    final result = <T>[];
    for (final json in data) {
      final parsed = parser(json as Map<String, dynamic>);
      final entity = (parsed as dynamic).toEntity();
      result.add(entity as T);
    }
    return result;
  }

  Failure mapDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      switch (response.statusCode) {
        case 400:
          return BadRequestFailure(
            message: response.data?['message']?.toString() ??
                'Yêu cầu không hợp lệ',
          );
        case 401:
          return UnauthorizedFailure(message: 'Vui lòng đăng nhập lại');
        case 403:
          return ForbiddenFailure(
            message: response.data?['message']?.toString() ??
                'Bạn không có quyền thực hiện',
          );
        case 404:
          return NotFoundFailure(message: 'Không tìm thấy');
        case 409:
          return ConflictFailure(
            message: response.data?['message']?.toString() ??
                'Xung đột dữ liệu',
          );
        case 429:
          return RateLimitFailure(
            message: 'Quá nhiều yêu cầu, vui lòng thử lại sau',
          );
        default:
          return ServerFailure(
            message: response.data?['message']?.toString() ?? 'Lỗi server',
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
