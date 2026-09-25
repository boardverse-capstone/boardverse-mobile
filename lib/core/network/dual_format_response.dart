import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Helper parse response từ backend, hỗ trợ 2 format khác nhau:
///
/// Format 1 — Discovery Survey / Group (dùng trong BE cũ):
/// ```json
/// { "success": true, "data": { ... }, "error": null }
/// { "success": false, "data": null, "error": { "code": "...", "message": "..." } }
/// ```
///
/// Format 2 — Solo-Personalized / Saved Games (dùng trong BE mới):
/// ```json
/// { "statusCode": 200, "message": "...", "data": { ... } }
/// { "statusCode": 400, "message": "...", "data": null }
/// ```
///
/// **Dùng cho tầng Data (Repository Impl):**
/// Repository gọi `DualFormatResponse.parse(response)` trước khi map sang entity.
/// Nếu parse thất bại → trả về `Left(Failure)`.
/// Nếu thành công → trả về `Right(data)` (dynamic) — caller tự cast.
///
/// Ví dụ usage trong DiscoveryRepositoryImpl:
/// ```dart
/// final response = await datasource.runSurvey(request);
/// return DualFormatResponse.parse(response).fold(
///   (failure) => Left(failure),
///   (data) => Right(_mapToSurveyResponse(data)),
/// );
/// ```
class DualFormatResponse {
  DualFormatResponse._();

  /// Parse raw [Response] từ Dio.
  ///
  /// Trả về:
  /// - `Right(data)` — response thành công, data là dynamic (caller cast).
  /// - `Left(Failure)` — parse thất bại (format lạ, network error, server error).
  static Either<Failure, dynamic> parse(Response response) {
    // 2xx → lấy data (format nào cũng được)
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return _extractDataOnSuccess(response.data);
    }

    // 4xx/5xx → tạo Failure phù hợp
    return _mapToFailure(response.statusCode, response.data);
  }

  /// Parse response trong trường hợp gọi request mà không cần body
  /// (ví dụ DELETE /saved/{id}, GET /saved).
  static Either<Failure, bool> parseNoContent(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return const Right<Failure, bool>(true);
    }
    // Trường hợp lỗi — wrap failure thành Either<Failure, bool> với false.
    final dynamic result = _mapToFailure(response.statusCode, response.data);
    return Left<Failure, bool>(
      result.fold((Failure f) => f, (_) => ServerFailure(message: 'Unknown')),
    );
  }

  static Either<Failure, dynamic> _extractDataOnSuccess(dynamic body) {
    if (body == null) return const Right(null);

    // Response có thể là Map hoặc List
    if (body is! Map) return Right(body);

    // Format 1: { success, data, error }
    if (body.containsKey('success')) {
      final success = body['success'];
      if (success == true) {
        // Co hoac khong co data field
        if (body.containsKey('data')) {
          return Right(body['data']);
        }
        return const Right(null);
      }
      // success == false
      return _mapFormat1Error(body['error'], null);
    }

    // Format 2: { statusCode, message, data }
    if (body.containsKey('statusCode')) {
      final code = body['statusCode'] as int;
      if (code >= 200 && code < 300) {
        return Right(body['data']);
      }
      // Non-2xx statusCode trong format 2
      return _mapFormat2Error(body['message'], code);
    }

    // Không nhận diện được format — coi như data thành công
    return Right(body);
  }

  static Either<Failure, dynamic> _mapFormat1Error(dynamic error, int? statusCode) {
    if (error == null) {
      return Left(ServerFailure(message: 'Yêu cầu thất bại.', statusCode: statusCode));
    }
    if (error is Map) {
      final errorCode = error['code'] as String?;
      final message = error['message'] as String? ?? 'Yêu cầu thất bại.';
      return Left(_failureFromCode(errorCode, message, statusCode: statusCode));
    }
    return Left(ServerFailure(message: 'Yêu cầu thất bại.', statusCode: statusCode));
  }

  static Either<Failure, dynamic> _mapFormat2Error(dynamic message, int code) {
    final msg = (message is String && message.isNotEmpty)
        ? message
        : _defaultMessageForCode(code);
    return Left(_failureFromCode(null, msg, statusCode: code));
  }

  static Either<Failure, dynamic> _mapToFailure(int? statusCode, dynamic body) {
    final code = statusCode ?? 0;
    String? msg;

    if (body is Map) {
      // Thử format 1 error
      if (body.containsKey('error') && body['error'] is Map) {
        final error = body['error'] as Map;
        msg = error['message'] as String?;
      }
      // Thử format 2
      if (body.containsKey('message') && msg == null) {
        msg = body['message'] as String?;
      }
    }

    msg ??= _defaultMessageForCode(code);

    if (code == 400) return Left(BadRequestFailure(message: msg));
    if (code == 401) return Left(const UnauthorizedFailure(message: 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'));
    if (code == 403) return Left(ForbiddenFailure(message: msg));
    if (code == 404) return Left(NotFoundFailure(message: msg));
    if (code == 409) return Left(ConflictFailure(message: msg));
    if (code == 429) return Left(RateLimitFailure(message: msg));
    return Left(ServerFailure(message: msg, statusCode: code));
  }

  static String _defaultMessageForCode(int code) {
    if (code >= 500) return 'Lỗi server ($code). Vui lòng thử lại sau.';
    if (code == 0) return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
    return 'Yêu cầu thất bại ($code).';
  }

  static Failure _failureFromCode(String? errorCode, String message, {int? statusCode}) {
    // Một số mã lỗi thường gặp
    switch (errorCode) {
      case 'VALIDATION_ERROR':
        return BadRequestFailure(message: message);
      case 'UNAUTHORIZED':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_INVALID':
        return const UnauthorizedFailure(
            message: 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      case 'FORBIDDEN':
        return ForbiddenFailure(message: message);
      case 'NOT_FOUND':
      case 'RESOURCE_NOT_FOUND':
        return NotFoundFailure(message: message);
      case 'CONFLICT':
        return ConflictFailure(message: message);
      case 'RATE_LIMITED':
        return RateLimitFailure(message: message);
      default:
        return ServerFailure(
            message: message, statusCode: statusCode);
    }
  }

  /// Convert [DioException] sang [Failure] — dùng để giữ lại message gốc
  /// từ backend envelope khi Dio throw exception (4xx/5xx).
  ///
  /// Dio mặc định throw `DioException` cho non-2xx response, nên
  /// `DualFormatResponse.parse(response)` không bao giờ được gọi.
  /// Repository / caller cần gọi hàm này trong `catch (DioException)` để
  /// bảo toàn message từ BE cho UI.
  ///
  /// Áp dụng cùng logic với [_mapToFailure]:
  /// - Format 1: `{error: {message: "..."}}`
  /// - Format 2: `{message: "..."}`
  /// - Network errors (no response): trả NetworkFailure
  static Failure fromDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      // Không có response → network/timeout/cancel/etc.
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkFailure(
              message:
                  'Kết nối quá thời gian. Vui lòng kiểm tra mạng và thử lại.');
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        case DioExceptionType.cancel:
          return const NetworkFailure(message: 'Yêu cầu đã bị huỷ.');
        default:
          return const NetworkFailure();
      }
    }

    return _mapToFailure(response.statusCode, response.data)
        .fold((Failure f) => f, (_) => ServerFailure(message: 'Yêu cầu thất bại.'));
  }
}
