import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/current_user_resolver.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_detail_state.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_status_pill.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_detail_header.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_detail_info.dart';
import 'package:boardverse_mobile/features/tournament/presentation/widgets/tournament_action_button.dart';

class TournamentDetailSheet extends StatelessWidget {
  final TournamentEntity tournament;

  const TournamentDetailSheet({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<String?>(
      future: getIt<CurrentUserResolver>().resolveUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data;
        return BlocProvider(
          create: (_) {
            final cubit = getIt<TournamentDetailCubit>();
            cubit.loadDetail(tournament.id, currentUserId: userId);
            return cubit;
          },
          child: BlocConsumer<TournamentDetailCubit, TournamentDetailState>(
        listener: (ctx, state) {
          if (state is TournamentDetailActionSuccess) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSmAll),
                content: Text(state.message),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is TournamentDetailError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSmAll),
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          TournamentEntity currentTournament = tournament;
          bool isLoading = false;
          bool isRegistering = false;

          if (state is TournamentDetailLoading) {
            isLoading = true;
          } else if (state is TournamentDetailLoaded) {
            currentTournament = state.tournament;
          } else if (state is TournamentDetailRegistering) {
            isRegistering = true;
            currentTournament = state.tournament;
          } else if (state is TournamentDetailActionSuccess) {
            isLoading = true;
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.52,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.radiusTopOnly(
                  topLeft: AppRadius.radiusXl,
                  topRight: AppRadius.radiusXl,
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, scrollController, ctx, currentTournament, isRegistering),
            ),
          );
        },
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    BuildContext ctx,
    TournamentEntity tournament,
    bool isRegistering,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(theme),
          const SizedBox(height: AppSpacing.lg),
          TournamentDetailHeader(
            tournament: tournament,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
          TournamentStatusPill(status: tournament.status),
          const SizedBox(height: AppSpacing.md),
          _buildDescription(theme, tournament),
          const SizedBox(height: AppSpacing.xl),
          TournamentDetailInfo(tournament: tournament),
          const SizedBox(height: AppSpacing.xl),
          TournamentActionButton(
            tournament: tournament,
            isRegistering: isRegistering,
            onRegister: () => ctx.read<TournamentDetailCubit>().register(tournament.id),
            onUnregister: () => ctx.read<TournamentDetailCubit>().unregister(tournament.id),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: AppSpacing.xxxl,
        height: AppSpacing.xxs,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: AppRadius.radiusFullAll,
        ),
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, TournamentEntity tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Text(
        tournament.description,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}
