import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/widgets/shimmer_skeletons.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/elo_history_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/elo_history_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/utils/tournament_utils.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/elo_chart.dart';

/// Shows the current user's Elo history across tournaments.
class EloHistoryPage extends StatelessWidget {
  final EloHistoryCubit? cubit;

  const EloHistoryPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<EloHistoryCubit>.value(
        value: cubit!,
        child: const _EloHistoryView(),
      );
    }
    return BlocProvider<EloHistoryCubit>(
      create: (_) => getIt<EloHistoryCubit>()..loadEloHistory(),
      child: const _EloHistoryView(),
    );
  }
}

class _EloHistoryView extends StatelessWidget {
  const _EloHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Lịch sử Elo'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: BlocBuilder<EloHistoryCubit, EloHistoryState>(
        builder: (context, state) {
          if (state is EloHistoryInitial || state is EloHistoryLoading) {
            return const EloHistorySkeleton();
          }
          if (state is EloHistoryError) {
            return _ErrorState(
              message: state.message,
              onRetry: () => context.read<EloHistoryCubit>().refresh(),
            );
          }
          final loaded = state as EloHistoryLoaded;
          if (loaded.history.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => context.read<EloHistoryCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _SummaryCard(state: loaded),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Biểu đồ Elo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                EloChart(history: loaded.history),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Lịch sử chi tiết',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...loaded.history.reversed
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _HistoryTile(entry: e),
                        )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final EloHistoryLoaded state;
  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Elo hiện tại',
              value: state.currentElo.toString(),
              color: Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Tổng thay đổi',
              value: (state.totalDelta >= 0 ? '+' : '') +
                  state.totalDelta.toString(),
              color: Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _StatColumn(
              label: 'Đã chơi',
              value: '${state.tournamentsPlayed}',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final EloHistoryEntity entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = entry.delta >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPositive
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Text(
              entry.formattedDelta,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isPositive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.tournamentTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.initialElo} → ${entry.finalElo} • ${TournamentUtils.formatDateTime(entry.playedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.formattedRank != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.rankDisplayName} ${entry.formattedRank!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
            Text(
              'Chưa có lịch sử Elo',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy tham gia một giải đấu để bắt đầu xây dựng Elo của bạn.',
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