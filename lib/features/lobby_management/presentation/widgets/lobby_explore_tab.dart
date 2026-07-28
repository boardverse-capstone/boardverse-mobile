import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';

/// Tab Khám phá - Hiển thị danh sách lobby công khai.
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
        if (state is LobbyListLoading) {
          return const _LoadingView();
        }

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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Đang tải phòng chờ...'),
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
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
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
            Icon(
              Icons.meeting_room_outlined,
              size: 80,
              color: colors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Không có phòng chờ nào',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hãy là người đầu tiên tạo phòng để mọi người cùng tham gia!',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCreateLobby,
              icon: const Icon(Icons.add),
              label: const Text('Tạo phòng'),
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
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: lobbies.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '${lobbies.length} phòng chờ đang hoạt động',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.cardRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _GameImage(lobby: lobby, theme: theme),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _LobbyInfo(
                    lobby: lobby,
                    capacity: capacity,
                    isFull: isFull,
                    theme: theme,
                    timeFormatter: timeFormatter,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: isFull ? null : onJoin,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: const Text('Vào'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameImage extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  const _GameImage({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusMdAll,
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? AppColorsDark.cardGradientTeal
              : AppColors.cardGradientTeal,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          lobby.gameName.isNotEmpty ? lobby.gameName[0].toUpperCase() : '?',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _LobbyInfo extends StatelessWidget {
  final LobbyEntity lobby;
  final String capacity;
  final bool isFull;
  final ThemeData theme;
  final DateFormat timeFormatter;

  const _LobbyInfo({
    required this.lobby,
    required this.capacity,
    required this.isFull,
    required this.theme,
    required this.timeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lobby.gameName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _CapacityBadge(capacity: capacity, isFull: isFull, colors: colors, theme: theme),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          lobby.cafeName.isNotEmpty ? lobby.cafeName : 'Chưa chọn quán',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: colors.primary),
            const SizedBox(width: 4),
            Text(
              timeFormatter.format(lobby.scheduledTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.person, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                lobby.hostName,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final String capacity;
  final bool isFull;
  final ColorScheme colors;
  final ThemeData theme;

  const _CapacityBadge({
    required this.capacity,
    required this.isFull,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isFull ? colors.errorContainer : colors.primaryContainer,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Text(
        capacity,
        style: theme.textTheme.labelMedium?.copyWith(
          color: isFull ? colors.onErrorContainer : colors.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
