import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../cubit/auth_cubit.dart';

/// Helper tái sử dụng cho luồng đăng nhập / đăng ký bằng Google.
///
/// Mục đích:
/// - Gom toàn bộ thao tác với `google_sign_in` vào một chỗ để `LoginPage`
///   và `RegisterPage` dùng chung mà không phải duplicate code.
/// - Chuẩn hoá lỗi Google Sign-In (vd: `ApiException: 10` / DEVELOPER_ERROR)
///   thành message tiếng Việt thân thiện với user.
/// - Tự động bật/tắt loading state của caller thông qua callback
///   [onLoadingChanged] để tránh trạng thái "kẹt" khi flow thất bại.
///
/// Gọi từ page:
/// ```dart
/// final helper = GoogleAuthHelper(googleSignIn: GoogleSignIn(
///   clientId: kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
///   serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
/// ));
/// await helper.signIn(
///   context: context,
///   onLoadingChanged: (loading) => setState(() => _isLoading = loading),
///   onError: (msg) => _showToast(msg, isError: true),
/// );
/// ```
class GoogleAuthHelper {
  GoogleAuthHelper({required GoogleSignIn googleSignIn})
      // ignore: prefer_initializing_formals
      : _googleSignIn = googleSignIn;

  final GoogleSignIn _googleSignIn;

  /// Chạy toàn bộ flow Google Sign-In:
  ///
  /// 1. Mở popup/tài khoản Google lấy `idToken`.
  /// 2. Validate env (`GOOGLE_SERVER_CLIENT_ID` cho mobile).
  /// 3. Gọi `AuthCubit.googleLogin(idToken: ...)`.
  /// 4. Phát tín hiệu loading qua [onLoadingChanged] để caller đổi UI.
  /// 5. Nếu có lỗi → gọi [onError] với message tiếng Việt.
  ///
  /// Không emit success/failure trực tiếp — để [AuthCubit] xử lý để tránh
  /// trạng thái không nhất quán giữa các page.
  Future<void> signIn({
    required BuildContext context,
    required ValueChanged<bool> onLoadingChanged,
    required ValueChanged<String> onError,
  }) async {
    // Defensive check trên Android/iOS: thiếu SERVER_CLIENT_ID → fail với
    // PlatformException khó hiểu. Fail-fast với message rõ ràng.
    if (!kIsWeb &&
        (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] == null ||
            dotenv.env['GOOGLE_SERVER_CLIENT_ID']!.isEmpty)) {
      onError(
        'Đăng nhập Google thất bại: thiếu GOOGLE_SERVER_CLIENT_ID trong .env. '
        'Vui lòng liên hệ quản trị viên.',
      );
      return;
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      // User đóng popup → thoát im lặng.
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        onError('Không nhận được idToken từ Google. Vui lòng thử lại.');
        return;
      }

      onLoadingChanged(true);
      if (!context.mounted) return;
      context.read<AuthCubit>().googleLogin(idToken: idToken);
    } catch (e) {
      onLoadingChanged(false);
      onError(_formatError(e));
    }
  }

  /// Chuẩn hoá lỗi Google Sign-In thành message tiếng Việt dễ hiểu.
  ///
  /// `google_sign_in` 6.x trên Android đôi khi ném PlatformException với code
  /// rút gọn (vd: `h4.d: 10,`) tương ứng `ApiException: 10` =
  /// `DEVELOPER_ERROR` (sai Client ID / thiếu SHA-1 / thiếu
  /// google-services.json). Hiển thị code lỗi thô sẽ gây hoang mang cho
  /// người dùng, nên ta map sang message thân thiện.
  String _formatError(Object error) {
    final raw = error.toString();
    if (raw.contains('sign_in_failed') ||
        raw.contains('10') ||
        raw.contains('DEVELOPER_ERROR')) {
      return 'Đăng nhập Google thất bại: cấu hình OAuth chưa đúng. '
          'Vui lòng liên hệ quản trị viên.';
    }
    return 'Đăng nhập Google thất bại: ${error.toString()}';
  }
}