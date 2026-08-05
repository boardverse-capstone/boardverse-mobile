import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/widgets/shimmer_skeletons.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/leaderboard_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/leaderboard_state.dart';

class LeaderboardPage extends StatelessWidget {
  final LeaderboardCubit? cubit;

  const LeaderboardPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<LeaderboardCubit>.value(
        value: cubit!,
        child: const _LeaderboardView(),
      );
    }
    return BlocProvider<LeaderboardCubit>(
      create: (_) => getIt<LeaderboardCubit>()..loadLeaderboard(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardInitial || state is LeaderboardLoading) {
            return const LeaderboardListSkeleton();
          }
          if (state is LeaderboardError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context.read<LeaderboardCubit>().refresh(),
            );
          }
          final loaded = state as LeaderboardLoaded;
          if (loaded.entries.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => context.read<LeaderboardCubit>().refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              itemCount: loaded.entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final entry = loaded.entries[index];
                return _LeaderboardTile(
                  entry: entry,
                  isTop3: entry.rank <= 3,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatefulWidget {
  final LeaderboardEntryEntity entry;
  final bool isTop3;

  const _LeaderboardTile({
    required this.entry,
    required this.isTop3,
  });

  @override
  State<_LeaderboardTile> createState() => _LeaderboardTileState();
}

class _LeaderboardTileState extends State<_LeaderboardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use AppColors.getMedalColor for consistency
    final medalColor = AppColors.getMedalColor(widget.entry.rank);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.isTop3
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: widget.isTop3
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: widget.isTop3 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.entry.rank}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.entry.rank <= 3
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        _TierBadge(tier: widget.entry.eloTier),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            '${widget.entry.tournamentsPlayed} giải · ${widget.entry.tournamentsWon} thắng',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.entry.globalElo}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Elo',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final EloTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Text(
        tier.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.elo,
                size: AppIcons.xxl * 2,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Chưa có bảng xếp hạng',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bảng xếp hạng sẽ cập nhật khi có kết quả giải đấu.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: AppIcons.xxl * 2, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Đã xảy ra lỗi',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
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
