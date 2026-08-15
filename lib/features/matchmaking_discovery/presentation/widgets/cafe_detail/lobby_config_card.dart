import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../domain/entities/cafe_detail_entity.dart';

/// Card hiển thị cấu hình lobby của quán (max players theo số ngày đặt
/// trước, max lobbies/user/day, deposit cap, grace period, …).
///
/// Render với điều kiện `cafe.cafeConfig != null`.
class LobbyConfigCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const LobbyConfigCard({super.key, required this.cafe});

  @override
  Widget build(BuildContext context) {
    final cfg = cafe.cafeConfig;
    if (cfg == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 22,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'QUY ĐỊNH LOBBY',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ConfigTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Số lobby tối đa / user / ngày',
            value: '${cfg.maxLobbiesPerUserPerDay}',
          ),
          const SizedBox(height: AppSpacing.xs),
          _SectionLabel(text: 'Số người chơi tối đa theo số ngày đặt trước'),
          const SizedBox(height: AppSpacing.xs),
          _PlayersAheadRow(label: 'Cùng ngày', value: cfg.maxPlayersPerLobbySameDay),
          _PlayersAheadRow(label: 'Trước 1 ngày', value: cfg.maxPlayersPerLobby1Day),
          _PlayersAheadRow(label: 'Trước 2 ngày', value: cfg.maxPlayersPerLobby2Days),
          _PlayersAheadRow(label: 'Trước 3-4 ngày', value: cfg.maxPlayersPerLobby3To4Days),
          _PlayersAheadRow(label: 'Trước 5-7 ngày', value: cfg.maxPlayersPerLobby5To7Days),
          const SizedBox(height: AppSpacing.sm),
          _ConfigTile(
            icon: Icons.gavel_rounded,
            label: 'Yêu cầu duyệt khi đăng ký xa',
            value: cfg.requireApprovalForDistant
                ? 'Có (trước ${cfg.distantThresholdDays}+ ngày, ${cfg.approvalTimeoutHours}h timeout)'
                : 'Không',
          ),
          const SizedBox(height: AppSpacing.xs),
          _ConfigTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Cọc tối đa / user',
            value: '${_formatCurrency(cfg.maxTotalDepositPerUser)} đ',
          ),
          const SizedBox(height: AppSpacing.xs),
          _ConfigTile(
            icon: Icons.timer_outlined,
            label: 'Buffer deadline tuyển thành viên',
            value: '${cfg.recruitmentDeadlineBufferMinutes} phút',
          ),
          const SizedBox(height: AppSpacing.xs),
          _ConfigTile(
            icon: Icons.cancel_outlined,
            label: 'Grace period hủy lobby',
            value: '${cfg.cancellationGraceMinutes} phút',
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(int v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}tr';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k';
    }
    return '$v';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfigTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.secondary,
          ),
        ),
        if (isDark) const SizedBox.shrink(),
      ],
    );
  }
}

class _PlayersAheadRow extends StatelessWidget {
  final String label;
  final int value;

  const _PlayersAheadRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value người',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}