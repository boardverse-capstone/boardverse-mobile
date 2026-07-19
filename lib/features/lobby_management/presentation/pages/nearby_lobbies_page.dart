import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/theme.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_config_page.dart';
import '../../domain/entities/lobby_summary.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_page.dart';

/// Trang danh sách lobby khả dụng quanh user (BR-10 + BR-08).
///
/// - Filter theo bán kính & Karma (slider trên top).
/// - Pull-to-refresh.
/// - Tap card → join lobby → navigate LobbyPage.
class NearbyLobbiesPage extends StatefulWidget {
  const NearbyLobbiesPage({super.key});

  @override
  State<NearbyLobbiesPage> createState() => _NearbyLobbiesPageState();
}

class _NearbyLobbiesPageState extends State<NearbyLobbiesPage> {
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  double _radiusKm = 10.0;
  double _minKarma = 0.0;

  late final LobbySearchCubit _searchCubit;
  late final LobbyCubit _lobbyCubit;

  @override
  void initState() {
    super.initState();
    _searchCubit = context.read<LobbySearchCubit>();
    _lobbyCubit = context.read<LobbyCubit>();
    _runSearch();
  }

  void _runSearch() {
    _searchCubit.searchNearbyLobbies(
      filter: LobbySearchFilter(
        radiusKm: _radiusKm,
        minKarma: _minKarma,
        excludeOwnLobbies: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm phòng chờ'),
        actions: [
          IconButton(
            tooltip: 'Tạo phòng mới',
            icon: const Icon(AppIcons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LobbyConfigPage(
                    gameId: 'demo',
                    gameName: 'Demo Game',
                    cafeId: 'demo_cafe',
                    cafeName: 'Demo Cafe',
                    matchmakingCubit: context.read<MatchmakingCubit>(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            radiusKm: _radiusKm,
            minKarma: _minKarma,
            theme: theme,
            onRadiusChanged: (value) {
              setState(() => _radiusKm = value);
              _runSearch();
            },
            onKarmaChanged: (value) {
              setState(() => _minKarma = value);
              _runSearch();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<LobbySearchCubit, LobbyState>(
              bloc: _searchCubit,
              builder: (context, state) {
                if (state is LobbyListLoading) {
                  return const _LoadingPanel();
                }
                if (state is LobbyListEmpty) {
                  return _EmptyView(message: state.message);
                }
                if (state is LobbyFailure) {
                  return _EmptyView(
                    message: state.message,
                    isError: true,
                    onRetry: _runSearch,
                  );
                }
                if (state is LobbyListLoaded) {
                  final lobbies = state.lobbies;
                  return RefreshIndicator(
                    onRefresh: () async => _runSearch(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      itemCount: lobbies.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _LobbyCard(
                            lobby: lobbies[index],
                            theme: theme,
                            onJoin: _joinAndOpen,
                            timeFormatter: _timeFormatter,
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinAndOpen(LobbySummary lobby) async {
    final joinResult = await _lobbyCubit.joinLobby(lobby.id, null);
    if (!mounted) return;
    final failureOrLobby = joinResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (failureOrLobby != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureOrLobby.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobby.id, lobbyCubit: _lobbyCubit),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Đang tìm phòng gần bạn...', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final double radiusKm;
  final double minKarma;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onKarmaChanged;
  final ThemeData theme;

  const _FilterBar({
    required this.radiusKm,
    required this.minKarma,
    required this.theme,
    required this.onRadiusChanged,
    required this.onKarmaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        boxShadow: AppElevation.shadowXxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow(
            icon: AppIcons.location,
            label: 'Bán kính',
            value: radiusKm < 1
                ? '${(radiusKm * 1000).toInt()} m'
                : '${radiusKm.toStringAsFixed(1)} km',
            valueColor: colors.primary,
            theme: theme,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primary,
              thumbColor: colors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: radiusKm,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${radiusKm.toStringAsFixed(1)} km',
              onChanged: onRadiusChanged,
            ),
          ),
          _FilterRow(
            icon: AppIcons.karma,
            label: 'Karma tối thiểu',
            value: '${minKarma.toInt()}',
            valueColor: colors.tertiary,
            theme: theme,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.tertiary,
              thumbColor: colors.tertiary,
              trackHeight: 4,
            ),
            child: Slider(
              value: minKarma,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${minKarma.toInt()} Karma',
              onChanged: onKarmaChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final ThemeData theme;

  const _FilterRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Icon(icon, size: AppIcons.sm, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LobbyCard extends StatelessWidget {
  final LobbySummary lobby;
  final void Function(LobbySummary) onJoin;
  final ThemeData theme;
  final DateFormat timeFormatter;

  const _LobbyCard({
    required this.lobby,
    required this.onJoin,
    required this.theme,
    required this.timeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final distance = lobby.distanceKm < 1
        ? '${(lobby.distanceKm * 1000).toInt()} m'
        : '${lobby.distanceKm.toStringAsFixed(1)} km';
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onJoin(lobby),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(lobby: lobby, theme: theme),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lobby.gameName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _SlotsBadge(
                            lobby: lobby,
                            isFull: isFull,
                            progress: capacityProgress,
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            AppIcons.cafe,
                            size: AppIcons.sm,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              lobby.cafeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaChip(icon: AppIcons.location, label: distance),
                          _MetaChip(
                            icon: AppIcons.karma,
                            label: '≥ ${lobby.minimumKarma.toInt()}',
                            accent: colors.tertiary,
                          ),
                          _MetaChip(
                            icon: AppIcons.clock,
                            label: timeFormatter.format(lobby.scheduledTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFull
                                ? 'Phòng đã đầy'
                                : 'Còn ${lobby.slotsRemaining} chỗ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isFull
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                                size: AppIcons.sm,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                lobby.isPublic ? 'Công khai' : 'Riêng tư',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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

class _CardImage extends StatelessWidget {
  final LobbySummary lobby;
  final ThemeData theme;

  const _CardImage({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasImage = lobby.gameImageUrl.trim().isNotEmpty;
    final placeholder = Container(
      width: 80,
      height: 80,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.boardGame,
            size: AppIcons.xl,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Board Game',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: AppRadius.radiusMdAll,
      child: hasImage
          ? Image.network(
              lobby.gameImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }
}

class _SlotsBadge extends StatelessWidget {
  final LobbySummary lobby;
  final bool isFull;
  final double progress;
  final ThemeData theme;

  const _SlotsBadge({
    required this.lobby,
    required this.isFull,
    required this.progress,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final bg = isFull ? colors.errorContainer : colors.primaryContainer;
    final fg = isFull ? colors.onErrorContainer : colors.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.radiusSmAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lobby.currentPlayers}/${lobby.maxPlayers}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(
            width: 44,
            child: ClipRRect(
              borderRadius: AppRadius.radiusFullAll,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: fg.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _MetaChip({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlight = accent ?? colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcons.sm, color: highlight),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: highlight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const _EmptyView({required this.message, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRetry == null ? () async {} : () async => onRetry!(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isError
                    ? colors.errorContainer
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? AppIcons.error : AppIcons.search,
                size: AppIcons.massive,
                color: isError
                    ? colors.onErrorContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            isError
                ? 'Đã có lỗi xảy ra, bạn có thể thử lại để cập nhật danh sách.'
                : 'Hãy tinh chỉnh bộ lọc hoặc tạo phòng mới để bắt đầu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
