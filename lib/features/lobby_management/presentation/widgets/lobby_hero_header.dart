import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/widgets/lobby_countdown_timer.dart';

/// Hero header cho LobbyPage — gradient card với neo-brutalism border + hard shadow
/// hiển thị cafe info, timer, stats và invite code.
class LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;
  final VoidCallback onShareInviteCode;

  const LobbyHeroHeader({
    super.key,
    required this.lobby,
    required this.theme,
    required this.onShareInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Cafe info + Timer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Cafe avatar + info
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(AppIcons.cafe,
                      color: AppColors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.cafeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giờ hẹn: ${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                LobbyCountdownTimer(
                  expiresAt: lobby.timeoutAt,
                  onExpired: () {},
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                HeroStat(
                  label: 'Thành viên',
                  value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                  icon: AppIcons.users,
                  progress: capacityProgress,
                ),
                const SizedBox(width: AppSpacing.sm),
                HeroStat(
                  label: 'Slot trống',
                  value: lobby.slotsRemaining.toString(),
                  icon: AppIcons.userAdd,
                ),
                const SizedBox(width: AppSpacing.sm),
                HeroStat(
                  label: 'Chế độ',
                  value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                  icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                ),
              ],
            ),
          ),

          // Invite code pill
          if (lobby.inviteCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: InviteCodePill(
                code: lobby.inviteCode!,
                onTap: onShareInviteCode,
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat item trong hero header, có thể có progress bar.
class HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? progress;

  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill hiển thị mã mời với icon copy — neo-brutalism style.
class InviteCodePill extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const InviteCodePill({
    super.key,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.userAdd, size: 16, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mã mời',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                AppIcons.copy,
                size: 16,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}