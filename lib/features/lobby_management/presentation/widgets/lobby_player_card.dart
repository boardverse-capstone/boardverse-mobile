import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';

/// Modern lobby player card với gradient accent, badge indicators, và
/// press animation. Sử dụng board game style với glass-morphism hint.
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
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: isCurrentUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary.withValues(alpha: 0.15),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: isCurrentUser
                  ? null
                  : colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.radiusLgAll,
              border: Border.all(
                color: isCurrentUser
                    ? colors.primary.withValues(alpha: 0.6)
                    : colors.outlineVariant.withValues(alpha: 0.5),
                width: isCurrentUser ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCurrentUser ? colors.primary : colors.primary)
                      .withValues(alpha: isCurrentUser ? 0.08 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar + badges stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PlayerAvatar(player: player, isCurrentUser: isCurrentUser),
                    // Ready badge
                    Positioned(
                      right: -AppSpacing.xxs,
                      bottom: -AppSpacing.xxs,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: player.isReady
                            ? const Icon(AppIcons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                    // Host badge
                    if (player.isHost)
                      Positioned(
                        left: -AppSpacing.xxs,
                        top: -AppSpacing.xxs,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.tertiary, colors.tertiary.withAlpha(204)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: colors.tertiary.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(AppIcons.starFilled, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Name
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCurrentUser ? colors.primary : colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (player.isHost ? colors.tertiary : statusColor).withValues(alpha: 0.15),
                        (player.isHost ? colors.tertiary : statusColor).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: AppRadius.radiusFullAll,
                    border: Border.all(
                      color: (player.isHost ? colors.tertiary : statusColor)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: player.isHost
                          ? colors.tertiary
                          : statusColor,
                      fontWeight: FontWeight.w800,
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
  final bool isCurrentUser;

  const _PlayerAvatar({required this.player, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();
    final avatarColor = isCurrentUser
        ? colors.primaryContainer
        : colors.secondaryContainer;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                player.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.onSecondaryContainer,
                        ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSecondaryContainer,
                    ),
              ),
            ),
    );
  }
}

/// Modern grid hiển thị players + empty slots.
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
        final maxExtent = constraints.maxWidth >= 720 ? 172.0 : 152.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
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
            return const _EmptySlotCard();
          },
        );
      },
    );
  }
}

/// Empty slot với gradient accent để thu hút attention.
class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      label: 'Vị trí đang trống',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceContainerHighest.withValues(alpha: 0.3),
              colors.surfaceContainerHighest.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.1),
                      colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  AppIcons.userAdd,
                  size: AppIcons.lg,
                  color: colors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đang trống',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mời bạn bè',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
