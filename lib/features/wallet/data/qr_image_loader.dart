import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service download ảnh QR SePay/vietqr với custom User-Agent.
///
/// `Image.network` của Flutter dùng `dart:io HttpClient` mặc định với
/// User-Agent "Dart/3.x (dart:io)". Nhiều CDN (vietqr.app, ...) block
/// UA này và trả HTML error page thay vì ảnh. Dùng `Dio` với UA giống
/// Chrome để bypass.
///
/// Trên Flutter Web, browser tự gửi UA Mozilla nên KHÔNG set custom UA
/// (sẽ trigger CORS preflight). Logic phân nhánh bằng `kIsWeb`:
///
/// - **Web**: chỉ set `Accept` + `Accept-Language` (CORS-safe headers).
/// - **Mobile**: set thêm `User-Agent` để bypass CDN block.
///
/// Cache in-memory theo URL — tránh download lại khi user mở/đóng sheet
/// nhiều lần.
class QrImageLoader {
  QrImageLoader({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static Dio _buildDio() {
    final headers = <String, String>{
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,'
          '*/*;q=0.8',
      'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
    };

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
  /// Bytes được cache in-memory theo URL — gọi lại với cùng URL trả về
  /// ngay lập tức.
  Future<Uint8List> loadBytes(String qrUrl) async {
    if (qrUrl.isEmpty) {
      throw const QrImageLoadException('QR URL trống.');
    }

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
