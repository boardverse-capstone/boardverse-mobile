import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

/// View factory registry — đảm bảo mỗi URL chỉ đăng ký một lần.
final Set<String> _registeredViewTypes = <String>{};

/// Đăng ký `<img>` view cho URL và mount vào DOM.
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Alignment alignment = Alignment.center,
  ImageRepeat repeat = ImageRepeat.noRepeat,
  FilterQuality filterQuality = FilterQuality.medium,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  final viewType = 'safe-network-image-${url.hashCode.abs()}';

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => _buildImgElement(url: url, fit: fit),
    );
  }

  return HtmlElementView(
    viewType: viewType,
  );
}

/// Tạo thẻ `<img>` thuần — KHÔNG set `crossOrigin` để bypass CORS preflight.
/// Browser vẫn render được ảnh dù CDN không có header
/// `Access-Control-Allow-Origin`. Chỉ thao tác đọc pixel (canvas) mới bị block.
html.ImageElement _buildImgElement({required String url, required BoxFit fit}) {
  final img = html.ImageElement()
    ..src = url
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = _boxFitToCss(fit)
    ..style.display = 'block'
    ..alt = '';

  // Placeholder background trong khi ảnh đang load.
  img.style.backgroundColor = '#f0f0f0';

  // Khi load lỗi (404, network error…) → giữ placeholder, không ném exception
  // vì HtmlElementView không có errorBuilder. UI sẽ thấy placeholder xám.
  img.onError.listen((_) {
    img.style.backgroundColor = '#e0e0e0';
  });

  return img;
}

/// Mapping BoxFit → CSS `object-fit`.
String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'cover';
    case BoxFit.fitHeight:
      return 'cover';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}