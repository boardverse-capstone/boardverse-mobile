import 'package:equatable/equatable.dart';

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
