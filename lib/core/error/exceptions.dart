/// Custom exceptions for the application.
///
/// These are thrown in the data layer and caught in the repository
/// implementation to be converted into [Failure] objects.
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException(message: $message, statusCode: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
  });

  @override
  String toString() => 'NetworkException(message: $message)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Lỗi lưu trữ cục bộ.',
  });

  @override
  String toString() => 'CacheException(message: $message)';
}
