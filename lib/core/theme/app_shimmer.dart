import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_radius.dart';
import 'app_spacing.dart';

/// Shimmer System - Skeleton loading animations
/// Dùng để hiển thị trạng thái loading đẹp mắt
class AppShimmer {
  AppShimmer._();

  // ========================
  // SHIMMER COLORS - LIGHT
  // ========================

  /// Base color cho light mode
  static const Color _lightBaseColor = Color(0xFFE0E0E0);

  /// Highlight color cho light mode
  static const Color _lightHighlightColor = Color(0xFFF5F5F5);

  // ========================
  // SHIMMER COLORS - DARK
  // ========================

  /// Base color cho dark mode
  static const Color _darkBaseColor = Color(0xFF2C2C2C);

  /// Highlight color cho dark mode
  static const Color _darkHighlightColor = Color(0xFF3D3D3D);

  // ========================
  // HELPER METHODS
  // ========================

  /// Lấy base color theo theme
  static Color _getBaseColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkBaseColor
        : _lightBaseColor;
  }

  /// Lấy highlight color theo theme
  static Color _getHighlightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkHighlightColor
        : _lightHighlightColor;
  }

  // ========================
  // BASE SHIMMER WIDGET
  // ========================

  /// Wrap một widget với shimmer effect
  static Widget shimmer({
    required BuildContext context,
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return Shimmer.fromColors(
      baseColor: _getBaseColor(context),
      highlightColor: _getHighlightColor(context),
      period: duration,
      child: child,
    );
  }

  // ========================
  // SHIMMER BOX
  // ========================

  /// Shimmer box - placeholder dạng hộp
  static Widget box({
    required BuildContext context,
    double width = double.infinity,
    required double height,
    double borderRadius = 8.0,
  }) {
    return shimmer(
      context: context,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Shimmer box với custom border radius từ AppRadius
  static Widget boxRadius({
    required BuildContext context,
    double width = double.infinity,
    required double height,
    BorderRadius borderRadius = AppRadius.radiusXsAll,
  }) {
    return shimmer(
      context: context,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  // ========================
  // SHIMMER CARD
  // ========================

  /// Shimmer card placeholder - dùng cho game card
  static Widget card({
    required BuildContext context,
    double aspectRatio = 4 / 3,
  }) {
    return shimmer(
      context: context,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.radiusLg),
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.cardPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.radiusXxsAll,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Subtitle placeholder
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.radiusXxsAll,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================
  // SHIMMER LIST ITEM
  // ========================

  /// Shimmer list item placeholder
  static Widget listItem({
    required BuildContext context,
    double avatarSize = 56,
    double borderRadius = 12.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.radiusXxsAll,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.radiusXxsAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================
  // SHIMMER TEXT LINES
  // ========================

  /// Shimmer text lines placeholder
  static Widget textLines({
    required BuildContext context,
    int lines = 3,
    double lineHeight = 14,
    double spacing = 8,
    double? lastLineWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLastLine ? 0 : spacing,
          ),
          child: Container(
            width: isLastLine ? (lastLineWidth ?? 100) : double.infinity,
            height: lineHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusXxsAll,
            ),
          ),
        );
      }),
    );
  }

  // ========================
  // SHIMMER CIRCLE
  // ========================

  /// Shimmer circle - dùng cho avatar placeholder
  static Widget circle({
    required BuildContext context,
    double size = 48,
  }) {
    return shimmer(
      context: context,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ========================
  // SHIMMER GRID
  // ========================

  /// Shimmer grid placeholder
  static Widget grid({
    required BuildContext context,
    required int itemCount,
    int crossAxisCount = 2,
    double spacing = AppSpacing.md,
    double childAspectRatio = 0.75,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => card(context: context),
    );
  }

  // ========================
  // SHIMMER CONTAINER
  // ========================

  /// Wrap bất kỳ container nào với shimmer
  static Widget container({
    required BuildContext context,
    required Widget child,
    BorderRadius? borderRadius,
  }) {
    return shimmer(
      context: context,
      child: ClipRRect(
        borderRadius: borderRadius ?? AppRadius.radiusXsAll,
        child: child,
      ),
    );
  }
}
