import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_result_entity.dart';
import 'package:boardverse/features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'package:boardverse/features/leaderboard/presentation/cubit/leaderboard_state.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_podium.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_row_tile.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_skeleton.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/leaderboard_state_views.dart';
import 'package:boardverse/features/leaderboard/presentation/widgets/user_rank_card.dart';

/// Trang leaderboard public — dùng dữ liệu THẬT từ
/// `/api/v1/leaderboard/{karma,elo,level}`.
///
/// Mapping tab theo quyết định với user:
/// - Tab 1: **ELO**   → `/api/v1/leaderboard/elo`
/// - Tab 2: **Level** → `/api/v1/leaderboard/level`
/// - Tab 3: **Karma** → `/api/v1/leaderboard/karma`
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeaderboardCubit>(
      create: (_) => getIt<LeaderboardCubit>()..load(LeaderboardKind.elo),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _autoRefreshTimer;

  static const _kinds = <LeaderboardKind>[
    LeaderboardKind.elo,
    LeaderboardKind.level,
    LeaderboardKind.karma,
  ];

  static const _autoRefreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kinds.length, vsync: this);
    _tabController.addListener(_onTabChange);
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted) {
        context.read<LeaderboardCubit>().refresh();
      }
    });
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    final kind = _kinds[_tabController.index];
    context.read<LeaderboardCubit>().switchKind(kind);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

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
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.all(4),
            decoration: NeoBrutalismTheme.autoBox(
              context,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderColor: theme.colorScheme.outlineVariant,
              borderRadius: 14,
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _kinds.map((k) => Tab(text: k.label)).toList(),
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              onTap: (_) {},
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
          return RefreshIndicator(
            onRefresh: () => context.read<LeaderboardCubit>().refresh(),
            child: _LeaderboardBody(
              result: loaded.result,
              kind: loaded.kind,
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  final LeaderboardResultEntity result;
  final LeaderboardKind kind;

  const _LeaderboardBody({required this.result, required this.kind});

  @override
  Widget build(BuildContext context) {
    final entries = result.entries;
    if (entries.isEmpty) {
      return const LeaderboardEmptyState();
    }

    // Sortable copy — backend đã DESC theo metric, nhưng đảm bảo thứ tự.
    final sorted = [...entries]..sort((a, b) => a.rank.compareTo(b.rank));
    final top3 = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      children: [
        LeaderboardPodium(top: top3, kind: kind),
        if (result.userRank != null) ...[
          const SizedBox(height: AppSpacing.md),
          UserRankCard(userRank: result.userRank!, kind: kind),
        ],
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
          icon: Icons.format_list_numbered_rounded,
          title: 'Bảng xếp hạng',
          subtitle: kind.description,
        ),
        for (final entry in rest) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: LeaderboardRowTile(
              entry: entry,
              kind: kind,
              showUserRankHint: result.userRank?.userId == entry.userId,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
