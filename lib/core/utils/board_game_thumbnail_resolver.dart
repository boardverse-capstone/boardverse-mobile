import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';

/// Helpers để xử lý URL thumbnail board game qua server proxy.
///
/// **Bối cảnh (build 2026-09-29):** Backend thêm
/// `GET /api/v1/board-games/thumbnail-proxy` để bypass CORS cho Flutter
/// Web (CanvasKit renderer taint canvas khi load ảnh từ upstream không
/// có `Access-Control-Allow-Origin`). Mobile (Android/iOS) load trực
/// tiếp từ upstream vẫn OK nhưng gọi qua proxy cũng hoạt động (tốn
/// thêm 1 round-trip).
///
/// Docs: `.agents/docs/apis_docs/board-games.md` §GET /thumbnail-proxy
class BoardGameThumbnailResolver {
  BoardGameThumbnailResolver._();

  /// Trả URL phù hợp để load thumbnail:
  /// - **Web** (`kIsWeb`): encode URL qua proxy endpoint để bypass CORS.
  /// - **Mobile** (Android/iOS): trả raw URL (load trực tiếp từ BGG CDN).
  /// - URL rỗng: trả `''` để UI hiển thị placeholder.
  ///
  /// **Cache key** nên đặt theo URL gốc (không phải URL proxy) để
  /// cache hit đúng trên cả 2 platform — xem ví dụ trong docs.
  static String resolve(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (!kIsWeb) return rawUrl;
    final encoded = Uri.encodeComponent(rawUrl);
    return '${ApiEndpoints.boardGameThumbnailProxy}?url=$encoded';
  }
}
