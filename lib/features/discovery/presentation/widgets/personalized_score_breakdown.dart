import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Hiển thị score breakdown cho personalized game.
///
/// Format: "BaseScore 70 + Personalization +12 − PlayHistory 0 = 82"
/// Collapsible — mở rộng để xem chi tiết.
class PersonalizedScoreBreakdown extends StatefulWidget {
  final double baseScore;
  final double personalizationBoost;
  final double playHistoryPenalty;
  final double personalizedScore;

  const PersonalizedScoreBreakdown({
    super.key,
    required this.baseScore,
    required this.personalizationBoost,
    required this.playHistoryPenalty,
    required this.personalizedScore,
  });

  @override
  State<PersonalizedScoreBreakdown> createState() =>
      _PersonalizedScoreBreakdownState();
}

class _PersonalizedScoreBreakdownState extends State<PersonalizedScoreBreakdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.8)
              : AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FF7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.personalizedScore.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              _buildRow('Base', widget.baseScore, Colors.grey, isDark),
              _buildRow(
                'Cá nhân hóa',
                widget.personalizationBoost,
                const Color(0xFF7B2FF7),
                isDark,
                prefix: '+',
              ),
              _buildRow(
                'Lịch sử chơi',
                widget.playHistoryPenalty,
                widget.playHistoryPenalty < 0
                    ? AppColors.error
                    : Colors.grey,
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value,
    Color color,
    bool isDark, {
    String prefix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            '${prefix}${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
