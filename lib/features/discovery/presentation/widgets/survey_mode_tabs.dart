import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism segmented tabs Solo / Nhóm cho SurveyPage.
///
/// Mỗi tab là một "tile" nổi bật với border 3px + hard shadow.
/// Tab đang chọn sẽ có background đặc (cam/teal), shadow bằng 0 → pressed-in feel.
class SurveyModeTabs extends StatelessWidget {
  final int selectedIndex; // 0=Solo, 1=Nhóm
  final ValueChanged<int> onChanged;

  const SurveyModeTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NeoTab(
              label: 'Cá nhân',
              icon: Icons.person_rounded,
              accentColor: AppColors.primary,
              isSelected: selectedIndex == 0,
              isDark: isDark,
              borderColor: borderColor,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _NeoTab(
              label: 'Nhóm',
              icon: Icons.groups_rounded,
              accentColor: AppColors.secondary,
              isSelected: selectedIndex == 1,
              isDark: isDark,
              borderColor: borderColor,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeoTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _NeoTab({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_NeoTab> createState() => _NeoTabState();
}

class _NeoTabState extends State<_NeoTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentColor
        : (widget.isDark ? AppColors.surfaceDark : AppColors.surface);

    final fgColor = widget.isSelected
        ? AppColors.white
        : (widget.isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimary);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? widget.borderColor
                  : widget.borderColor.withValues(alpha: 0.6),
              width: widget.isSelected
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isSelected
                ? null
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: widget.accentColor.withValues(alpha: 0.25),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        widget.isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: fgColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
