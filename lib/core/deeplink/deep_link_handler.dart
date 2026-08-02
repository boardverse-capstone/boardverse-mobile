import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../di/injection.dart';
import '../navigation/widgets/booking_pending_resume_helper.dart';
import '../navigation/pages/main_scaffold.dart';
import '../../features/booking_payment/domain/repositories/booking_repository.dart';

/// Listener cho deep-link SePay return (`boardverse://payment/return?...`).
///
/// App đăng ký scheme `boardverse` trong AndroidManifest.xml. Khi user bấm
/// "Quay lại app" trên trang SePay, app nhận URI này và navigate về tab
/// Bookings (nơi đã có banner resume). Đồng thời trigger `notify` cho
/// `BookingRefreshSignal` để reload state.
class DeepLinkHandler {
  DeepLinkHandler._();

  static final DeepLinkHandler instance = DeepLinkHandler._();

  static const String _paymentReturnScheme = 'boardverse';
  static const String _paymentReturnHost = 'payment';
  static const String _paymentReturnPath = '/return';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  final List<Uri> _queued = [];
  void Function()? _onBookingsRefresh;

  /// Khởi tạo listener. An toàn gọi nhiều lần — chỉ subscribe 1 lần.
  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required void Function() onBookingsRefresh,
  }) async {
    _navigatorKey = navigatorKey;
    _onBookingsRefresh = onBookingsRefresh;
    _subscription ??= _appLinks.uriLinkStream.listen(_handleUri);
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      if (kDebugMode) debugPrint('DeepLinkHandler initial link error: $e');
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Gọi từ widget khi navigator đã mount để consume URI đã queue.
  void onNavigatorReady() => _tryConsumeQueue();

  void _handleUri(Uri uri) {
    if (_isPaymentReturn(uri)) {
      _queued.add(uri);
      _tryConsumeQueue();
    }
  }

  bool _isPaymentReturn(Uri uri) {
    return uri.scheme == _paymentReturnScheme &&
        uri.host == _paymentReturnHost &&
        uri.path == _paymentReturnPath;
  }

  void _tryConsumeQueue() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    while (_queued.isNotEmpty) {
      final uri = _queued.removeAt(0);
      _navigateToBookings(nav);
      // Fire-and-forget; errors đã được log nội bộ.
      unawaited(_triggerResume(uri));
    }
  }

  void _navigateToBookings(NavigatorState nav) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainScaffold(initialTabIndex: 1),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _triggerResume(Uri uri) async {
    final helper = sl<BookingPersistenceResumeHelper>();
    final repo = sl<BookingRepository>();
    // Re-save id từ query (nếu có).
    final depositId = uri.queryParameters['depositId'];
    final bookingId = uri.queryParameters['bookingId'];
    if (depositId != null && depositId.isNotEmpty) {
      final status = await helper.fetchDepositStatus(depositId);
      if (status != null) {
        await repo.savePendingDepositId(depositId);
      } else {
        await helper.clearPending();
      }
    } else if (bookingId != null && bookingId.isNotEmpty) {
      await repo.savePendingBookingId(bookingId);
    }
    _onBookingsRefresh?.call();
  }
}