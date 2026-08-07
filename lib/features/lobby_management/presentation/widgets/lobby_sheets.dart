import 'package:flutter/material.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart';

/// Bottom sheet hiển thị chi tiết lobby.
class LobbyDetailsSheet extends StatelessWidget {
  final LobbyEntity lobby;

  const LobbyDetailsSheet({super.key, required this.lobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final rows = [
      DetailRow(
        icon: AppIcons.boardGame,
        label: 'Game',
        value: lobby.gameName,
      ),
      DetailRow(icon: AppIcons.cafe, label: 'Quán', value: lobby.cafeName),
      DetailRow(
        icon: AppIcons.schedule,
        label: 'Giờ hẹn',
        value:
            '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
      ),
      DetailRow(
        icon: AppIcons.users,
        label: 'Người chơi',
        value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
      ),
      DetailRow(
        icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
        label: 'Chế độ',
        value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
      ),
      if (lobby.inviteCode != null)
        DetailRow(
          icon: AppIcons.copy,
          label: 'Mã mời',
          value: lobby.inviteCode!,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: AppRadius.radiusFullAll,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Chi tiết phòng',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: row,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng chi tiết trong sheet (icon + label + value).
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Icon(icon, size: AppIcons.md, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
