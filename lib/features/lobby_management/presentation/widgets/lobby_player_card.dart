import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';

class LobbyPlayerCard extends StatelessWidget {
  final LobbyPlayer player;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LobbyPlayerCard({
    super.key,
    required this.player,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = theme.brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;
    final statusColor = player.isReady ? successColor : colors.outline;
    final statusLabel = player.isHost
        ? 'Chủ phòng'
        : player.isReady
        ? 'Sẵn sàng'
        : 'Đang chờ';

    return Semantics(
      button: onTap != null,
      label: '${player.name}, $statusLabel',
      child: Material(
        color: isCurrentUser
            ? colors.primaryContainer
            : colors.surfaceContainerHighest.withValues(alpha: 0.58),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(
            color: isCurrentUser
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.72),
            width: isCurrentUser ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PlayerAvatar(player: player),
                    Positioned(
                      right: -AppSpacing.xxs,
                      bottom: -AppSpacing.xxs,
                      child: Container(
                        width: AppSpacing.lg,
                        height: AppSpacing.lg,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                        child: player.isReady
                            ? Icon(
                                AppIcons.check,
                                size: AppIcons.xs,
                                color: colors.surface,
                              )
                            : null,
                      ),
                    ),
                    if (player.isHost)
                      Positioned(
                        left: -AppSpacing.xxs,
                        top: -AppSpacing.xxs,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: colors.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: Icon(
                            AppIcons.starFilled,
                            size: AppIcons.xs,
                            color: colors.onTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? colors.onPrimaryContainer : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: (player.isHost ? colors.tertiary : statusColor)
                        .withValues(alpha: 0.13),
                    borderRadius: AppRadius.radiusFullAll,
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: player.isHost
                          ? colors.onTertiaryContainer
                          : statusColor,
                      fontWeight: FontWeight.w700,
                    ),
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

class _PlayerAvatar extends StatelessWidget {
  final LobbyPlayer player;

  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();

    return CircleAvatar(
      radius: AppSpacing.xxl,
      backgroundColor: colors.secondaryContainer,
      foregroundColor: colors.onSecondaryContainer,
      backgroundImage: hasAvatar ? NetworkImage(player.avatarUrl) : null,
      onBackgroundImageError: hasAvatar ? (_, _) {} : null,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class LobbyPlayerGrid extends StatelessWidget {
  final List<LobbyPlayer> players;
  final int maxSlots;
  final String? currentUserId;
  final Function(LobbyPlayer)? onPlayerTap;

  const LobbyPlayerGrid({
    super.key,
    required this.players,
    required this.maxSlots,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = (maxSlots - players.length).clamp(0, maxSlots);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 720 ? 172.0 : 148.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            childAspectRatio: 0.78,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: players.length + emptySlots,
          itemBuilder: (context, index) {
            if (index < players.length) {
              final player = players[index];
              return LobbyPlayerCard(
                player: player,
                isCurrentUser: player.id == currentUserId,
                onTap: onPlayerTap == null
                    ? null
                    : () => onPlayerTap?.call(player),
              );
            }
            return const _EmptySlot();
          },
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      label: 'Vị trí đang trống',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.26),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.userAdd,
                  size: AppIcons.lg,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đang trống',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
