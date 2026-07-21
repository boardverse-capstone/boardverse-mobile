import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';

/// Shows details of a single tournament match.
/// Uses [TournamentRepository.getMatchById] to fetch fresh data.
class MatchDetailPage extends StatefulWidget {
  final String matchId;
  final TournamentMatchEntity? initial;

  const MatchDetailPage({
    super.key,
    required this.matchId,
    this.initial,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late Future<TournamentMatchEntity> _future;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _future = Future.value(widget.initial!);
    } else {
      _future = _fetch();
    }
  }

  Future<TournamentMatchEntity> _fetch() async {
    final result =
        await getIt<TournamentRepository>().getMatchById(widget.matchId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (entity) => entity,
    );
  }

  void _refresh() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Chi tiết trận đấu'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<TournamentMatchEntity>(
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
          return _MatchBody(match: snapshot.data!);
        },
      ),
    );
  }
}

class _MatchBody extends StatelessWidget {
  final TournamentMatchEntity match;
  const _MatchBody({required this.match});

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
        _Header(match: match),
        const SizedBox(height: AppSpacing.lg),
        if (match.duration != null) ...[
          _DurationCard(duration: match.duration!),
          const SizedBox(height: AppSpacing.lg),
        ],
        _ResultsList(match: match),
        if (match.notes != null && match.notes!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghi chú',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  match.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final TournamentMatchEntity match;
  const _Header({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Tag(
                label: match.roundDisplayName,
                color: theme.colorScheme.primary,
                background: theme.colorScheme.primaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              _Tag(
                label: 'Bàn ${match.tableNumber}',
                color: theme.colorScheme.onSurfaceVariant,
                background: theme.colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusBadge(status: match.status),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  const _Tag({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      MatchStatus.scheduled => theme.colorScheme.outline,
      MatchStatus.onGoing => theme.colorScheme.tertiary,
      MatchStatus.completed => theme.colorScheme.primary,
      MatchStatus.cancelled => theme.colorScheme.error,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          status.label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DurationCard extends StatelessWidget {
  final Duration duration;
  const _DurationCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(AppIcons.schedule, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời lượng trận đấu',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '$minutes phút ${seconds > 0 ? '$seconds giây' : ''}'.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
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

class _ResultsList extends StatelessWidget {
  final TournamentMatchEntity match;
  const _ResultsList({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (match.results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.radiusMdAll,
        ),
        child: Center(
          child: Text(
            'Chưa ghi nhận kết quả',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Sort by rank, then by score desc
    final sorted = [...match.results]
      ..sort((a, b) {
        if (a.rank != null && b.rank != null) {
          return a.rank!.compareTo(b.rank!);
        }
        return b.score.compareTo(a.score);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...sorted.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _ResultRow(result: r),
            )),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final MatchPlayerResult result;
  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = result.displayName.isNotEmpty
        ? result.displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: result.isWinner
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: result.isWinner
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: result.isWinner ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          if (result.isWinner)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: result.avatarUrl != null && result.avatarUrl!.isNotEmpty
                ? Image.network(result.avatarUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      initial,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight:
                        result.isWinner ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Điểm danh ${result.cardsBought} thẻ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.score}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: result.isWinner
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'điểm',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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