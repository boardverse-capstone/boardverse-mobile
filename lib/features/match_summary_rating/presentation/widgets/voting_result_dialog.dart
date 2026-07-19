import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../cubit/voting_state.dart';

/// Dialog hiển thị kết quả voting.
class VotingResultDialog extends StatelessWidget {
  final List<VotingCandidate> noShowPlayers;
  final List<VotingCandidate> attendedPlayers;
  final VoidCallback onContinue;

  const VotingResultDialog({
    super.key,
    required this.noShowPlayers,
    required this.attendedPlayers,
    required this.onContinue,
  });

  static Future<void> show({
    required BuildContext context,
    required List<VotingCandidate> noShowPlayers,
    required List<VotingCandidate> attendedPlayers,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VotingResultDialog(
        noShowPlayers: noShowPlayers,
        attendedPlayers: attendedPlayers,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasNoShow = noShowPlayers.isNotEmpty;

    final errorColor = colors.error;
    final successColor = theme.brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;
    final warningColor = theme.brightness == Brightness.dark
        ? AppColorsDark.warning
        : AppColors.warning;

    final accentIconColor = hasNoShow ? warningColor : successColor;
    final accentBgColor = hasNoShow
        ? warningColor.withValues(alpha: 0.16)
        : successColor.withValues(alpha: 0.16);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accentBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasNoShow ? AppIcons.warning : AppIcons.available,
                  size: AppIcons.massive,
                  color: accentIconColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasNoShow ? 'Kết quả bình chọn' : 'Không có người vắng mặt',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasNoShow) ...[
                        _ResultSectionHeader(
                          label: 'Người bị đánh dấu vắng mặt (No-show)',
                          color: errorColor,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...noShowPlayers.map(
                          (player) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: _PlayerTile(
                              candidate: player,
                              color: errorColor.withValues(alpha: 0.12),
                              icon: AppIcons.busy,
                              iconColor: errorColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _ResultSectionHeader(
                        label: 'Người có mặt',
                        color: successColor,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (attendedPlayers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: AppRadius.radiusMdAll,
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Text(
                            'Không có dữ liệu',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ...attendedPlayers.map(
                          (player) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: _PlayerTile(
                              candidate: player,
                              color: successColor.withValues(alpha: 0.12),
                              icon: AppIcons.available,
                              iconColor: successColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: accentBgColor,
                          borderRadius: AppRadius.radiusMdAll,
                          border: Border.all(
                            color: accentIconColor.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasNoShow ? AppIcons.info : AppIcons.check,
                              color: accentIconColor,
                              size: AppIcons.md,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                hasNoShow
                                    ? 'Điểm uy tín (Karma) của người vắng mặt sẽ bị giảm.'
                                    : 'Tất cả thành viên đều có mặt. Cảm ơn!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onContinue();
                  },
                  icon: const Icon(AppIcons.forward),
                  label: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _ResultSectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.radiusFullAll,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final VotingCandidate candidate;
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _PlayerTile({
    required this.candidate,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: iconColor.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            child: Text(
              candidate.name.isEmpty
                  ? '?'
                  : candidate.name.characters.first.toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              candidate.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (candidate.isHost)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.tertiary,
                borderRadius: AppRadius.radiusXxsAll,
              ),
              child: Text(
                'Host',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onTertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          Icon(icon, size: AppIcons.md, color: iconColor),
        ],
      ),
    );
  }
}
