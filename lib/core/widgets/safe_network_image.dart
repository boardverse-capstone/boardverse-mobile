import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'safe_network_image_stub.dart'
    if (dart.library.html) 'safe_network_image_web.dart' as impl;

/// Widget ảnh mạng an toàn — xử lý CORS trên Flutter Web.
///
/// Trên Web, `Image.network` của Flutter dùng `imgElement.crossOrigin = 'anonymous'`
/// để lấy ảnh. Nếu CDN không trả header `Access-Control-Allow-Origin`, ảnh
/// load thất bại dù trình duyệt vẫn hiển thị được bằng `<img>` thường.
///
/// Widget này fallback sang `<img>` thuần qua `HtmlElementView` trên Web,
/// nơi browser sẽ render ảnh trực tiếp mà không yêu cầu CORS headers.
/// Trên Mobile/Desktop, hoạt động như `Image.network` bình thường.
///
/// Cách dùng: thay `Image.network(url, ...)` bằng
/// `SafeNetworkImage(url: url, ...)` — các tham số cơ bản giống hệt `Image`.
class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final ImageRepeat repeat;
  final bool gaplessPlayback;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    this.loadingBuilder,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.repeat = ImageRepeat.noRepeat,
    this.gaplessPlayback = false,
  });

  @override
  Widget build(BuildContext context) {
    // URL rỗng → render placeholder/error ngay để không gọi network layer.
    if (url.isEmpty) {
      return _buildErrorWidget(context);
    }

    if (kIsWeb) {
      return impl.buildWebImage(
        url: url,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: repeat,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, st) =>
          errorBuilder?.call(ctx, err, st) ?? _defaultError(ctx),
      loadingBuilder: loadingBuilder,
      alignment: alignment,
      filterQuality: filterQuality,
      repeat: repeat,
      gaplessPlayback: gaplessPlayback,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return errorBuilder?.call(context, Exception('Empty URL'), null) ??
        _defaultError(context);
  }

  Widget _defaultError(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: theme.colorScheme.outline,
        size: (height ?? width ?? 48) * 0.4,
      ),
    );
  }
}