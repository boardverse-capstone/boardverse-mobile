import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Card generic dùng trong LobbyConfigPage.
///
/// Hỗ trợ 2 style:
/// - **Mặc định**: `surfaceContainerHigh` cũ, dùng cho các tab đã ổn định.
/// - **Neo-brutalism** ([useNeoStyle = true]): border đậm + hard offset shadow,
///   đồng bộ với design system v4.0. Khuyến nghị dùng cho tab mới hoặc sau
///   khi refactor UI.
class LobbyConfigInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  /// Khi true, áp dụng neo-brutalism: border 3px + hard shadow (5, 5) +
  /// icon badge có nền màu icon (không phải icon màu trên nền nhạt).
  final bool useNeoStyle;

  /// Màu shadow cho neo-brutalism variant. Mặc định dùng [iconColor].
  final Color? neoShadowColor;

  const LobbyConfigInfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
    this.useNeoStyle = false,
    this.neoShadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!useNeoStyle) {
      return _buildLegacyStyle(theme);
    }
    return _buildNeoStyle(context, theme);
  }

  // ── Legacy style (mặc định cũ) ────────────────────────────────────────
  Widget _buildLegacyStyle(ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  // ── Neo-brutalism style (mới) ──────────────────────────────────────────
  Widget _buildNeoStyle(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor =
        neoShadowColor ?? iconColor.withValues(alpha: 0.2);

    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        bold: true,
        borderRadius: 20,
        shadowColor: shadowColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header với icon badge + title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Icon badge — neo style: màu iconColor với text trắng
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: NeoBrutalismTheme.borderWidth,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}