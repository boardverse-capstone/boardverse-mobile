/// Generic API response envelope matching the backend contract.
///
/// Every response from the BoardVerse API follows this structure:
/// ```json
/// {
///   "statusCode": 200,
///   "message": "OK",
///   "data": { ... },
///   "timestamp": "2026-05-31T12:34:56Z",
///   "path": "/api/auth/login"
/// }
/// ```
///
/// The [message] field is the backend's human-readable text and should be
/// displayed directly to the user (e.g. via toast notifications).
class ApiResponse<T> {
  final int statusCode;
  final String message;
  final T? data;
  final String? timestamp;
  final String? path;

  const ApiResponse({
    required this.statusCode,
    required this.message,
    this.data,
    this.timestamp,
    this.path,
  });

  /// Parses a raw JSON map into an [ApiResponse].
  ///
  /// [fromJsonT] is an optional callback to deserialize the `data` field
  /// into the concrete type [T]. If `data` is null or [fromJsonT] is null,
  /// [data] will be null.
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

  /// Whether this response indicates a successful operation (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
