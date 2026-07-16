import 'package:flutter/material.dart';

/// Border Radius System - Định nghĩa các giá trị border radius
/// Sử dụng consistent border radius để tạo UI đồng nhất
class AppRadius {
  AppRadius._();

  // ========================
  // BORDER RADIUS VALUES
  // ========================

  /// 4px - Nhỏ nhất, dùng cho tags, chips nhỏ
  static const double radiusXxs = 4.0;

  /// 8px - Small, dùng cho input fields, small buttons
  static const double radiusXs = 8.0;

  /// 12px - Medium small, dùng cho chips, badges
  static const double radiusSm = 12.0;

  /// 16px - Medium, dùng cho cards, dialogs
  static const double radiusMd = 16.0;

  /// 20px - Medium large, dùng cho large cards
  static const double radiusLg = 20.0;

  /// 24px - Large, dùng cho bottom sheets
  static const double radiusXl = 24.0;

  /// 28px - Extra large, dùng cho featured cards
  static const double radiusXxl = 28.0;

  /// 32px - Rất lớn
  static const double radiusHuge = 32.0;

  /// Full radius - Circle
  static const double radiusFull = 999.0;

  // ========================
  // BORDER RADIUS OBJECTS
  // ========================

  /// Extra extra small radius
  static const BorderRadius radiusXxsAll = BorderRadius.all(
    Radius.circular(radiusXxs),
  );

  /// Extra small radius
  static const BorderRadius radiusXsAll = BorderRadius.all(
    Radius.circular(radiusXs),
  );

  /// Small radius
  static const BorderRadius radiusSmAll = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  /// Medium radius
  static const BorderRadius radiusMdAll = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  /// Large radius
  static const BorderRadius radiusLgAll = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  /// Extra large radius
  static const BorderRadius radiusXlAll = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  /// Extra extra large radius
  static const BorderRadius radiusXxlAll = BorderRadius.all(
    Radius.circular(radiusXxl),
  );

  /// Full radius (circle)
  static const BorderRadius radiusFullAll = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ========================
  // DIRECTIONAL BORDER RADIUS
  // ========================

  /// Top only radius - dùng cho bottom sheets, app bars
  static BorderRadius radiusTopOnly({
    double topLeft = radiusMd,
    double topRight = radiusMd,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
    );
  }

  /// Bottom only radius - dùng cho floating elements
  static BorderRadius radiusBottomOnly({
    double bottomLeft = radiusMd,
    double bottomRight = radiusMd,
  }) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  /// Horizontal only radius (left & right)
  static BorderRadius radiusHorizontalOnly({
    double topLeft = radiusMd,
    double bottomLeft = radiusMd,
    double topRight = radiusMd,
    double bottomRight = radiusMd,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      bottomLeft: Radius.circular(bottomLeft),
      topRight: Radius.circular(topRight),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  // ========================
  // COMMON BORDER RADIUS FOR COMPONENTS
  // ========================

  /// Button radius
  static const BorderRadius buttonRadius = radiusXsAll;

  /// Card radius
  static const BorderRadius cardRadius = radiusLgAll;

  /// Bottom sheet radius
  static const BorderRadius bottomSheetRadius = radiusXlAll;

  /// Dialog radius
  static const BorderRadius dialogRadius = radiusLgAll;

  /// Chip radius
  static const BorderRadius chipRadius = radiusSmAll;

  /// Input field radius
  static const BorderRadius inputRadius = radiusXsAll;

  /// Avatar radius (circle)
  static const BorderRadius avatarRadius = radiusFullAll;

  /// Image radius
  static const BorderRadius imageRadius = radiusMdAll;

  /// Tag/Badge radius
  static const BorderRadius tagRadius = radiusXxsAll;

  /// FAB radius
  static const BorderRadius fabRadius = radiusMdAll;

  // ========================
  // BORDER SIDE
  // ========================

  /// Default border side (1px, color from theme)
  static BorderSide borderSide({Color? color, double width = 1.0}) {
    return BorderSide(
      color: color ?? Colors.grey.shade300,
      width: width,
    );
  }

  /// No border
  static const BorderSide noBorder = BorderSide.none;
}
