import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/qr_image_loader.dart';

/// Widget hiển thị ảnh QR với 3-tier fallback chain.
///
/// ## Priority chain (cao → thấp)
///
/// 1. **`qrImageBase64`** (từ `TopUpQuoteEntity`): backend proxy từ
///    vietqr.app server-side, embed trong JSON response. Đây là nguồn
///    tốt nhất — không cần network call (đã có sẵn), bypass CORS trên
///    Flutter Web, và là ảnh QR đẹp từ VietQR CDN (logo bank + viền).
///
/// 2. **`qrUrl`** (CDN vietqr.app): dùng `QrImageLoader` (Dio với UA
///    giống Chrome) để download bytes, render bằng `Image.memory`.
///    - **Mobile**: hoạt động (vì Dio dùng `dart:io` không có CORS).
///    - **Web**: KHÔNG dùng — vietqr.app CDN không trả CORS header nên
///      browser chặn. (Xem lý do chi tiết trong `QrImageLoader`.)
///
/// 3. **`paymentUrl`** (URL VietQR chứa query params): render `QrImageView`
///    local từ chuỗi URL. QR matrix thuần, vẫn scan được nhưng không có
///    logo/viền. Đây là fallback cuối — luôn work mọi platform.
///
/// 4. **Placeholder icon**: nếu cả 3 đều rỗng / fail.
///
/// ## Animation
///
/// Bytes load xong (từ base64 hoặc Dio) → fade-in 280ms cho mượt.
/// QR matrix local render ngay frame đầu (không cần animation).
///
/// ## UI polish cho QR matrix local
///
/// Bọc trong container có viền + shadow + eye icon overlay → trông
/// giống ảnh QR card, đỡ trơn so với matrix thuần.
class QrNetworkImage extends StatefulWidget {
  const QrNetworkImage({
    required this.qrUrl,
    required this.paymentUrl,
    this.qrImageBase64,
    this.size = 200,
    this.backgroundColor = Colors.white,
    super.key,
  });

  /// URL ảnh QR từ SePay/vietqr CDN (vd `https://vietqr.app/img?...`).
  ///
  /// Tier 2 — mobile only (web sẽ skip vì CORS).
  final String qrUrl;

  /// URL thanh toán — dùng cho `QrImageView` local fallback (Tier 3).
  final String paymentUrl;

  /// Ảnh QR PNG đã encode Base64 từ backend.
  ///
  /// Tier 1 — ưu tiên cao nhất. Decoded `Uint8List` và render ngay
  /// không cần network. Có thể null khi backend cũ chưa hỗ trợ hoặc
  /// proxy thất bại.
  final String? qrImageBase64;

  final double size;
  final Color backgroundColor;

  @override
  State<QrNetworkImage> createState() => _QrNetworkImageState();
}

class _QrNetworkImageState extends State<QrNetworkImage> {
  /// `null` trên web (skip Dio hoàn toàn); `QrImageLoader` trên mobile.
  late final QrImageLoader? _loader = kIsWeb ? null : QrImageLoader();
  Future<Uint8List>? _future;

  /// Decode `qrImageBase64` → bytes. Trả về null nếu rỗng / invalid.
  Uint8List? get _base64Bytes {
    final b64 = widget.qrImageBase64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(QrNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrUrl != widget.qrUrl ||
        oldWidget.qrImageBase64 != widget.qrImageBase64) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    // Tier 1: base64 → render sync, không cần load.
    // Tier 2: qrUrl → load async (mobile only).
    final loader = _loader;
    if (loader == null || widget.qrUrl.isEmpty) {
      _future = null;
      return;
    }
    _future = loader.loadBytes(widget.qrUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;
    final base64Bytes = _base64Bytes;
    final hasBase64 = base64Bytes != null && base64Bytes.isNotEmpty;

    // ── Tier 1: Render ảnh QR từ base64 (NO network) ────────────────
    if (hasBase64) {
      return _frameRemoteImage(
        bytes: base64Bytes,
        size: size,
      );
    }

    // ── Tier 2: Mobile — download từ qrUrl qua Dio ─────────────────
    if (!kIsWeb) {
      final future = _future;
      if (future == null) {
        return _fallbackOrLocalQr(size: size);
      }

      return SizedBox(
        height: size,
        width: size,
        child: FutureBuilder<Uint8List>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasData) {
              return _frameRemoteImage(bytes: snapshot.data!, size: size);
            }

            // Fail → fallback qua Tier 3.
            return _fallbackOrLocalQr(
              size: size,
              caption: 'Không tải được ảnh QR — dùng mã này.',
            );
          },
        ),
      );
    }

    // ── Tier 3: Web (no base64) — render QR matrix local ────────────
    return _fallbackOrLocalQr(size: size);
  }

  /// Render ảnh QR từ bytes (PNG/JPEG) với fade-in animation.
  ///
  /// Dùng cho cả base64 (Tier 1) lẫn Dio download (Tier 2 mobile).
  Widget _frameRemoteImage({
    required Uint8List bytes,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) {
            // Bytes nhận được nhưng không decode được (rare) → fallback local.
            return _frameLocalQr(size: size);
          },
        ),
      ),
    );
  }

  /// Tier 3: fallback local QR matrix (từ `paymentUrl`).
  ///
  /// Dùng khi:
  /// - Web không có base64.
  /// - Mobile download thất bại.
  /// - Base64 decode thất bại (invalid PNG).
  Widget _fallbackOrLocalQr({required double size, String? caption}) {
    if (widget.paymentUrl.isEmpty) {
      return _placeholder(icon: Icons.qr_code_2_rounded, size: size);
    }

    if (caption == null) {
      return _frameLocalQr(size: size);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _frameLocalQr(size: size),
        const SizedBox(height: 6),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Bọc QR matrix trong container có viền + shadow + eye icon overlay.
  ///
  /// Dùng cho cả web (primary) và mobile (fallback) — chỉ cần render
  /// `QrImageView` local. Container + decoration làm QR trông giống
  /// "card" — đỡ trơn so với matrix thuần.
  Widget _frameLocalQr({required double size}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Container "card" chứa QR + padding trong.
    final card = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: widget.paymentUrl,
        version: QrVersions.auto,
        size: size * 0.88,
        // Nền ngoài của QrImageView = màu của card (đã set white).
        backgroundColor: widget.backgroundColor,
        // Module đậm tối đa để tăng contrast scan (kể cả dark mode).
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );

    // Eye icon overlay nhỏ ở góc dưới-trái — gợi ý "QR đã sẵn sàng quét".
    // Icon nằm trong Stack, position cố định trong card.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.backgroundColor.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.center_focus_strong_rounded,
              size: 14,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder({required IconData icon, required double size}) {
    return SizedBox(
      height: size,
      width: size,
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
