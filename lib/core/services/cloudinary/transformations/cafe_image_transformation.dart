import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';

import 'cloudinary_transformation.dart';

/// Cafe / venue photo transformation.
///
/// `c_fit` preserves the full image (no cropping) and limits the
/// width; height is derived automatically to maintain aspect ratio.
class CafeImageTransformation extends CloudinaryTransformation {
  const CafeImageTransformation.gallery()
      : maxWidth = 800;

  const CafeImageTransformation.detail()
      : maxWidth = 1600;

  const CafeImageTransformation.thumb()
      : maxWidth = 320;

  const CafeImageTransformation.custom({required this.maxWidth});

  final int maxWidth;

  @override
  Transformation toCldTransformation() {
    final t = Transformation()
      ..resize(Resize.fit()..width(maxWidth));
    applyOptimization(t);
    return t;
  }
}