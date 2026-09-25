import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/survey_state.dart';

/// Toggle lớn 2 tab "Cá nhân hóa" / "Khảo sát" trong tab Solo.
///
/// Mỗi nút là 1 tile riêng với icon + label + dot indicator, có
/// neo-brutalism border 2px, hard shadow, và animation khi nhấn.
///
/// Màu:
/// - Cá nhân hóa (AI): tím gradient (#7B2FF7 → #B968F1)
/// - Khảo sát (filter): cam gradient (#FF5722 → #FF8A50)
class SoloModeInnerToggle extends StatelessWidget {
  final SoloMode currentMode;
  final bool isEligible;
  final ValueChanged<SoloMode> onChanged;

  const SoloModeInnerToggle({
    super.key,
    required this.currentMode,
    required this.isEligible,
    required this.onChanged,
  });

  static const Color _personalizationPrimary = Color(0xFF7B2FF7);
  static const Color _personalizationSecondary = Color(0xFFB968F1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Row(
      children: [
        Expanded(
          child: _SoloModeTile(
            label: 'Cá nhân hóa',
            sublabel: 'Dựa trên sở thích của bạn',
            icon: Icons.auto_awesome_rounded,
            gradient: const [_personalizationPrimary, _personalizationSecondary],
            isSelected: currentMode == SoloMode.personalized,
            isEnabled: isEligible,
            isDark: isDark,
            borderColor: borderColor,
            onTap: () => onChanged(SoloMode.personalized),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SoloModeTile(
            label: 'Khảo sát',
            sublabel: 'Chọn theo tiêu chí',
            icon: Icons.tune_rounded,
            gradient: AppColors.cardGradientOrange,
            isSelected: currentMode == SoloMode.survey,
            isEnabled: true,
            isDark: isDark,
            borderColor: borderColor,
            onTap: () => onChanged(SoloMode.survey),
          ),
        ),
      ],
    );
  }
}

class _SoloModeTile extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final List<Color> gradient;
  final bool isSelected;
  final bool isEnabled;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _SoloModeTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.isEnabled,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_SoloModeTile> createState() => _SoloModeTileState();
}

class _SoloModeTileState extends State<_SoloModeTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.isEnabled;

    final inactiveBg = widget.isDark
        ? AppColors.surfaceDark
        : AppColors.surface;

    final accent = widget.gradient.first;

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isSelected ? null : inactiveBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected ? widget.borderColor : accent.withValues(alpha: 0.35),
                width: widget.isSelected
                    ? NeoBrutalismTheme.borderWidthBold
                    : NeoBrutalismTheme.borderWidth,
              ),
              boxShadow: widget.isSelected
                  ? NeoBrutalismTheme.lightShadow(
                      shadowColor: accent.withValues(alpha: 0.45),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isSelected
                          ? Colors.white.withValues(alpha: 0.45)
                          : accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSelected ? Colors.white : accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: widget.isSelected
                              ? Colors.white
                              : (widget.isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                          height: 1.1,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.sublabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : (widget.isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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
