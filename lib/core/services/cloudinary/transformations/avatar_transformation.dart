import 'package:cloudinary_url_gen/transformation/gravity/gravity.dart';
import 'package:cloudinary_url_gen/transformation/resize/resize.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';

import 'cloudinary_transformation.dart';

/// Square avatar transformation with face-aware cropping.
///
/// Use [AvatarTransformation.medium] (200px) for chat/list rows,
/// [AvatarTransformation.large] (400px) for profile header,
/// [AvatarTransformation.small] (96px) for inline mentions.
///
/// Transforms: `c_fill,g_auto,w_$size,h_$size` + `f_auto/q_auto`.
class AvatarTransformation extends CloudinaryTransformation {
  const AvatarTransformation.small()
      : size = 96;

  const AvatarTransformation.medium()
      : size = 200;

  const AvatarTransformation.large()
      : size = 400;

  const AvatarTransformation.custom({required this.size});

  final int size;

  @override
  Transformation toCldTransformation() {
    final t = Transformation()
      ..resize(Resize.fill()
        ..width(size)
        ..height(size)
        ..gravity(Gravity.autoGravity()));
    applyOptimization(t);
    return t;
  }
}