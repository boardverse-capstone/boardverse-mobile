import 'package:flutter/material.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';

/// Neo-brutalism bottom sheet hiển thị chi tiết lobby.
class LobbyDetailsSheet extends StatelessWidget {
  final LobbyEntity lobby;

  const LobbyDetailsSheet({super.key, required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
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
                    child: const Icon(
                      AppIcons.info,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Chi tiết phòng',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                children: [
                  // ── Tổng quan ────────────────────────────────────────────
                  _NeoSectionHeader(title: 'TỔNG QUAN'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.boardGame,
                          label: 'GAME',
                          value: lobby.gameName,
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.cafe,
                          label: 'QUÁN',
                          value: lobby.cafeName.isEmpty
                              ? '—'
                              : lobby.cafeName,
                          accent: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoDetailCard(
                          icon: lobby.isPublic
                              ? AppIcons.globe
                              : AppIcons.lock,
                          label: 'CHẾ ĐỘ',
                          value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                          accent: AppColors.info,
                        ),
                      ),
                      if (lobby.inviteCode != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _NeoDetailCard(
                            icon: AppIcons.copy,
                            label: 'MÃ MỜI',
                            value: lobby.inviteCode!,
                            accent: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Lịch trình ───────────────────────────────────────────
                  _NeoSectionHeader(title: 'LỊCH TRÌNH'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.schedule,
                          label: 'GIỜ HẸN',
                          value:
                              '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
                          accent: AppColors.accent,
                        ),
                      ),
                      if (lobby.cancellationLeadTimeMinutes != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _NeoDetailCard(
                            icon: AppIcons.timer,
                            label: 'LEAD-TIME',
                            value:
                                '${lobby.cancellationLeadTimeMinutes} phút',
                            accent: AppColors.info,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Thành viên ─────────────────────────────────────────
                  _NeoSectionHeader(title: 'THÀNH VIÊN'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.users,
                          label: 'HIỆN TẠI / TỐI ĐA',
                          value:
                              '${lobby.currentPlayers} / ${lobby.maxPlayers} người',
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.userCheck,
                          label: 'TỐI THIỂU',
                          value: '${lobby.minPlayers} người',
                          accent: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.userAdd,
                          label: 'SLOT TRỐNG',
                          value: '${lobby.slotsRemaining} vị trí',
                          accent: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NeoDetailCard(
                          icon: AppIcons.karma,
                          label: 'KARMA TỐI THIỂU',
                          value: lobby.minimumKarma > 0
                              ? '${lobby.minimumKarma.toInt()}+'
                              : 'Không',
                          accent: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neo-brutalism section header.
class _NeoSectionHeader extends StatelessWidget {
  final String title;

  const _NeoSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

/// Neo-brutalism detail card (single tile).
class _NeoDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _NeoDetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 14, color: AppColors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}