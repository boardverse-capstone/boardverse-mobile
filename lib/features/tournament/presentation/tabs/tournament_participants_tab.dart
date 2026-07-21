import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/navigation/tournament_routes.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/presentation/pages/participant_detail_page.dart';

/// Tab 2: Lists tournament participants.
/// Tap a row to navigate to [ParticipantDetailPage].
class TournamentParticipantsTab extends StatelessWidget {
  final String tournamentId;
  final List<TournamentParticipantEntity> participants;

  const TournamentParticipantsTab({
    super.key,
    required this.tournamentId,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.users,
                  size: AppIcons.xxl * 2,
                  color: theme.colorScheme.outlineVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chưa có người tham gia',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Danh sách sẽ cập nhật khi có người đăng ký.',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = participants[index];
        return _ParticipantCard(
          participant: p,
          onTap: () {
            TournamentRoutes.openParticipantDetail(
              context: context,
              tournamentId: tournamentId,
              participantId: p.id,
              initial: p,
            );
          },
        );
      },
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final TournamentParticipantEntity participant;
  final VoidCallback onTap;

  const _ParticipantCard({
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: participant.isCurrentUser
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        borderRadius: AppRadius.radiusMdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: participant.isCurrentUser
              ? BoxDecoration(
                  borderRadius: AppRadius.radiusMdAll,
                  border: Border.all(color: theme.colorScheme.primary),
                )
              : null,
          child: Row(
            children: [
              _Avatar(
                avatarUrl: participant.avatarUrl,
                displayName: participant.displayName,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            participant.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (participant.isCurrentUser) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: AppRadius.radiusSmAll,
                            ),
                            child: Text(
                              'Bạn',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(AppIcons.elo,
                            size: AppIcons.sm,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${participant.elo}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.star,
                            size: AppIcons.sm,
                            color: theme.colorScheme.tertiary),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'Karma ${participant.karma}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusBadge(status: participant.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;

  const _Avatar({required this.avatarUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusFullAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(avatarUrl!, fit: BoxFit.cover)
          : Center(
              child: Text(
                initial,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ParticipantStatus status;
  const _StatusBadge({required this.status});

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

  _BadgeColor _resolveColor(ThemeData theme, ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.checkedIn:
      case ParticipantStatus.active:
        return _BadgeColor(
          background: theme.colorScheme.tertiaryContainer,
          foreground: theme.colorScheme.tertiary,
        );
      case ParticipantStatus.finished:
        return _BadgeColor(
          background: theme.colorScheme.secondaryContainer,
          foreground: theme.colorScheme.secondary,
        );
      case ParticipantStatus.withdrawn:
      case ParticipantStatus.noShow:
        return _BadgeColor(
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.error,
        );
      default:
        return _BadgeColor(
          background: theme.colorScheme.surfaceContainerHigh,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _BadgeColor {
  final Color background;
  final Color foreground;
  const _BadgeColor({required this.background, required this.foreground});
}