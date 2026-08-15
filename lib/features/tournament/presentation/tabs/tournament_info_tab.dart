import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_action_button.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_detail_info.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_engagement_panel.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_status_pill.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_tab_header.dart';

/// Tab 1: Tournament info, status, description + action button +
/// Waitlist/Spectator panel (T-03 + T-04).
class TournamentInfoTab extends StatelessWidget {
  final TournamentEntity tournament;
  final bool isRegistering;
  final VoidCallback onRegister;
  final VoidCallback onUnregister;

  const TournamentInfoTab({
    super.key,
    required this.tournament,
    required this.isRegistering,
    required this.onRegister,
    required this.onUnregister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        TournamentTabHeader(tournament: tournament),
        const SizedBox(height: AppSpacing.md),
        TournamentStatusPill(status: tournament.status),
        const SizedBox(height: AppSpacing.md),
        if (tournament.description.isNotEmpty) _buildDescription(theme),
        const SizedBox(height: AppSpacing.xl),
        TournamentDetailInfo(tournament: tournament),
        const SizedBox(height: AppSpacing.xl),
        // T-03 + T-04: Waitlist + Spectator panels — auto-render dựa trên
        // TournamentEngagementCubit mà widget cha (TournamentDetailPage)
        // đã cung cấp.
        const TournamentEngagementPanel(),
        const SizedBox(height: AppSpacing.xl),
        TournamentActionButton(
          tournament: tournament,
          isRegistering: isRegistering,
          onRegister: onRegister,
          onUnregister: onUnregister,
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
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