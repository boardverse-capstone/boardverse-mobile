import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/neo_brutalism_theme.dart';
import '../theme/app_spacing.dart';

/// Neo-brutalism Button Styles
/// 
/// Features:
/// - Bold borders (2-3px)
/// - Hard offset shadows
/// - Press scale animations
/// - Brand colors
class NeoButtons {
  NeoButtons._();

  /// Primary Button - Full width
  static Widget primary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: AppColors.primary,
      textColor: AppColors.white,
      shadowColor: AppColors.primary,
    );
  }

  /// Secondary Button - With border
  static Widget secondary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: AppColors.secondary,
      textColor: AppColors.white,
      shadowColor: AppColors.secondary,
    );
  }

  /// Accent Button - Yellow/Amber
  static Widget accent({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: AppColors.accent,
      textColor: AppColors.black,
      shadowColor: AppColors.accent,
    );
  }

  /// Outlined Button
  static Widget outlined({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    Color? borderColor,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: Colors.transparent,
      textColor: borderColor ?? AppColors.primary,
      borderColor: borderColor ?? AppColors.primary,
      shadowColor: borderColor ?? AppColors.primary,
    );
  }

  /// Error/Danger Button
  static Widget error({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      shadowColor: AppColors.error,
    );
  }

  /// Success Button
  static Widget success({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return _NeoButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
      shadowColor: AppColors.success,
    );
  }
}

/// Internal Neo-brutalist button implementation
class _NeoButton extends StatefulWidget {
  const _NeoButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.shadowColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color shadowColor;

  @override
  State<_NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<_NeoButton>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;
    final isOutlined = widget.backgroundColor == Colors.transparent;

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
          width: widget.fullWidth ? double.infinity : null,
          height: 52,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.borderColor ?? (isDark ? AppColors.borderDark : AppColors.border),
              width: isOutlined ? 2 : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: isOutlined
                ? null
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: widget.shadowColor.withValues(alpha: 0.4),
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(widget.textColor),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.textColor,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: widget.textColor,
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

/// Icon-only Neo button (circular)
class NeoIconButton extends StatefulWidget {
  const NeoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  @override
  State<NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<NeoIconButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? AppColors.primary;
    final iconColor = widget.color ?? AppColors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: bgColor.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            widget.icon,
            color: iconColor,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}
