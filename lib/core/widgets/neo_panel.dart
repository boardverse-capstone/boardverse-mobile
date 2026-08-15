import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/neo_brutalism_theme.dart';

/// Neo-brutalism panel — bordered card with hard offset shadow và accent
/// stripe phía trên. Dùng làm container cho các section/card có nhấn
/// mạnh (waitlist, spectator, status, error…).
///
/// Đặc trưng:
/// - Border 2.5px đậm, không blur shadow (offset 3,3).
/// - Màu nhấn [accentColor] làm viền và accent stripe nhỏ phía trên
///   giúp panel có "chủ đề" màu rõ ràng.
/// - Nội dung đặt trong padding `AppSpacing.md` theo design system.
class NeoPanel extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const NeoPanel({
    super.key,
    required this.child,
    this.accentColor = AppColors.primary,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? NeoBrutalismTheme.surfaceDark
        : NeoBrutalismTheme.surfaceLight;
    final borderColor =
        isDark ? NeoBrutalismTheme.borderDark : accentColor;

    final container = Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: borderColor.withValues(alpha: 0.35),
        ),
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          // Accent stripe nhỏ ở góc trên-trái.
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 28,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMdAll,
        child: container,
      ),
    );
  }
}

/// Badge icon vuông bo nhẹ, viền đậm — dùng đầu mỗi NeoPanel làm
/// "icon marker" giúp panel nhận diện nhanh theo loại (info / warning /
/// success / error).
class NeoIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const NeoIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Icon(icon, color: AppColors.white, size: size * 0.55),
    );
  }
}

/// Pill nhỏ — label ngắn kèm màu, thường đặt ở header card để show
/// trạng thái (VD: "Đang chờ", "Đã mời", "Chưa theo dõi").
class NeoStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const NeoStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusFullAll,
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Button neo-brutalism custom màu (thay vì chỉ primary/secondary).
/// Dùng cho các CTA cần tone riêng (info, success, warning).
class NeoPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color textColor;
  final bool loading;
  final VoidCallback? onPressed;

  const NeoPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.background,
    this.textColor = AppColors.white,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: AppRadius.radiusMdAll,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? background.withValues(alpha: 0.55)
                : background,
            border: Border.all(color: AppColors.black, width: 2),
            borderRadius: AppRadius.radiusMdAll,
            boxShadow: disabled
                ? null
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: background.withValues(alpha: 0.4),
                  ),
          ),
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: textColor),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}