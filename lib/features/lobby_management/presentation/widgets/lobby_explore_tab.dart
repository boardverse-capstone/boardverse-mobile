import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';

/// Modern lobby explore tab với gradient cards và elevated design.
class LobbyExploreTab extends StatelessWidget {
  final LobbySearchCubit searchCubit;
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onPreview;
  final void Function(String, String?) onJoin;
  final VoidCallback onCreateLobby;

  const LobbyExploreTab({
    super.key,
    required this.searchCubit,
    required this.timeFormatter,
    required this.onPreview,
    required this.onJoin,
    required this.onCreateLobby,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbySearchCubit, LobbyState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is LobbyListLoading) return const _LoadingView();
        if (state is LobbyFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        if (state is LobbyListEmpty || (state is LobbyListLoaded && state.entities.isEmpty)) {
          return _EmptyExploreView(onCreateLobby: onCreateLobby);
        }
        if (state is LobbyListLoaded) {
          return _LobbyList(
            lobbies: state.entities,
            timeFormatter: timeFormatter,
            onPreview: onPreview,
            onJoin: onJoin,
            onRefresh: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đang tải phòng chờ...',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: colors.onErrorContainer),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            _GradientRetryButton(onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyExploreView extends StatelessWidget {
  final VoidCallback onCreateLobby;

  const _EmptyExploreView({required this.onCreateLobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.1),
                    colors.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.meeting_room_outlined, size: 64, color: colors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có phòng chờ nào',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy là người đầu tiên tạo phòng để mọi người cùng tham gia!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            _GradientRetryButton(
              onTap: onCreateLobby,
              label: 'Tạo phòng',
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyList extends StatelessWidget {
  final List<LobbyEntity> lobbies;
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onPreview;
  final void Function(String, String?) onJoin;
  final Future<void> Function() onRefresh;

  const _LobbyList({
    required this.lobbies,
    required this.timeFormatter,
    required this.onPreview,
    required this.onJoin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
        itemCount: lobbies.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      borderRadius: AppRadius.radiusFullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${lobbies.length} phòng đang hoạt động',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final lobby = lobbies[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LobbyExploreCard(
              lobby: lobby,
              timeFormatter: timeFormatter,
              onTap: () => onPreview(lobby),
              onJoin: () => onJoin(lobby.id, lobby.inviteCode),
            ),
          );
        },
      ),
    );
  }
}

/// Modern lobby card với gradient game thumbnail và elevated design.
class _LobbyExploreCard extends StatelessWidget {
  final LobbyEntity lobby;
  final DateFormat timeFormatter;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _LobbyExploreCard({
    required this.lobby,
    required this.timeFormatter,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final capacity = '${lobby.currentPlayers}/${lobby.maxPlayers}';
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: AppElevation.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusLgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              // ── Gradient thumbnail + game info header ──────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primary.withAlpha(179),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Game initial avatar
                    _GameAvatar(lobby: lobby, theme: theme, colors: colors),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lobby.gameName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.store_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lobby.cafeName.isNotEmpty ? lobby.cafeName : 'Chưa chọn quán',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _CapacityBadge(capacity: capacity, isFull: isFull, colors: colors),
                  ],
                ),
              ),

              // ── Footer: time + host + join ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Time + host info
                    Expanded(
                      child: Row(
                        children: [
                          _InfoChip(
                            icon: Icons.access_time,
                            label: timeFormatter.format(lobby.scheduledTime),
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _InfoChip(
                            icon: Icons.person_outline,
                            label: lobby.hostName,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Join button
                    SizedBox(
                      width: 88,
                      child: _JoinButton(
                        isFull: isFull,
                        onTap: isFull ? null : onJoin,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameAvatar extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;
  final ColorScheme colors;

  const _GameAvatar({
    required this.lobby,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = lobby.gameImageUrl != null && lobby.gameImageUrl!.isNotEmpty;

    if (hasImage) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          lobby.gameImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _InitialAvatar(lobby: lobby),
        ),
      );
    }

    return _InitialAvatar(lobby: lobby);
  }
}

class _InitialAvatar extends StatelessWidget {
  final LobbyEntity lobby;

  const _InitialAvatar({required this.lobby});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          lobby.gameName.isNotEmpty ? lobby.gameName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final String capacity;
  final bool isFull;
  final ColorScheme colors;

  const _CapacityBadge({
    required this.capacity,
    required this.isFull,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isFull ? colors.error : Colors.white.withValues(alpha: 0.25);
    final textColor = isFull ? Colors.white : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFull) Icon(Icons.person, size: 12, color: textColor),
          if (!isFull) const SizedBox(width: 4),
          Text(
            capacity,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isFull;
  final VoidCallback? onTap;

  const _JoinButton({required this.isFull, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isFull
            ? null
            : LinearGradient(colors: [colors.primary, colors.primary.withAlpha(204)]),
        color: isFull ? colors.surfaceContainerHighest : null,
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: isFull
            ? null
            : [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFull ? Icons.block : Icons.login,
                  size: 16,
                  color: isFull ? colors.onSurfaceVariant : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isFull ? 'Đầy' : 'Vào',
                  style: TextStyle(
                    color: isFull ? colors.onSurfaceVariant : Colors.white,
                    fontWeight: FontWeight.w700,
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

/// Gradient retry/create button.
class _GradientRetryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const _GradientRetryButton({
    required this.onTap,
    this.label = 'Thử lại',
    this.icon = Icons.refresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
