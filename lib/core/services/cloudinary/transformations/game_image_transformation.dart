import 'package:cloudinary_url_gen/transformation/gravity/gravity.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';

import 'cloudinary_transformation.dart';

/// 16:9 cover image transformation for board-game cards and hero banners.
///
/// `c_fill,g_auto,w_$width,h_$height` keeps the focal point centered
/// while cropping to the requested aspect ratio.
class GameImageTransformation extends CloudinaryTransformation {
  const GameImageTransformation.card()
      : width = 600,
        height = 400;

  const GameImageTransformation.hero()
      : width = 1280,
        height = 720;

  const GameImageTransformation.thumb()
      : width = 300,
        height = 200;

  const GameImageTransformation.custom({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  @override
  Transformation toCldTransformation() {
    final t = Transformation()
      ..resize(Resize.fill()
        ..width(width)
        ..height(height)
        ..gravity(Gravity.autoGravity()));
    applyOptimization(t);
    return t;
  }
}