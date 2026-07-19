import 'package:flutter/material.dart';

/// Elevation System - Định nghĩa các giá trị elevation (shadow)
/// Dựa trên Material Design 3 elevation system
class AppElevation {
  AppElevation._();

  // ========================
  // ELEVATION VALUES (numeric)
  // ========================

  /// 0px - Không có shadow (flat design)
  static const double elevationNone = 0.0;

  /// 1px - Shadow nhẹ nhất
  static const double elevationXxs = 1.0;

  /// 2px - Small elevation
  static const double elevationXs = 2.0;

  /// 4px - Default small elevation
  static const double elevationSm = 4.0;

  /// 6px - Medium elevation
  static const double elevationMd = 6.0;

  /// 8px - Large elevation
  static const double elevationLg = 8.0;

  /// 12px - Extra large elevation
  static const double elevationXl = 12.0;

  /// 16px - Very large elevation
  static const double elevationXxl = 16.0;

  /// 24px - Maximum elevation
  static const double elevationMassive = 24.0;

  // ========================
  // LIGHT THEME SHADOWS
  // ========================

  /// No shadow
  static List<BoxShadow> get shadowNone => [];

  /// Extra extra small shadow
  static List<BoxShadow> get shadowXxs => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Extra small shadow
  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Small shadow - Cards, buttons
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium shadow - Floating elements
  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large shadow - Modals, dialogs
  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Extra large shadow - Bottom sheets
  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Extra extra large shadow
  static List<BoxShadow> get shadowXxl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];

  /// Massive shadow - Maximum elevation
  static List<BoxShadow> get shadowMassive => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 48,
      offset: const Offset(0, 24),
    ),
  ];

  // ========================
  // CUSTOM ELEVATION
  // ========================

  /// Tạo custom elevation với các tham số
  static List<BoxShadow> custom({
    double blurRadius = 8,
    double offsetY = 2,
    double opacity = 0.08,
    Color? color,
  }) {
    return [
      BoxShadow(
        color: color ?? Colors.black.withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: Offset(0, offsetY),
      ),
    ];
  }

  /// Tạo elevation với multiple shadows (layered)
  static List<BoxShadow> layered({required double elevation}) {
    if (elevation <= 0) return shadowNone;

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: elevation * 0.5,
        offset: Offset(0, elevation * 0.25),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: elevation,
        offset: Offset(0, elevation * 0.5),
      ),
    ];
  }

  // ========================
  // BRAND-SPECIFIC ELEVATIONS
  // ========================

  /// Card shadow - với border nhẹ
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Card elevated - khi hover/press
  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// FAB shadow
  static List<BoxShadow> get fab => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Bottom navigation shadow
  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];

  /// App bar shadow
  static List<BoxShadow> get appBar => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Dialog shadow
  static List<BoxShadow> get dialog => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  /// Bottom sheet shadow
  static List<BoxShadow> get bottomSheet => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];
}
