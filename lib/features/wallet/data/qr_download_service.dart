import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service download/lưu ảnh QR SePay về thiết bị để player mở app ngân
/// hàng quét.
///
/// Lý do không mở `paymentUrl` trực tiếp: trên điện thoại, SePay web
/// khó chuyển sang app ngân hàng. Lưu QR về gallery → mở app NH → quét
/// QR từ thư viện → thanh toán ổn định hơn nhiều.
///
/// Nguồn bytes (ưu tiên giảm dần):
/// 1. `qrImageBytes` (từ `TopUpQuoteEntity.qrImageBase64`) — backend
///    embed sẵn, không tốn HTTP request.
/// 2. `qrUrl` (CDN vietqr.app) — tải về, mobile only.
/// 3. Web không hỗ trợ Gal → fallback mở URL trong tab mới.
class QrDownloadService {
  QrDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Lưu ảnh QR vào gallery.
  ///
  /// Khuyến nghị truyền [qrImageBytes] để tránh HTTP request, đặc biệt
  /// trên Flutter Web.
  ///
  /// Trả về tên file đã lưu (để hiển thị snackbar cho user).
  /// Throw [QrDownloadException] nếu có lỗi (network, permission, storage).
  Future<String> downloadAndSaveQr({
    required String qrUrl,
    required String orderId,
    Uint8List? qrImageBytes,
  }) async {
    if (qrUrl.isEmpty && qrImageBytes == null) {
      throw const QrDownloadException('Không có ảnh QR — không thể tải.');
    }

    // Web: không hỗ trợ Gal, fallback mở URL trong tab mới.
    if (kIsWeb) {
      if (qrUrl.isNotEmpty) {
        final uri = Uri.parse(qrUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      throw const QrDownloadException(
        'Trên web, vui lòng click chuột phải vào ảnh QR để lưu.',
      );
    }

    // Mobile: xin quyền Photos.
    final hasAccess = await Gal.hasAccess(toAlbum: false);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: false);
      if (!granted) {
        throw const QrDownloadException(
          'Bạn cần cấp quyền truy cập Photos để lưu mã QR.',
        );
      }
    }

    // Sanitize orderId cho safe filename.
    final safeOrderId = orderId.replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '_');
    final fileName = 'bvc-qr-$safeOrderId.png';

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);

    try {
      if (qrImageBytes != null && qrImageBytes.isNotEmpty) {
        await file.writeAsBytes(qrImageBytes, flush: true);
      } else {
        await _dio.download(
          qrUrl,
          filePath,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        );
      }
    } on DioException catch (e) {
      throw QrDownloadException(
        'Không tải được ảnh QR: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      throw QrDownloadException('Lỗi lưu ảnh QR: $e');
    }

    final size = await file.length();
    if (size == 0) {
      throw const QrDownloadException('Ảnh QR tải về rỗng — vui lòng thử lại.');
    }

    try {
      await Gal.putImage(filePath, album: 'BoardVerse');
    } on GalException catch (e) {
      throw QrDownloadException('Lưu ảnh thất bại: ${e.type.message}');
    }

    return fileName;
  }
}

class QrDownloadException implements Exception {
  const QrDownloadException(this.message);

  final String message;

  @override
  String toString() => 'QrDownloadException: $message';
}
