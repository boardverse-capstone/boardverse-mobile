import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';

/// Shows details of a single participant in a tournament.
///
/// Uses [TournamentRepository.getParticipant] to fetch fresh data,
/// falls back to a loading state if no entity was provided.
class ParticipantDetailPage extends StatefulWidget {
  final String tournamentId;
  final String participantId;
  final TournamentParticipantEntity? initial;

  const ParticipantDetailPage({
    super.key,
    required this.tournamentId,
    required this.participantId,
    this.initial,
  });

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  late Future<TournamentParticipantEntity> _future;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _future = Future.value(widget.initial!);
    } else {
      _future = _fetch();
    }
  }

  Future<TournamentParticipantEntity> _fetch() async {
    final result = await getIt<TournamentRepository>().getParticipant(
      widget.tournamentId,
      widget.participantId,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (entity) => entity,
    );
  }

  void _refresh() {
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Người tham gia'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<TournamentParticipantEntity>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final participant = snapshot.data!;
          return _ParticipantBody(participant: participant);
        },
      ),
    );
  }
}

class _ParticipantBody extends StatelessWidget {
  final TournamentParticipantEntity participant;
  const _ParticipantBody({required this.participant});

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
        _Header(participant: participant),
        const SizedBox(height: AppSpacing.lg),
        _StatsGrid(participant: participant),
        const SizedBox(height: AppSpacing.lg),
        if (participant.isWalkIn)
          _InfoBanner(
            icon: Icons.directions_walk,
            text: 'Đây là walk-in (khách vãng lai)',
            color: theme.colorScheme.tertiary,
          ),
        const SizedBox(height: AppSpacing.lg),
        if (participant.finalRank != null) ...[
          _FinalRankCard(rank: participant.finalRank!),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final TournamentParticipantEntity participant;
  const _Header({required this.participant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        participant.displayName.isNotEmpty ? participant.displayName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: participant.avatarUrl != null &&
                    participant.avatarUrl!.isNotEmpty
                ? Image.network(participant.avatarUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      initial,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            participant.displayName,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Text(
              participant.status.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final TournamentParticipantEntity participant;
  const _StatsGrid({required this.participant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: AppIcons.elo,
            label: 'Elo',
            value: '${participant.elo}',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.star,
            label: 'Karma',
            value: '${participant.karma}',
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: AppIcons.elo,
            label: 'Δ Elo',
            value: participant.eloDelta >= 0
                ? '+${participant.eloDelta}'
                : '${participant.eloDelta}',
            color: participant.eloDelta >= 0
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalRankCard extends StatelessWidget {
  final int rank;
  const _FinalRankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;
    IconData icon;
    switch (rank) {
      case 1:
        label = 'Nhà vô địch';
        icon = Icons.emoji_events;
        break;
      case 2:
        label = 'Á quân';
        icon = Icons.workspace_premium;
        break;
      case 3:
        label = 'Hạng 3';
        icon = Icons.military_tech;
        break;
      default:
        label = 'Hạng $rank';
        icon = Icons.shield;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thứ hạng chung cuộc',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
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