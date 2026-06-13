import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_endpoints.dart';

/// Keys used to persist tokens in [FlutterSecureStorage].
class StorageKeys {
  StorageKeys._();
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}

/// Dio interceptor that:
/// 1. Attaches the stored access token as `Authorization: Bearer <token>`
///    on every outgoing request.
/// 2. On a 401 response, attempts to refresh the token pair via
///    `POST /api/Auth/refresh-token`. If the refresh succeeds the original
///    request is retried transparently; if it fails all tokens are cleared
///    (force logout).
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  /// A dedicated [Dio] instance for the refresh call so we don't
  /// trigger this interceptor recursively.
  late final Dio _refreshDio;

  AuthInterceptor({required this._storage}) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ─── Attach Bearer token ──────────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ─── Handle 401 → attempt refresh ─────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Already a refresh request that failed → give up.
    if (err.requestOptions.path == ApiEndpoints.refreshToken) {
      await _clearTokens();
      return handler.next(err);
    }

    try {
      final storedRefreshToken =
          await _storage.read(key: StorageKeys.refreshToken);

      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        await _clearTokens();
        return handler.next(err);
      }

      // Call refresh endpoint using the separate Dio instance.
      final response = await _refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefreshToken},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>?;

      if (response.statusCode == 200 && data != null) {
        final newAccessToken = data['token'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        // Persist new tokens.
        await _storage.write(
            key: StorageKeys.accessToken, value: newAccessToken);
        await _storage.write(
            key: StorageKeys.refreshToken, value: newRefreshToken);

        // Retry the original request with the fresh token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _refreshDio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } else {
        await _clearTokens();
        return handler.next(err);
      }
    } on DioException {
      await _clearTokens();
      return handler.next(err);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Future<void> _clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
