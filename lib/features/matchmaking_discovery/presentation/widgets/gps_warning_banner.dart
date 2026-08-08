import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism GPS warning banner.
class GpsWarningBanner extends StatelessWidget {
  final VoidCallback? onEnableGps;
  final VoidCallback? onEnterManually;

  const GpsWarningBanner({
    super.key,
    this.onEnableGps,
    this.onEnterManually,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: AppSpacing.paddingAllMd,
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_off,
                  color: AppColors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'GPS đang tắt',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.warningDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bật GPS để xem các quán cafe gần bạn hoặc nhập vị trí thủ công.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _NeoButtonInline(
                  label: 'Bật GPS',
                  icon: Icons.gps_fixed,
                  backgroundColor: AppColors.warning,
                  textColor: AppColors.black,
                  onPressed: onEnableGps,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NeoButtonInline(
                  label: 'Nhập tay',
                  icon: Icons.edit_location_alt,
                  backgroundColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  textColor: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  borderColor: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  onPressed: onEnterManually,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeoButtonInline extends StatefulWidget {
  const _NeoButtonInline({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  State<_NeoButtonInline> createState() => _NeoButtonInlineState();
}

class _NeoButtonInlineState extends State<_NeoButtonInline>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed == null
          ? null
          : () {
              _pressCtrl.forward();
              HapticFeedback.mediumImpact();
              Future.delayed(const Duration(milliseconds: 80), () {
                if (mounted) _pressCtrl.reverse();
                widget.onPressed?.call();
              });
            },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.borderColor ?? widget.backgroundColor,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: widget.backgroundColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: widget.textColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
