import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_elevation.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Thẻ thống kê compact: label uppercase + giá trị lớn + icon màu nhấn.
///
/// Sử dụng theme tokens (shadow, color, radius) — không hardcode bất kỳ
/// giá trị màu/shadow nào, đảm bảo consistent với Material 3 design system.
/// Có press animation (scale 0.96) để tạo tactile feedback.
class ProfileStatCard extends StatefulWidget {
  const ProfileStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Màu nhấn cho icon + accent text. Mặc định lấy theo
  /// [ColorScheme.primary]. Truyền `null` sẽ dùng primary.
  final Color? accentColor;

  /// Optional tap callback
  final VoidCallback? onTap;

  @override
  State<ProfileStatCard> createState() => _ProfileStatCardState();
}

class _ProfileStatCardState extends State<ProfileStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.accentColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _onTapDown : null,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.radiusLgAll,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: AppElevation.shadowSm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Icon trong ô bo nhỏ — accent nhẹ.
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  widget.icon,
                  color: color,
                  size: AppIcons.md,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
