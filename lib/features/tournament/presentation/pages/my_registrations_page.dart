import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/widgets/shimmer_skeletons.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/my_registrations_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/my_registrations_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/tournament_detail_sheet.dart';
import 'package:boardverse_mobile/features/tournament/presentation/utils/tournament_utils.dart';

/// Lists tournaments the current user has registered for.
///
/// Tapping a card opens the existing detail bottom sheet so the user
/// can review info, withdraw, or watch the bracket.
class MyRegistrationsPage extends StatelessWidget {
  final MyRegistrationsCubit? cubit;

  const MyRegistrationsPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<MyRegistrationsCubit>.value(
        value: cubit!,
        child: const _MyRegistrationsView(),
      );
    }
    return BlocProvider<MyRegistrationsCubit>(
      create: (_) =>
          getIt<MyRegistrationsCubit>()..loadMyRegistrations(),
      child: const _MyRegistrationsView(),
    );
  }
}

class _MyRegistrationsView extends StatelessWidget {
  const _MyRegistrationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Giải của tôi'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: BlocBuilder<MyRegistrationsCubit, MyRegistrationsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterChips(
                active: state is MyRegistrationsLoaded
                    ? state.activeFilter
                    : (state is MyRegistrationsLoading
                        ? state.currentFilter
                        : MyRegistrationsFilter.all),
                onSelected: (filter) =>
                    context.read<MyRegistrationsCubit>().applyFilter(filter),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MyRegistrationsState state) {
    if (state is MyRegistrationsInitial || state is MyRegistrationsLoading) {
      return const TournamentListSkeleton();
    }

    if (state is MyRegistrationsError) {
      return _ErrorState(
        message: state.message,
        onRetry: () =>
            context.read<MyRegistrationsCubit>().refresh(),
      );
    }

    if (state is MyRegistrationsLoaded) {
      if (state.tournaments.isEmpty) {
        return _EmptyState(filter: state.activeFilter);
      }
      return RefreshIndicator(
        onRefresh: () => context.read<MyRegistrationsCubit>().refresh(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          itemCount: state.tournaments.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final tournament = state.tournaments[index];
            return _MyRegistrationCard(
              tournament: tournament,
              onTap: () => _openDetail(context, tournament),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openDetail(BuildContext context, TournamentEntity tournament) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TournamentDetailSheet(tournament: tournament),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final MyRegistrationsFilter active;
  final ValueChanged<MyRegistrationsFilter> onSelected;

  const _FilterChips({
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: MyRegistrationsFilter.values.map((filter) {
          final isSelected = filter == active;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.chipRadius,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MyRegistrationCard extends StatelessWidget {
  final TournamentEntity tournament;
  final VoidCallback onTap;

  const _MyRegistrationCard({
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        borderRadius: AppRadius.radiusMdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusChip(status: tournament.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${tournament.cafeName} • ${tournament.gameTemplateName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(AppIcons.schedule,
                      size: AppIcons.sm,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    TournamentUtils.formatDateTime(tournament.startTime),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(AppIcons.users,
                      size: AppIcons.sm,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${tournament.currentParticipants}/${tournament.maxParticipants}',
                    style: theme.textTheme.bodySmall,
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

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _resolveColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _ChipColor _resolveColor(ThemeData theme, TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return _ChipColor(
          background: theme.colorScheme.primaryContainer,
          foreground: theme.colorScheme.primary,
        );
      case TournamentStatus.ongoing:
        return _ChipColor(
          background: theme.colorScheme.tertiaryContainer,
          foreground: theme.colorScheme.tertiary,
        );
      case TournamentStatus.completed:
        return _ChipColor(
          background: theme.colorScheme.secondaryContainer,
          foreground: theme.colorScheme.secondary,
        );
      case TournamentStatus.cancelled:
        return _ChipColor(
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.error,
        );
      case TournamentStatus.upcoming:
      case TournamentStatus.registrationClosed:
        return _ChipColor(
          background: theme.colorScheme.surfaceContainerHigh,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _ChipColor {
  final Color background;
  final Color foreground;
  const _ChipColor({required this.background, required this.foreground});
}

class _EmptyState extends StatelessWidget {
  final MyRegistrationsFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final message = filter == MyRegistrationsFilter.all
        ? 'Bạn chưa đăng ký giải đấu nào.'
        : 'Không có giải đấu nào ở trạng thái "${filter.label}".';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.tournament,
              size: AppIcons.xxl * 2,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có giải đấu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
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
                size: AppIcons.xxl * 2,
                color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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