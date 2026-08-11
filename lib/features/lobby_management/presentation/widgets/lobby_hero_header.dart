import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart';

/// Hero header cho LobbyPage — layout mới (2026-08):
///
/// - Cafe info (avatar + tên + địa điểm) ở hàng trên cùng
/// - Tiêu đề game nổi bật + nút "Xem chi tiết" ở góc phải
/// - 3 stat card (Thành viên / Chế độ / Mã mời) ở dưới
///
/// Style neo-brutalism với border đậm + hard shadow nhưng **ít chen chúc**
/// hơn bản cũ (bỏ countdown `LobbyCountdownTimer` ở header → chuyển vào
/// status strip nếu cần sau).
class LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  /// Callback khi user bấm nút "Xem chi tiết" (icon info ở góc phải).
  /// Trước đây là IconButton nhỏ trên AppBar → giờ chuyển vào đây cho
  /// dễ thấy hơn.
  final VoidCallback onShowDetails;

  /// Callback khi user bấm copy share code.
  final VoidCallback onShareInviteCode;

  const LobbyHeroHeader({
    super.key,
    required this.lobby,
    required this.theme,
    required this.onShowDetails,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Cafe info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
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
                  child: const Icon(
                    AppIcons.cafe,
                    color: AppColors.white,
                    size: 24,
                  ),
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
                // Nút "Xem chi tiết" — thay cho icon nhỏ trên AppBar.
                _HeroIconButton(
                  icon: AppIcons.info,
                  tooltip: 'Xem chi tiết',
                  onTap: onShowDetails,
                ),
              ],
            ),
          ),

          // ── Row 2: Game title (nổi bật) ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Text(
              lobby.gameName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ),

          // ── Row 3: 3 stat cards (Thành viên / Chế độ / Mã mời) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: HeroStat(
                    label: 'Thành viên',
                    value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                    icon: AppIcons.users,
                    progress: capacityProgress,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: HeroStat(
                    label: 'Chế độ',
                    value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                    icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: lobby.inviteCode != null
                      ? InviteCodeStat(
                          code: lobby.inviteCode!,
                          onTap: onShareInviteCode,
                        )
                      : HeroStat(
                          label: 'Slot trống',
                          value: lobby.slotsRemaining.toString(),
                          icon: AppIcons.userAdd,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút icon tròn trong hero header (neo-brutalism mini).
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: AppColors.white),
          ),
        ),
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
    return Container(
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
                  AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat card hiển thị mã mời — có thể bấm copy.
class InviteCodeStat extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const InviteCodeStat({
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
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.copy,
                    size: 14,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mã mời',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
