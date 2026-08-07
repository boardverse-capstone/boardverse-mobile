import 'package:url_launcher/url_launcher.dart';

import '../../features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import '../../features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';

/// Helper tập trung cho các thao tác liên quan tới cafe info (phone, address,
/// directions URL) — dùng cho Phase B (Cafe Approval) + Phase C ("Đến quán").
///
/// Tách riêng để:
/// - Tránh duplicate logic giữa `LobbyPendingCafeApprovalPage` (Phase B) và
///   `LobbyCheckInSection` (Phase C).
/// - Cache `cafeId → CafeDetailEntity` trong 1 vòng đời nav để không spam API.
class CafeInfoHelper {
  CafeInfoHelper._();

  /// In-memory cache: cafeId → (CafeDetailEntity, fetchTimestamp).
  static final Map<String, _CafeCacheEntry> _cache = {};

  /// Time-to-live cho cache entry — 5 phút. Sau đó refetch.
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Lấy thông tin cafe detail (gồm phone, lat/lng, address) theo id.
  /// Trả null nếu fail (network / 404).
  static Future<CafeDetailEntity?> fetchCafe(
    String cafeId, {
    required MatchmakingRepository repo,
  }) async {
    if (cafeId.isEmpty) return null;

    final cached = _cache[cafeId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return cached.cafe;
    }

    final result = await repo.getCafeDetail(cafeId);
    final cafe = result.fold<CafeDetailEntity?>(
      (_) => null,
      (c) => c,
    );
    if (cafe != null) {
      _cache[cafeId] = _CafeCacheEntry(
        cafe: cafe,
        fetchedAt: DateTime.now(),
      );
    }
    return cafe;
  }

  /// Mở Google Maps chỉ đường tới cafe.
  ///
  /// Ưu tiên:
  /// 1. `google.navigation:q=lat,lng` (deep-link vào Google Maps app, nếu có).
  /// 2. `https://www.google.com/maps/dir/?api=1&destination=lat,lng` (web/app).
  /// 3. Search theo address (khi cafe không có lat/lng).
  ///
  /// Trả về true nếu đã launch thành công. Caller nên show error snackbar
  /// nếu trả false.
  static Future<bool> openDirections(CafeDetailEntity cafe) async {
    if (cafe.latitude != null && cafe.longitude != null) {
      // 1. Deep-link vào Google Maps app.
      final navUri = Uri.parse(
        'google.navigation:q=${cafe.latitude},${cafe.longitude}',
      );
      if (await canLaunchUrl(navUri)) {
        return launchUrl(navUri, mode: LaunchMode.externalApplication);
      }

      // 2. Fallback web URL.
      final fallback = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${cafe.latitude},${cafe.longitude}'
        '&travelmode=driving',
      );
      if (await canLaunchUrl(fallback)) {
        return launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    }

    // 3. Search theo address (lat/lng null hoặc mọi fallback đều fail).
    final searchUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(cafe.address)}',
    );
    return launchUrl(searchUri, mode: LaunchMode.externalApplication);
  }

  /// Mở phone dialer với `tel:` URI.
  ///
  /// Trả về true nếu đã launch thành công (có app dialer trên thiết bị).
  static Future<bool> callCafe(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Clear cache — dùng khi user logout / mode change.
  static void clearCache() {
    _cache.clear();
  }
}

class _CafeCacheEntry {
  final CafeDetailEntity cafe;
  final DateTime fetchedAt;

  _CafeCacheEntry({required this.cafe, required this.fetchedAt});
}
