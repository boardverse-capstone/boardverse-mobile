import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/navigation/tournament_routes.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/match_detail_page.dart';

/// Tab 3: Tournament bracket / matches grouped by round.
/// Tapping a match card opens [MatchDetailPage].
class TournamentMatchesTab extends StatefulWidget {
  final String tournamentId;
  final List<TournamentMatchEntity> matches;

  const TournamentMatchesTab({
    super.key,
    required this.tournamentId,
    required this.matches,
  });

  @override
  State<TournamentMatchesTab> createState() => _TournamentMatchesTabState();
}

class _TournamentMatchesTabState extends State<TournamentMatchesTab> {
  int? _selectedRound; // null = all rounds

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports_outlined,
                  size: AppIcons.xxl * 2,
                  color: theme.colorScheme.outlineVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chưa có bàn đấu',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bàn đấu sẽ xuất hiện khi giải bắt đầu.',
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

    final rounds = _uniqueRounds(widget.matches);
    final filtered = _selectedRound == null
        ? widget.matches
        : widget.matches
            .where((m) => m.roundNumber == _selectedRound)
            .toList();

    return Column(
      children: [
        _RoundFilterChips(
          rounds: rounds,
          selectedRound: _selectedRound,
          onSelected: (round) => setState(() => _selectedRound = round),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final match = filtered[index];
              return _MatchCard(
                match: match,
                onTap: () {
                  TournamentRoutes.openMatchDetail(
                    context: context,
                    matchId: match.id,
                    initial: match,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<int> _uniqueRounds(List<TournamentMatchEntity> matches) {
    final rounds = matches.map((m) => m.roundNumber).toSet().toList()
      ..sort();
    return rounds;
  }
}

class _RoundFilterChips extends StatelessWidget {
  final List<int> rounds;
  final int? selectedRound;
  final ValueChanged<int?> onSelected;

  const _RoundFilterChips({
    required this.rounds,
    required this.selectedRound,
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
        children: [
          _chip(
            theme,
            label: 'Tất cả',
            selected: selectedRound == null,
            onTap: () => onSelected(null),
          ),
          ...rounds.map(
            (r) => _chip(
              theme,
              label: r == 4 ? 'Chung kết' : 'Vòng $r',
              selected: selectedRound == r,
              onTap: () => onSelected(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    ThemeData theme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
        backgroundColor: theme.colorScheme.surface,
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final TournamentMatchEntity match;
  final VoidCallback onTap;

  const _MatchCard({required this.match, required this.onTap});

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
                      match.roundDisplayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Bàn ${match.tableNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _StatusDot(status: match.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (match.results.isEmpty)
                Text(
                  'Chưa có kết quả',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...match.results.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            r.isWinner
                                ? Icons.emoji_events
                                : Icons.person_outline,
                            size: AppIcons.sm,
                            color: r.isWinner
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              r.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    r.isWinner ? FontWeight.w700 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${r.score}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: r.isWinner
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final MatchStatus status;
  const _StatusDot({required this.status});

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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}