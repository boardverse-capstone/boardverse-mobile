import 'package:equatable/equatable.dart';

import '../network/api_response.dart';

/// Base failure class for the domain layer.
///
/// All failures carry a human-readable [message] that originates from
/// the backend response envelope and can be displayed directly to the user.
sealed class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Failure caused by the server returning a non-success status code.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Failure caused by network connectivity issues (no internet, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
  });
}

/// Failure caused by local cache/storage errors.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Lỗi lưu trữ cục bộ.',
  });
}

/// Failure caused by invalid request (400).
class BadRequestFailure extends Failure {
  const BadRequestFailure({required super.message});
}

/// Failure caused by unauthorized access (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message});
}

/// Failure caused by forbidden access (403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required super.message});
}

/// Failure caused by resource not found (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

/// Failure caused by data conflict (409).
class ConflictFailure extends Failure {
  const ConflictFailure({required super.message});
}

/// Failure caused by rate limiting (429).
class RateLimitFailure extends Failure {
  const RateLimitFailure({required super.message});
}

/// Helper factory — map từ `ApiResponse` (envelope backend) sang `Failure`.
///
/// Phân loại qua `statusCode`:
/// - 200..299 → gần như không reach Failure path (caller đã check `isSuccess`).
/// - 400 → [BadRequestFailure]
/// - 401 → [UnauthorizedFailure]
/// - 403 → [ForbiddenFailure]
/// - 404 → [NotFoundFailure]
/// - 409 → [ConflictFailure]
/// - 429 → [RateLimitFailure]
/// - 5xx → [ServerFailure]
/// - other → [ServerFailure]
extension FailureFromApiResponseX on Failure {
  /// Translation từ `ApiResponse` đã parse.
  /// Nếu [response] success (isSuccess), giữ default — nên caller check
  /// `isSuccess` trước khi gọi.
  static Failure fromApiResponse(
    ApiResponse<dynamic> response, {
    String? fallbackMessage,
    int? codeOverride,
  }) {
    final code = codeOverride ?? response.statusCode;
    final message = response.message.isNotEmpty
        ? response.message
        : (fallbackMessage ?? _defaultMessageForCode(code));

    switch (code) {
      case 400:
        return BadRequestFailure(message: message);
      case 401:
        return UnauthorizedFailure(message: message);
      case 403:
        return ForbiddenFailure(message: message);
      case 404:
        return NotFoundFailure(message: message);
      case 409:
        return ConflictFailure(message: message);
      case 429:
        return RateLimitFailure(message: message);
      default:
        return ServerFailure(message: message, statusCode: code);
    }
  }

  static String _defaultMessageForCode(int code) {
    if (code >= 500) return 'Lỗi server ($code). Vui lòng thử lại sau.';
    if (code == 0) return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
    return 'Yêu cầu thất bại ($code).';
  }
}
