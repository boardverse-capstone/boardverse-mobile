import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../cubit/voting_state.dart';

/// Neo-brutalism dialog hiển thị kết quả voting.
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
    final hasNoShow = noShowPlayers.isNotEmpty;

    final accentIconColor =
        hasNoShow ? AppColors.warning : AppColors.success;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.border,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: accentIconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 3),
                  ),
                  child: Icon(
                    hasNoShow ? AppIcons.warning : AppIcons.available,
                    size: 32,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    hasNoShow
                        ? 'Kết quả bình chọn'
                        : 'Không có người vắng mặt',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasNoShow) ...[
                      _ResultSectionHeader(
                        label: 'Người bị đánh dấu vắng mặt (No-show)',
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...noShowPlayers.map(
                        (player) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _PlayerTile(
                            candidate: player,
                            bgColor: AppColors.error,
                            icon: AppIcons.busy,
                            iconColor: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _ResultSectionHeader(
                      label: 'Người có mặt',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (attendedPlayers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Không có dữ liệu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...attendedPlayers.map(
                        (player) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _PlayerTile(
                            candidate: player,
                            bgColor: AppColors.success,
                            icon: AppIcons.available,
                            iconColor: AppColors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: accentIconColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border,
                          width: 2.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasNoShow ? AppIcons.info : AppIcons.check,
                            color: AppColors.black,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              hasNoShow
                                  ? 'Điểm uy tín (Karma) của người vắng mặt sẽ bị giảm.'
                                  : 'Tất cả thành viên đều có mặt. Cảm ơn!',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: AppColors.black,
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
            _NeoFilledButton(
              label: 'Tiếp tục',
              icon: AppIcons.forward,
              color: AppColors.primary,
              onPressed: () {
                Navigator.pop(context);
                onContinue();
              },
            ),
          ],
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
    return Row(
      children: [
        Container(
          width: 8,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final VotingCandidate candidate;
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _PlayerTile({
    required this.candidate,
    required this.bgColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Center(
              child: Text(
                candidate.name.isEmpty
                    ? '?'
                    : candidate.name.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              candidate.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.white,
              ),
            ),
          ),
          if (candidate.isHost)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: const Text(
                'HOST',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism filled button.
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}