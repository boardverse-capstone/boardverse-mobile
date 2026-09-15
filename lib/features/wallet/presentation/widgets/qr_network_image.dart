import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/qr_image_loader.dart';

/// Widget hiển thị ảnh QR với fallback chain.
///
/// Nguồn ảnh (ưu tiên giảm dần):
/// 1. **`qrImageBase64`** (từ `TopUpQuoteEntity`): backend proxy từ
///    vietqr.app server-side, embed trong JSON response. Không cần
///    network, không lo CORS.
/// 2. **`qrUrl`** (CDN vietqr.app): dùng `QrImageLoader` (Dio + Chrome
///    UA). Mobile only — web sẽ skip vì CORS.
/// 3. **`paymentUrl`**: render QR matrix local từ URL này. QR matrix
///    thuần, vẫn scan được nhưng không có logo/viền.
/// 4. Placeholder icon nếu cả 3 đều rỗng / fail.
///
/// Animation: bytes load xong → fade-in 280ms cho mượt. QR matrix local
/// render ngay frame đầu.
class QrNetworkImage extends StatefulWidget {
  const QrNetworkImage({
    required this.qrUrl,
    required this.paymentUrl,
    this.qrImageBase64,
    this.size = 200,
    this.backgroundColor = Colors.white,
    super.key,
  });

  /// URL ảnh QR từ SePay/vietqr CDN.
  final String qrUrl;

  /// URL thanh toán — dùng cho `QrImageView` local fallback.
  final String paymentUrl;

  /// Ảnh QR PNG đã encode Base64 từ backend.
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

    // Nguồn 1: Render ảnh QR từ base64 (no network).
    if (hasBase64) {
      return _frameRemoteImage(
        bytes: base64Bytes,
        size: size,
      );
    }

    // Nguồn 2: Mobile — download từ qrUrl qua Dio.
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

            return _fallbackOrLocalQr(
              size: size,
              caption: 'Không tải được ảnh QR — dùng mã này.',
            );
          },
        ),
      );
    }

    // Nguồn 3: Web (no base64) — render QR matrix local.
    return _fallbackOrLocalQr(size: size);
  }

  /// Render ảnh QR từ bytes (PNG/JPEG) với fade-in animation.
  ///
  /// Dùng cho cả base64 lẫn Dio download.
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
            return _frameLocalQr(size: size);
          },
        ),
      ),
    );
  }

  /// Fallback local QR matrix (từ `paymentUrl`).
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
  Widget _frameLocalQr({required double size}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        backgroundColor: widget.backgroundColor,
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
