import 'package:flutter/material.dart';

/// Spacing System - 8pt Grid System
/// Mọi spacing phải sử dụng các giá trị trong file này để đảm bảo consistency
class AppSpacing {
  AppSpacing._();

  // ========================
  // SPACING VALUES (8pt grid)
  // ========================

  /// 4px - Spacing nhỏ nhất
  static const double xxs = 4.0;

  /// 8px - Default small spacing
  static const double xs = 8.0;

  /// 12px - Medium-small spacing
  static const double sm = 12.0;

  /// 16px - Default medium spacing
  static const double md = 16.0;

  /// 20px - Medium-large spacing
  static const double lg = 20.0;

  /// 24px - Default large spacing
  static const double xl = 24.0;

  /// 32px - Extra large spacing
  static const double xxl = 32.0;

  /// 40px - Section spacing
  static const double xxxl = 40.0;

  /// 48px - Large section spacing
  static const double huge = 48.0;

  /// 64px - Page section spacing
  static const double massive = 64.0;

  // ========================
  // SCREEN PADDING
  // ========================

  /// Default horizontal padding cho screens
  static const double screenHorizontal = md;

  /// Default vertical padding cho screens
  static const double screenVertical = lg;

  /// Safe area horizontal padding
  static const double safeAreaHorizontal = md;

  /// Safe area vertical padding
  static const double safeAreaVertical = lg;

  // ========================
  // CARD SPACING
  // ========================

  /// Internal card padding
  static const double cardPadding = md;

  /// Card spacing với nhau
  static const double cardGap = md;

  /// Card horizontal gap trong grid
  static const double cardGridGap = sm;

  // ========================
  // LIST SPACING
  // ========================

  /// List item vertical spacing
  static const double listItemVertical = sm;

  /// List item horizontal padding
  static const double listItemHorizontal = md;

  /// Divider height
  static const double dividerHeight = 1.0;

  /// Divider indent (left padding)
  static const double dividerIndent = md;

  // ========================
  // INPUT SPACING
  // ========================

  /// Input field internal padding
  static const double inputPadding = md;

  /// Input label to field gap
  static const double inputLabelGap = xs;

  /// Input error text spacing
  static const double inputErrorGap = xxs;

  /// Between multiple inputs
  static const double inputGap = md;

  // ========================
  // BUTTON SPACING
  // ========================

  /// Button internal horizontal padding
  static const double buttonHorizontal = lg;

  /// Button internal vertical padding
  static const double buttonVertical = md;

  /// Button gap khi có multiple buttons
  static const double buttonGap = sm;

  /// Icon to text gap trong button
  static const double buttonIconGap = xs;

  // ========================
  // NAVIGATION SPACING
  // ========================

  /// Bottom nav bar height
  static const double bottomNavHeight = 80.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Tab bar height
  static const double tabBarHeight = 48.0;

  // ========================
  // GRID
  // ========================

  /// Default cross axis count cho grid
  static const int gridCrossAxisCount = 2;

  /// Grid child aspect ratio (width / height)
  static const double gridChildAspectRatio = 0.75;

  /// Grid spacing
  static const double gridSpacing = md;

  // ========================
  // CONVENIENCE EDGE INSETS
  // ========================

  /// Padding all
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  /// Padding horizontal
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(
    horizontal: xs,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: lg,
  );

  /// Padding vertical
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(
    vertical: xs,
  );
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: lg,
  );

  /// Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Card padding
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: listItemHorizontal,
    vertical: listItemVertical,
  );

  /// Input padding
  static const EdgeInsets inputPaddingAll = EdgeInsets.all(inputPadding);

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: buttonHorizontal,
    vertical: buttonVertical,
  );
}
