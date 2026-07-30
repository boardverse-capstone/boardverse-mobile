import 'package:flutter/widgets.dart';

/// Stub cho non-web platform — luôn trả `SizedBox.shrink()` để widget
/// không lỗi import khi build cho Android/iOS/Windows.
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
  return const SizedBox.shrink();
}