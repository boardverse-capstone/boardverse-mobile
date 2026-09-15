import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Bottom action bar dùng cho tất cả các tab trong
/// LobbyConfigPage.
///
/// Hỗ trợ 2 layout:
/// - **Single button** (mặc định, [secondaryLabel] = null): 1 nút full-width.
///   Dùng cho tab 1 (Quán & Game) — không cần "Quay lại" vì đây là
///   bước đầu tiên.
/// - **Dual button** ([secondaryLabel] != null): 2 nút cạnh nhau,
///   [secondary] (outline, "Quay lại") + [primary] (filled, "Tiếp tục").
///   Dùng cho các tab 2-4 để user chủ động quay lại bước trước thay vì
///   bấm nhầm nút back ở AppBar (gây pop cả page, mất toàn bộ tiến
///   trình đã điền).
///
/// Style: Neo-brutalism — border đậm, hard offset shadow (no blur),
/// press animation (translate 2px khi nhấn), haptic feedback.
class LobbyConfigBottomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Nhãn cho nút phụ (bên trái). Khi null, render single full-width button.
  final String? secondaryLabel;

  /// Callback cho nút phụ. Khi null mà [secondaryLabel] được set, nút phụ
  /// vẫn hiển thị nhưng disabled.
  final VoidCallback? secondaryOnPressed;

  const LobbyConfigBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.secondaryOnPressed,
  });

  @override
  State<LobbyConfigBottomButton> createState() =>
      _LobbyConfigBottomButtonState();
}

class _LobbyConfigBottomButtonState extends State<LobbyConfigBottomButton> {
  bool _isDebouncing = false;

  void _handlePress(VoidCallback? callback) {
    if (callback == null || widget.isLoading || _isDebouncing) return;

    _isDebouncing = true;
    callback();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSecondary = widget.secondaryLabel != null;

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
        child: hasSecondary
            ? Row(
                children: [
                  // Nút phụ (Quay lại) — outline, chiếm ~40% width.
                  Expanded(
                    flex: 4,
                    child: _OutlineNeoButton(
                      label: widget.secondaryLabel!,
                      enabled: widget.secondaryOnPressed != null &&
                          !widget.isLoading &&
                          !_isDebouncing,
                      onPressed: () =>
                          _handlePress(widget.secondaryOnPressed),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Nút chính — filled primary, chiếm ~60% width.
                  Expanded(
                    flex: 6,
                    child: _PrimaryNeoButton(
                      label: widget.label,
                      enabled: widget.onPressed != null &&
                          !widget.isLoading &&
                          !_isDebouncing,
                      isLoading: widget.isLoading,
                      onPressed: () => _handlePress(widget.onPressed),
                    ),
                  ),
                ],
              )
            : _PrimaryNeoButton(
                label: widget.label,
                enabled: widget.onPressed != null &&
                    !widget.isLoading &&
                    !_isDebouncing,
                isLoading: widget.isLoading,
                onPressed: () => _handlePress(widget.onPressed),
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// INTERNAL BUTTONS
// ══════════════════════════════════════════════════════════════════════════

/// Nút filled primary theo neo-brutalism:
/// - Nền `AppColors.primary` (cam) khi enabled, surface variant khi disabled.
/// - Border đậm 3px, hard offset shadow (no blur), press animation
///   translate (2, 2), haptic feedback.
class _PrimaryNeoButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryNeoButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_PrimaryNeoButton> createState() => _PrimaryNeoButtonState();
}

class _PrimaryNeoButtonState extends State<_PrimaryNeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: widget.enabled
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.enabled
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: NeoBrutalismTheme.borderWidthBold,
          ),
          boxShadow: !widget.enabled
              ? null
              : NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bọc Text trong Flexible để nút không overflow khi
                    // label quá dài (vd "Xác nhận & đặt cọc" + icon chiếm
                    // hơn width parent ~183px). maxLines + ellipsis đảm
                    // bảo text tự rút gọn khi cần mà không vỡ layout.
                    Flexible(
                      child: Text(
                        widget.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: widget.enabled
                              ? AppColors.white
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: widget.enabled
                          ? AppColors.white
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Nút outline theo neo-brutalism:
/// - Nền trắng / surface (light/dark) khi enabled.
/// - Border đậm 3px màu [borderColor] (mặc định `AppColors.border`),
///   hard offset shadow (no blur).
/// - Dùng cho "Quay lại" — secondary action không phải CTA chính.
class _OutlineNeoButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _OutlineNeoButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_OutlineNeoButton> createState() => _OutlineNeoButtonState();
}

class _OutlineNeoButtonState extends State<_OutlineNeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.border;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (!widget.enabled) return;
        setState(() => _isPressed = false);
      },
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: widget.enabled
              ? (isDark ? AppColors.surfaceDark : AppColors.white)
              : (isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
          boxShadow: !widget.enabled
              ? null
              : NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.black.withValues(alpha: 0.35),
                ),
        ),
        transform: _isPressed
            ? (Matrix4.identity()..translateByDouble(2.0, 2.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: widget.enabled
                    ? (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Bọc Text trong Flexible để tránh overflow khi label dài,
              // giữ icon luôn hiển thị đầy đủ ở cuối row.
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: widget.enabled
                        ? (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
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