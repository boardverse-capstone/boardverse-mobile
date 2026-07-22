import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/match_result_entity.dart';

/// Widget chọn kết quả trận đấu (Win/Loss/Draw).
class OutcomeSelector extends StatelessWidget {
  final MatchOutcome? selectedOutcome;
  final ValueChanged<MatchOutcome> onSelected;
  final bool isDisabled;

  const OutcomeSelector({
    super.key,
    this.selectedOutcome,
    required this.onSelected,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final outcome in MatchOutcome.values) ...[
          if (outcome != MatchOutcome.values.first) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OutcomeButton(
              outcome: outcome,
              isSelected: selectedOutcome == outcome,
              onTap: isDisabled ? null : () => onSelected(outcome),
            ),
          ),
        ],
      ],
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final MatchOutcome outcome;
  final bool isSelected;
  final VoidCallback? onTap;

  const _OutcomeButton({
    required this.outcome,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (backgroundColor, foregroundColor, icon) = switch (outcome) {
      MatchOutcome.win => (AppColors.success, Colors.white, Icons.emoji_events),
      MatchOutcome.loss => (AppColors.error, Colors.white, Icons.sentiment_dissatisfied),
      MatchOutcome.draw => (AppColors.info, Colors.white, Icons.handshake),
    };

    return Material(
      color: isSelected ? backgroundColor : backgroundColor.withValues(alpha: 0.1),
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: backgroundColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppRadius.radiusMdAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIcons.xl,
                color: isSelected ? foregroundColor : backgroundColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                outcome.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? foregroundColor : backgroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
