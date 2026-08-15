import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';

import 'app_toast_card.dart';

/// Helpers hiển thị toast thống nhất cho toàn bộ app.
///
/// **Mục đích**:
/// - Gom logic show toast vào một chỗ (trước đây mỗi auth page tự viết lại).
/// - Đảm bảo **message không bao giờ rỗng** — fallback an toàn nếu backend
///   trả `message: ""` hoặc `null` để tránh toast trống gây UX tệ.
/// - Dùng [ErrorToastCard] / [SuccessToastCard] chuyên dụng (neo-brutalism
///   style) cho nhất quán với design system v4.0.
///
/// **Vị trí hiển thị**: top — không che keyboard / button dưới.
/// **Duration**: 3 giây cho error / success — đủ đọc nhưng không chờ lâu.
class AppToast {
  AppToast._();

  /// Hiển thị error toast với message từ backend.
  ///
  /// Nếu [message] rỗng → fallback `defaultMessage` (mặc định
  /// `'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.'`).
  static void showError(
    BuildContext context,
    String? message, {
    String defaultMessage = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
    int seconds = 3,
  }) {
    final safeMessage = (message == null || message.trim().isEmpty)
        ? defaultMessage
        : message;
    _showTop(
      context,
      ErrorToastCard(message: safeMessage),
      seconds: seconds,
    );
  }

  /// Hiển thị success toast.
  static void showSuccess(
    BuildContext context,
    String? message, {
    String defaultMessage = 'Thành công!',
    int seconds = 3,
  }) {
    final safeMessage = (message == null || message.trim().isEmpty)
        ? defaultMessage
        : message;
    _showTop(
      context,
      SuccessToastCard(message: safeMessage),
      seconds: seconds,
    );
  }

  /// Internal helper — show delight toast ở top với widget bất kỳ.
  static void _showTop(
    BuildContext context,
    Widget card, {
    required int seconds,
  }) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: Duration(seconds: seconds),
      position: DelightSnackbarPosition.top,
      builder: (_) => card,
    ).show(context);
  }
}
