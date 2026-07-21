import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/navigation/tournament_routes.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_list_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_list_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_hero.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_filter_section.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_error_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_list_card.dart';
import 'package:boardverse_mobile/features/tournament/presentation/utils/tournament_utils.dart';

class TournamentPage extends StatelessWidget {
  const TournamentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TournamentListCubit>()..loadTournaments(),
      child: const _TournamentPageContent(),
    );
  }
}

class _TournamentPageContent extends StatefulWidget {
  const _TournamentPageContent();

  @override
  State<_TournamentPageContent> createState() => _TournamentPageContentState();
}

class _TournamentPageContentState extends State<_TournamentPageContent> {
  static const _heroHeight = 224.0;
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocBuilder<TournamentListCubit, TournamentListState>(
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                expandedHeight: _heroHeight,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  PopupMenuButton<_TournamentMenuAction>(
                    tooltip: 'Tùy chọn',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => _onMenuAction(context, action),
                    itemBuilder: (popupContext) => const [
                      PopupMenuItem(
                        value: _TournamentMenuAction.myRegistrations,
                        child: ListTile(
                          leading: Icon(Icons.assignment_outlined),
                          title: Text('Giải của tôi'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _TournamentMenuAction.eloHistory,
                        child: ListTile(
                          leading: Icon(Icons.trending_up),
                          title: Text('Lịch sử Elo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _TournamentMenuAction.leaderboard,
                        child: ListTile(
                          leading: Icon(Icons.leaderboard_outlined),
                          title: Text('Bảng xếp hạng'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  title: Text(
                    'Giải đấu',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: TournamentHero(state: state),
                ),
              ),
              SliverToBoxAdapter(
                child: TournamentFilterSection(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (index) => setState(() => _selectedFilter = index),
                ),
              ),
            ],
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TournamentListState state) {
    if (state is TournamentListLoading || state is TournamentListInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TournamentListError) {
      return TournamentErrorState(
        message: state.message,
        onRetry: () => context.read<TournamentListCubit>().loadTournaments(),
      );
    }

    if (state is TournamentListLoaded) {
      final filtered = TournamentUtils.filterTournaments(state, _selectedFilter);

      if (filtered.isEmpty) {
        return const _TournamentEmptyPlaceholder();
      }

      return RefreshIndicator(
        onRefresh: () => context.read<TournamentListCubit>().refresh(),
        child: ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.massive,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final tournament = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TournamentListCard(
                tournament: tournament,
                onTap: () => _showTournamentDetail(context, tournament),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showTournamentDetail(BuildContext context, TournamentEntity tournament) {
    TournamentRoutes.openTournamentDetail(
      context: context,
      tournamentId: tournament.id,
    );
  }

  void _onMenuAction(BuildContext context, _TournamentMenuAction action) {
    switch (action) {
      case _TournamentMenuAction.myRegistrations:
        TournamentRoutes.openMyRegistrations(context);
        break;
      case _TournamentMenuAction.eloHistory:
        TournamentRoutes.openEloHistory(context);
        break;
      case _TournamentMenuAction.leaderboard:
        TournamentRoutes.openLeaderboard(context);
        break;
    }
  }
}

/// Menu actions exposed from the tournament page popup menu.
enum _TournamentMenuAction {
  myRegistrations,
  eloHistory,
  leaderboard,
}

class _TournamentEmptyPlaceholder extends StatelessWidget {
  const _TournamentEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.tournament,
              size: AppIcons.xxl * 2,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không có giải đấu nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy quay lại sau để cập nhật thông tin mới nhất.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
