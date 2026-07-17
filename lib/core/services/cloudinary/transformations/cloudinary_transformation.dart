import 'package:cloudinary_url_gen/transformation/delivery/delivery.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery_actions.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';

import '../cloudinary_config.dart';

/// Base contract for any Cloudinary delivery transformation.
///
/// Subclasses describe how an asset should be delivered
/// (resize, crop, format, quality). Build URL via
/// [CloudinaryUrlBuilder.build] using the [toCldTransformation] output.
///
/// Best-practice: concrete classes always call [applyOptimization]
/// at the end of their chain so every delivery URL gets
/// `f_auto/q_auto` unless explicitly disabled in `.env`.
abstract class CloudinaryTransformation {
  const CloudinaryTransformation();

  /// Build the SDK transformation chain.
  /// Subclasses compose `Transformation()` actions and must
  /// call [applyOptimization] as the final step.
  Transformation toCldTransformation();

  /// Append `f_auto/q_auto` to the chain so the browser receives
  /// the optimal format (WebP/AVIF) and quality automatically.
  /// Skipped when [CloudinaryConfig.autoOptimize] is `false`.
  void applyOptimization(Transformation t) {
    if (!CloudinaryConfig.autoOptimize) return;
    t.delivery(Delivery.format(Format.auto));
    t.delivery(Delivery.quality(Quality.auto()));
  }
}