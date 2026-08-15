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
        // Đặt `responseType: ResponseType.json` để Dio parse body thành
        // `Map<String, dynamic>` thay vì `String`. Kết hợp với việc thêm
        // `charset=utf-8` vào `Accept` header, backend phản hồi với
        // Content-Type đúng chuẩn sẽ được giải mã UTF-8 → giữ nguyên
        // ký tự tiếng Việt (đ, ă, ơ, ...) trong các trường như
        // `message` của error envelope.
        //
        // Nếu backend trả sai Content-Type (không có charset) thì Dio
        // vẫn parse được vì đây là JSON hợp lệ — UTF-8 là mặc định của
        // RFC 8259 cho JSON.
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      ),
    );

    // Attach the auth interceptor (auto Bearer + refresh flow).
    dio.interceptors.add(authInterceptor);

    // Pretty-print logs in debug mode.
    //
    // ⚠️ `LogInterceptor` mặc định của Dio dùng `jsonEncode` để in body,
    // mà `jsonEncode` mặc định ESCAPE non-ASCII thành `\uXXXX` (vd:
    // `Tên đăng nhập` → `T\u00EAn \u0111\u0103ng nh\u1EADp`). Điều này
    // dễ gây hiểu nhầm rằng data thật trong app bị escape — trong khi
    // thực tế chỉ là log debug, `state.message` trong `AuthFailure`
    // vẫn là chuỗi UTF-8 đầy đủ và toast hiển thị đúng.
    //
    // Custom interceptor in raw response/request — KHÔNG escape Unicode,
    // vẫn giữ indent cho dễ đọc.
    assert(() {
      dio.interceptors.add(
        _PrettyLogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
      return true;
    }());
  }
}

/// Interceptor log debug "thân thiện" — không escape Unicode ký tự
/// tiếng Việt (đ, ă, ơ, ...) như `LogInterceptor` mặc định của Dio.
///
/// Thay vì dump body qua `jsonEncode`, ta in trực tiếp String (response
/// data đã được Dio parse thành `Map`/`String` UTF-8 từ trước đó).
///
/// Lưu ý: log này CHỈ dùng để debug. Data thật trong app (vd:
/// `state.message`) là chuỗi UTF-8 đầy đủ — toast hiển thị đúng.
/// Log chỉ hiển thị dạng escape vì `print(Map)` trên một số platform
/// dùng `JsonEncoder` nội bộ — đây là hành vi mong đợi của Dart.
///
/// Format:
/// ```
/// ╔═ Dio Request ════════════════════════════
/// ║ POST  https://api.example.com/...
/// ║ Body: {key: Tên đăng nhập}
/// ╚═══════════════════════════════════════════
/// ╔═ Dio Response ═══════════════════════════
/// ║ 401  https://api.example.com/...
/// ║ Body: {statusCode: 401, message: Tên đăng nhập sai}
/// ╚═══════════════════════════════════════════
/// ```
class _PrettyLogInterceptor extends Interceptor {
  _PrettyLogInterceptor({
    this.requestBody = true,
    this.responseBody = true,
    this.error = true,
  });

  final bool requestBody;
  final bool responseBody;
  final bool error;

  void _printBlock(String title, List<String> lines) {
    const border = '══════════════════════════════════════════';
    // ignore: avoid_print
    print('╔═ $title $border');
    for (final line in lines) {
      // ignore: avoid_print
      print('║ $line');
    }
    // ignore: avoid_print
    print('╚${'═' * (border.length + title.length + 4)}');
  }

  String _formatBody(Object? body) {
    if (body == null) return '<empty>';
    if (body is String) return body;
    // In trực tiếp Map/List — Dart `print` cho Map gọi `toString()` giữ
    // nguyên Unicode (chỉ JSON.stringify từ JS mới escape).
    return body.toString();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final lines = <String>[
      '${options.method}  ${options.uri}',
      if (requestBody && options.data != null)
        'Body: ${_formatBody(options.data)}',
    ];
    _printBlock('Dio Request', lines);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final lines = <String>[
      '${response.statusCode}  ${response.requestOptions.uri}',
      if (responseBody && response.data != null)
        'Body: ${_formatBody(response.data)}',
    ];
    _printBlock('Dio Response', lines);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!error) {
      handler.next(err);
      return;
    }
    final status = err.response?.statusCode ?? 'ERR';
    final lines = <String>[
      '$status  ${err.requestOptions.uri}',
      'Error: ${err.type.name}',
      if (err.message != null) 'Message: ${err.message}',
      if (err.response?.data != null)
        'Body: ${_formatBody(err.response!.data)}',
    ];
    _printBlock('Dio Error', lines);
    handler.next(err);
  }
}
