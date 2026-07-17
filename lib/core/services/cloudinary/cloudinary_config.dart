import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration for Cloudinary image uploads.
///
/// Reads values from the `.env` file (loaded via `flutter_dotenv`).
/// Keeping these in `.env` lets the same binary talk to different
/// Cloudinary accounts per environment without code changes.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Cloudinary cloud name (visible in the Cloudinary dashboard URL
  /// and Account Details page).
  static String get cloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  /// Unsigned upload preset name. Created in Settings → Upload
  /// with signing mode = "Unsigned".
  static String get uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Default folder used when an upload caller doesn't specify one.
  /// Helps keep assets organized in the Cloudinary Media Library.
  static String get defaultFolder =>
      dotenv.env['CLOUDINARY_DEFAULT_FOLDER'] ?? 'boardverse/uploads';

  /// Whether `buildUrl` should automatically append `f_auto/q_auto`
  /// to delivery URLs (recommended for most production traffic).
  static bool get autoOptimize {
    final raw = dotenv.env['CLOUDINARY_AUTO_OPTIMIZE'];
    return (raw ?? 'true').toLowerCase() == 'true';
  }

  /// `true` only when both required values are present.
  /// Lets the app boot (with upload features disabled) even if the
  /// operator hasn't filled in their Cloudinary credentials yet.
  static bool get isValid =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Throws a [StateError] when the service is used without config.
  /// Call this at the entry-point of every public method so misuse
  /// fails fast with a helpful message.
  static void assertConfigured() {
    if (!isValid) {
      throw StateError(
        'Cloudinary chưa được cấu hình. '
        'Vui lòng thêm CLOUDINARY_CLOUD_NAME và CLOUDINARY_UPLOAD_PRESET '
        'vào file .env và restart app.',
      );
    }
  }

  /// Cloudinary upload endpoint for unsigned image uploads.
  /// Pattern: https://api.cloudinary.com/v1_1/{cloudName}/image/upload
  static String uploadEndpoint() =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}