import 'package:cloudinary_url_gen/cloudinary.dart' as cg;

import 'transformations/cloudinary_transformation.dart';

/// Builds HTTPS delivery URLs for a stored Cloudinary asset + transformation.
///
/// The returned URL is **always HTTPS** (secure). Append `f_auto/q_auto`
/// happens inside [CloudinaryTransformation.applyOptimization] which the
/// concrete transformations already invoke.
class CloudinaryUrlBuilder {
  CloudinaryUrlBuilder(this._cloudinary);

  final cg.Cloudinary _cloudinary;

  /// Build a delivery URL.
  ///
  /// [publicId] is the value returned in [CloudinaryUploadResult.publicId]
  /// (typically `folder/name`).
  String build(String publicId, CloudinaryTransformation transformation) {
    return _cloudinary
        .image(publicId)
        .transformation(transformation.toCldTransformation())
        .toString();
  }
}