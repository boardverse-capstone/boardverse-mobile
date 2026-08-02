/// Domain events cho FCM push notification handling.
///
/// Mirror `.agents/docs/apis_docs/notifications.md` §45-95 — 2 events:
/// - `LobbyAutoCancelled`
/// - `CafePricingChanged`
///
/// Implementation thực tế dùng `firebase_messaging` package — service này
/// chỉ là abstraction để UI đăng ký listener và react với payload.
library;

sealed class FcmPushEvent {
  /// Deep-link/target mà notification trỏ tới (vd: `boardverse://booking/xyz`).
  final String? deepLink;
  final Map<String, dynamic> data;

  const FcmPushEvent({this.deepLink, this.data = const {}});
}

class LobbyAutoCancelledFcmEvent extends FcmPushEvent {
  final String lobbyId;
  final String reason;
  const LobbyAutoCancelledFcmEvent({
    required this.lobbyId,
    required this.reason,
    super.deepLink,
    super.data,
  });
}

class CafePricingChangedFcmEvent extends FcmPushEvent {
  final String cafeId;
  final Map<String, dynamic> pricing;
  const CafePricingChangedFcmEvent({
    required this.cafeId,
    required this.pricing,
    super.deepLink,
    super.data,
  });
}

/// Fallback cho payload không match schema — log + bỏ qua.
class UnknownFcmEvent extends FcmPushEvent {
  const UnknownFcmEvent({super.deepLink, super.data});
}