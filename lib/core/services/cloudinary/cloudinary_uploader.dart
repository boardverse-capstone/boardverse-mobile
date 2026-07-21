import 'dart:io';

import 'package:dio/dio.dart';

import 'cloudinary_config.dart';

/// Result envelope returned by [CloudinaryUploader.upload].
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.bytes,
    required this.format,
    this.width,
    this.height,
  });

  /// The HTTPS URL to store in the backend. Always `https://`.
  final String secureUrl;

  /// The Cloudinary asset id (without folder prefix stripped).
  /// Pass this to `buildUrl` if you need a derived transformation later.
  final String publicId;

  /// Original uploaded file size in bytes.
  final int bytes;

  /// File format returned by Cloudinary (e.g. `jpg`, `png`, `webp`).
  final String format;

  /// Optional intrinsic dimensions reported by Cloudinary.
  final int? width;
  final int? height;
}

/// Thrown when Cloudinary rejects an upload (network, auth, quota, ...).
class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'CloudinaryUploadException(message: $message, statusCode: $statusCode)';
}

/// Uploads files to Cloudinary via the unsigned upload endpoint.
///
/// We deliberately use `dio` (already in the project) instead of
/// `cloudinary_flutter`'s uploader so the call site is explicit,
/// testable, and decoupled from Flutter widget lifecycle.
class CloudinaryUploader {
  CloudinaryUploader({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
              ),
            );

  final Dio _dio;

  /// Upload a single file as `image` resource to Cloudinary.
  ///
  /// Returns the secure URL ready to be saved on the backend.
  /// [folder] and [publicId] are optional; [publicId] without an
  /// extension lets Cloudinary derive the format from the uploaded bytes.
  Future<CloudinaryUploadResult> upload({
    required File file,
    required String folder,
    String? publicId,
    void Function(double progress)? onProgress,
  }) async {
    CloudinaryConfig.assertConfigured();

    final fileName = publicId ?? file.uri.pathSegments.last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      'upload_preset': CloudinaryConfig.uploadPreset,
      'folder': folder,
      'public_id': ?publicId,
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        CloudinaryConfig.uploadEndpoint(),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );

      final data = response.data;
      if (data == null) {
        throw const CloudinaryUploadException(
          'Cloudinary trả về response rỗng.',
        );
      }

      final secureUrl = data['secure_url'] as String?;
      final returnedPublicId = data['public_id'] as String?;
      final bytes = (data['bytes'] as num?)?.toInt() ?? 0;
      final format = data['format'] as String? ?? '';
      final width = (data['width'] as num?)?.toInt();
      final height = (data['height'] as num?)?.toInt();

      if (secureUrl == null || returnedPublicId == null) {
        throw CloudinaryUploadException(
          'Cloudinary response thiếu secure_url/public_id: $data',
          statusCode: response.statusCode,
        );
      }

      return CloudinaryUploadResult(
        secureUrl: secureUrl,
        publicId: returnedPublicId,
        bytes: bytes,
        format: format,
        width: width,
        height: height,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final apiMessage = body is Map && body['error'] is Map
          ? (body['error']['message'] as String?)
          : null;
      throw CloudinaryUploadException(
        apiMessage ?? e.message ?? 'Upload thất bại.',
        statusCode: status,
      );
    }
  }
}