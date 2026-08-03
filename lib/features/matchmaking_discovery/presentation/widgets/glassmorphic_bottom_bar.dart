import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Sticky bottom CTA bar dùng glassmorphism:
/// - Background blur (BackdropFilter) cho cảm giác "nổi" trên content
/// - Top border 1px + subtle gradient
/// - 1 primary CTA + 1 secondary CTA tuỳ chọn
class GlassmorphicBottomBar extends StatelessWidget {
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final bool isLoading;

  const GlassmorphicBottomBar({
    super.key,
    this.primaryAction,
    this.secondaryAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: (brightness == Brightness.dark
                    ? AppColors.black
                    : AppColors.white)
                .withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                (brightness == Brightness.dark
                        ? AppColors.black
                        : AppColors.white)
                    .withValues(alpha: 0.92),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (secondaryAction != null)
                  Expanded(
                    flex: 2,
                    child: secondaryAction!,
                  ),
                if (secondaryAction != null && primaryAction != null)
                  const SizedBox(width: AppSpacing.sm),
                if (primaryAction != null)
                  Expanded(
                    flex: 3,
                    child: primaryAction!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CTA button "Chơi cùng nhóm" — primary action trên BoardGameDetailPage.
/// Có animation pulse nhẹ khi ở trạng thái idle.
class PrimaryPlayCta extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isLoading;

  const PrimaryPlayCta({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.groups,
    this.isLoading = false,
  });

  @override
  State<PrimaryPlayCta> createState() => _PrimaryPlayCtaState();
}

class _PrimaryPlayCtaState extends State<PrimaryPlayCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusSmAll,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: 0.25 + (_pulseCtrl.value * 0.2),
                ),
                blurRadius: 16 + (_pulseCtrl.value * 8),
                spreadRadius: _pulseCtrl.value * 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: FilledButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: widget.isLoading
            ? const SizedBox(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(widget.icon),
        label: Text(widget.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.radiusSmAll,
          ),
        ),
      ),
    );
  }
}