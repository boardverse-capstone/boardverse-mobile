import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service download ảnh QR SePay/vietqr với custom User-Agent.
///
/// ## Tại sao không dùng `Image.network`?
///
/// `Image.network` của Flutter dùng `dart:io HttpClient` mặc định với
/// User-Agent `"Dart/3.x (dart:io)"`. Nhiều CDN (Cloudflare, vietqr.app,
/// imgur, ...) block UA này vì cho là bot/script → trả 403 Forbidden
/// hoặc HTML error page → `Image.network.errorBuilder` chạy → QR trắng
/// trên UI mobile.
///
/// Trong khi đó browser (Chrome, Safari) gửi UA đầy đủ:
/// ```
/// Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
///   (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
/// ```
/// → CDN cho qua → ảnh QR hiển thị OK trên web.
///
/// ## Fix
///
/// Dùng `Dio` với UA giống Chrome để bypass. Decode bytes thành widget
/// bằng `Image.memory` (lib Flutter tự render PNG/JPEG).
///
/// ## Lưu ý quan trọng: Flutter Web CORS
///
/// Trên **Flutter Web**, Dio dùng `XMLHttpRequest` của browser. Browser
/// chặn các header KHÔNG nằm trong [CORS safelist](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests)
/// — `User-Agent` nằm trong nhóm này. Đặt custom `User-Agent` trên web
/// sẽ trigger preflight `OPTIONS` request → server không respond
/// `Access-Control-Allow-Headers` → CORS error.
///
/// Trên web browser TỰ ĐỘNG gửi UA `Mozilla/5.0 ... Chrome/...` rồi,
/// nên KHÔNG CẦN (và KHÔNG ĐƯỢC) set custom UA trên web.
///
/// → Logic phân nhánh bằng `kIsWeb`:
///
/// - **Web**: chỉ set `Accept` + `Accept-Language` (CORS-safe headers).
/// - **Mobile (Android/iOS)**: set thêm `User-Agent` để bypass CDN
///   block "Dart" UA.
///
/// ## Cache
///
/// Cache in-memory theo URL trong suốt lifetime app — tránh download
/// lại khi user đóng/mở bottom sheet nhiều lần. Không cache disk vì
/// QR có `expiresAt` ngắn (10 phút).
class QrImageLoader {
  QrImageLoader({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{}

      // ignore: unused_element
      ;

  static Dio _buildDio() {
    // Headers CHỈ chứa các giá trị nằm trong CORS safelist
    // (Accept, Accept-Language, Content-Language, Content-Type, Range).
    // KHÔNG set User-Agent trên web — browser tự gửi rồi và sẽ bị
    // CORS block nếu override.
    final headers = <String, String>{
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,'
          '*/*;q=0.8',
      'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
    };

    // Mobile-only: set User-Agent để bypass CDN block "Dart" UA.
    // Trên mobile Dio dùng `dart:io HttpClient` — KHÔNG có CORS nên
    // custom header hoạt động bình thường.
    if (!kIsWeb) {
      headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/120.0.0.0 Safari/537.36';
    }

    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.bytes,
        headers: headers,
        followRedirects: true,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
  }

  /// Download bytes ảnh QR từ [qrUrl].
  ///
  /// Throw [QrImageLoadException] nếu:
  /// - URL rỗng
  /// - HTTP non-2xx (403, 404, 500, ...)
  /// - Network error / timeout
  /// - Response body rỗng
  ///
  /// Bytes được cache in-memory theo URL — gọi lại với cùng URL trả
  /// về ngay lập tức (không tốn request).
  Future<Uint8List> loadBytes(String qrUrl) async {
    if (qrUrl.isEmpty) {
      throw const QrImageLoadException('QR URL trống.');
    }

    // In-memory cache.
    final cached = _cache[qrUrl];
    if (cached != null) return cached;

    try {
      final response = await _dio.get<Uint8List>(qrUrl);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const QrImageLoadException('Response body rỗng.');
      }

      // Verify PNG/JPEG magic bytes — tránh trường hợp CDN trả HTML
      // error page mà status vẫn 200.
      if (!_looksLikeImage(bytes)) {
        throw const QrImageLoadException(
          'Response không phải ảnh (CDN có thể đã trả HTML error).',
        );
      }

      _cache[qrUrl] = bytes;
      return bytes;
    } on DioException catch (e) {
      throw QrImageLoadException(
        'HTTP ${e.response?.statusCode ?? e.type.name}: '
        '${e.message ?? "không rõ"}',
      );
    } catch (e) {
      if (e is QrImageLoadException) rethrow;
      throw QrImageLoadException('Lỗi không xác định: $e');
    }
  }

  /// Xóa cache (vd: khi user đổi số tiền → URL mới cần load lại).
  static void clearCache() => _cache.clear();

  bool _looksLikeImage(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // GIF: GIF87a or GIF89a
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }
}

class QrImageLoadException implements Exception {
  const QrImageLoadException(this.message);

  final String message;

  @override
  String toString() => 'QrImageLoadException: $message';
}
