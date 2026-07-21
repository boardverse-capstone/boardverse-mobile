import 'dart:io';

import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:flutter/widgets.dart';

import 'cloudinary_config.dart';
import 'cloudinary_uploader.dart';
import 'cloudinary_url_builder.dart';
import 'transformations/cloudinary_transformation.dart';

/// Single entry-point for everything Cloudinary in the app.
///
/// Lives at the core layer (not in any feature folder) so it can be
/// reused by Profile, BoardGame discovery, Reviews, ... without
/// coupling features to each other.
///
/// Register once via `get_it` at app startup:
/// ```dart
/// sl.registerLazySingleton<CloudinaryService>(
///   () => CloudinaryService.fromEnv(),
/// );
/// ```
class CloudinaryService {
  CloudinaryService._({
    required this._uploader,
    required this._urlBuilder,
    required this._client,
  });

  /// Build the service from `.env` config.
  ///
  /// Throws [StateError] if required env vars are missing.
  factory CloudinaryService.fromEnv() {
    CloudinaryConfig.assertConfigured();
    final client = CloudinaryObject.fromCloudName(
      cloudName: CloudinaryConfig.cloudName,
    );
    client.config.urlConfig.secure = true;
    return CloudinaryService._(
      uploader: CloudinaryUploader(),
      urlBuilder: CloudinaryUrlBuilder(client),
      client: client,
    );
  }

  final CloudinaryUploader _uploader;
  final CloudinaryUrlBuilder _urlBuilder;
  final CloudinaryObject _client;

  /// Expose the SDK CloudinaryObject (mainly for [image] widget).
  CloudinaryObject get client => _client;

  /// Whether the service is ready to accept uploads.
  bool get isConfigured => CloudinaryConfig.isValid;

  /// Upload an image file to Cloudinary.
  ///
  /// Returns the **secure URL** ready to be sent to the backend
  /// (e.g. `PUT /api/userprofile/me/avatar { avatarUrl: url }`).
  Future<String> uploadImage({
    required File file,
    String? folder,
    String? publicId,
    void Function(double progress)? onProgress,
  }) async {
    final result = await _uploader.upload(
      file: file,
      folder: folder ?? CloudinaryConfig.defaultFolder,
      publicId: publicId,
      onProgress: onProgress,
    );
    return result.secureUrl;
  }

  /// Upload an image and return the full [CloudinaryUploadResult]
  /// (URL + publicId + dimensions). Use this when you also need
  /// the public_id to derive further delivery URLs later.
  Future<CloudinaryUploadResult> uploadImageDetailed({
    required File file,
    String? folder,
    String? publicId,
    void Function(double progress)? onProgress,
  }) =>
      _uploader.upload(
        file: file,
        folder: folder ?? CloudinaryConfig.defaultFolder,
        publicId: publicId,
        onProgress: onProgress,
      );

  /// Build a delivery URL for a stored asset using a transformation spec.
  ///
  /// Example:
  /// ```dart
  /// final url = service.buildUrl(
  ///   publicId: 'boardverse/avatars/abc123',
  ///   transformation: const AvatarTransformation.medium(),
  /// );
  /// ```
  String buildUrl({
    required String publicId,
    required CloudinaryTransformation transformation,
  }) =>
      _urlBuilder.build(publicId, transformation);

  /// Convenience widget that delivers a transformed image with built-in
  /// caching. Wraps the SDK's `CldImageWidget`.
  Widget image({
    required String publicId,
    required CloudinaryTransformation transformation,
    BoxFit fit = BoxFit.cover,
  }) {
    return CldImageWidget(
      cloudinary: _client,
      publicId: publicId,
      transformation: transformation.toCldTransformation(),
    );
  }
}