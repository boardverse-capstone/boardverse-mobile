import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Bottom button — confirm action.
class LobbyConfigBottomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const LobbyConfigBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<LobbyConfigBottomButton> createState() =>
      _LobbyConfigBottomButtonState();
}

class _LobbyConfigBottomButtonState extends State<LobbyConfigBottomButton> {
  bool _isDebouncing = false;
  bool _isPressed = false;

  void _handlePress() {
    if (widget.onPressed == null || widget.isLoading || _isDebouncing) return;

    _isDebouncing = true;
    widget.onPressed?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled =
        widget.onPressed != null && !widget.isLoading && !_isDebouncing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTapDown: (_) {
            if (!enabled) return;
            setState(() => _isPressed = true);
            HapticFeedback.mediumImpact();
          },
          onTapUp: (_) {
            if (!enabled) return;
            setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (!enabled) return;
            setState(() => _isPressed = false);
          },
          onTap: enabled ? _handlePress : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.border),
                width: NeoBrutalismTheme.borderWidthBold,
              ),
              boxShadow: !enabled
                  ? null
                  : NeoBrutalismTheme.lightShadow(
                      shadowColor:
                          AppColors.primary.withValues(alpha: 0.5),
                    ),
            ),
            transform: _isPressed
                ? (Matrix4.identity()..translateByDouble(2.0, 2.0, 0.0, 1.0))
                : Matrix4.identity(),
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        color: enabled
                            ? AppColors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
