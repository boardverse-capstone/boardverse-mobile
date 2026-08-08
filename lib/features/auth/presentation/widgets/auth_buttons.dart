import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Auth Button Styles
/// 
/// Features:
/// - Bold borders
/// - Hard offset shadows
/// - Press scale animations
/// - Brand colors
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
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

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: isPressed ? const Offset(2, 2) : Offset.zero,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: AppColors.white),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button cho auth pages - Neo style.
class AuthSecondaryButton extends StatefulWidget {
  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<AuthSecondaryButton> createState() => _AuthSecondaryButtonState();
}

class _AuthSecondaryButtonState extends State<AuthSecondaryButton>
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

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: isPressed ? const Offset(2, 2) : Offset.zero,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.secondary.withValues(alpha: 0.5),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: AppColors.white),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Social login button - Neo style.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: Colors.black.withValues(alpha: 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: AppIcons.md,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
