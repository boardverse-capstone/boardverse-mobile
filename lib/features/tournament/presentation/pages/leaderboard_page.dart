import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:boardverse/features/leaderboard/presentation/cubit/leaderboard_state.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_row_tile.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_skeleton.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_state_views.dart';

/// Leaderboard page cho Tournament tab.
///
/// Chỉ hiển thị Elo (vì tournament context = rank theo ELO). Dùng
/// shared widget `LeaderboardRowTile` để đảm bảo style nhất quán với
/// global leaderboard page.
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
      create: (_) => getIt<LeaderboardCubit>()..load(LeaderboardKind.elo),
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
        title: const Text(
          'Bảng xếp hạng',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ELO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Xếp hạng theo Global Elo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<LeaderboardCubit, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardInitial || state is LeaderboardLoading) {
            return const LeaderboardPageSkeleton();
          }
          if (state is LeaderboardError) {
            return LeaderboardErrorState(
              message: state.message,
              onRetry: () => context.read<LeaderboardCubit>().refresh(),
            );
          }
          final loaded = state as LeaderboardLoaded;
          final entries = loaded.result.entries;
          if (entries.isEmpty) {
            return const LeaderboardEmptyState(
              message: 'Bảng xếp hạng sẽ cập nhật khi có kết quả giải đấu.',
            );
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
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return LeaderboardRowTile(
                  entry: entry,
                  kind: LeaderboardKind.elo,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
