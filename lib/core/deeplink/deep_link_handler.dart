import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// DeepLinkHandler — currently a no-op placeholder.
///
/// The previous implementation listened for the legacy SePay return URL
/// (`boardverse://payment/return?...`) and forwarded the user to the Bookings
/// tab. After the SePay/booking-payment flow was replaced by the BVC
/// reservation flow, the deep-link scheme no longer exists on the backend
/// and the entire pathway is obsolete.
///
/// The class is kept so existing call sites (`DeepLinkHandler.instance.initialize`
/// in `main.dart` and `DeepLinkHandler.instance.onNavigatorReady` in
/// `MainScaffold`) continue to compile. The handler simply ignores all
/// incoming URIs.
class DeepLinkHandler {
  DeepLinkHandler._();

  static final DeepLinkHandler instance = DeepLinkHandler._();

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required void Function() onBookingsRefresh,
  }) async {
    // No-op: deep-link pipeline was tied to the legacy SePay return scheme
    // (`boardverse://payment/return`). Now obsolete.
  }

  Future<void> dispose() async {}

  /// Public so existing callers (e.g. `MainScaffold`) can still invoke this
  /// hook. With no queued URIs there is nothing to consume.
  void onNavigatorReady() {}

  /// Kept for backwards compatibility — does nothing.
  // ignore: unused_element
  void handleUri(Uri uri) {
    if (kDebugMode) {
      debugPrint('DeepLinkHandler: ignored $uri');
    }
  }
}