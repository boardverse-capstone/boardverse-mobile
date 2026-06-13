import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_interceptor.dart';

/// Configures and exposes a singleton [Dio] instance.
///
/// The base URL is read from the `.env` file via `flutter_dotenv`.
/// This ensures no hardcoded URLs leak into the codebase.
class DioClient {
  late final Dio dio;

  DioClient({required AuthInterceptor authInterceptor}) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach the auth interceptor (auto Bearer + refresh flow).
    dio.interceptors.add(authInterceptor);

    // Pretty-print logs in debug mode.
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
      return true;
    }());
  }
}
