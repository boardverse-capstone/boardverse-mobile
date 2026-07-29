import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/services/cloudinary/cloudinary_service.dart';

/// Result returned by the avatar upload pipeline. The caller is responsible
/// for pushing the resulting URL back via [ProfileCubit.updateAvatar].
class AvatarUploadResult {
  const AvatarUploadResult(this.url);
  final String url;
}

/// Thrown when the upload pipeline cannot complete (picker, upload, config).
///
/// Message `__cancelled__` is a sentinel for "user cancelled the picker" —
/// the controller treats it as a non-error and returns `null` from
/// [runWithFeedback] instead of rethrowing.
class AvatarUploadException implements Exception {
  const AvatarUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Encapsulates the 3-step avatar upload flow:
/// 1. Pick an image from the gallery.
/// 2. Upload the file to Cloudinary.
/// 3. Hand the resulting URL back to the caller.
///
/// Callers should wrap calls in [runWithFeedback] to display loading / error
/// UI consistently across the app.
class AvatarUploadController {
  final ImagePicker _picker;
  final CloudinaryService? _cloudinary;

  AvatarUploadController({ImagePicker? picker})
      : _picker = picker ?? ImagePicker(),
        _cloudinary = sl.isRegistered<CloudinaryService>()
            ? sl<CloudinaryService>()
            : null;

  /// Returns `true` if Cloudinary is configured. Use this to gate the UI
  /// (e.g. disabling the avatar tap).
  bool get isCloudinaryConfigured => _cloudinary != null;

  /// Runs the full upload pipeline. Returns the secure URL on success.
  ///
  /// Throws [AvatarUploadException] for any step failure (picker unavailable,
  /// user cancelled, cloudinary not configured, upload error).
  Future<AvatarUploadResult> pickAndUpload() async {
    if (!isCloudinaryConfigured) {
      throw const AvatarUploadException('Cloudinary chưa được cấu hình.');
    }

    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (e) {
      throw AvatarUploadException('Không thể mở thư viện ảnh: $e');
    }

    if (picked == null) {
      throw const AvatarUploadException('__cancelled__');
    }

    try {
      final url = await _cloudinary!.uploadImage(
        file: File(picked.path),
        folder: 'boardverse/avatars',
      );
      return AvatarUploadResult(url);
    } catch (e) {
      throw AvatarUploadException('Upload thất bại: $e');
    }
  }

  /// Convenience: shows a modal loading dialog while the upload is in flight,
  /// then dismisses it. Returns the [AvatarUploadResult] or `null` when the
  /// user cancelled.
  ///
  /// Callers should invoke `context.read<ProfileCubit>().updateAvatar(url)`
  /// after this method returns successfully.
  Future<AvatarUploadResult?> runWithFeedback(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UploadingDialog(),
    );

    try {
      final result = await pickAndUpload();
      if (navigator.canPop()) navigator.pop();
      return result;
    } on AvatarUploadException catch (e) {
      if (navigator.canPop()) navigator.pop();
      if (e.message == '__cancelled__') return null;
      rethrow;
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      throw AvatarUploadException('Upload thất bại: $e');
    }
  }
}

class _UploadingDialog extends StatelessWidget {
  const _UploadingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(
            'Đang tải ảnh lên...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
