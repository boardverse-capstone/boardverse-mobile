import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_status.dart';

/// Tournament list card với press animation (scale 0.96).
class TournamentListCard extends StatefulWidget {
  final TournamentEntity tournament;
  final VoidCallback? onTap;

  const TournamentListCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  State<TournamentListCard> createState() => _TournamentListCardState();
}

class _TournamentListCardState extends State<TournamentListCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final statusColor = _statusColor(theme, widget.tournament.status);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: AppElevation.elevationNone,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TournamentIcon(color: statusColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tournament.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            children: [
                              Icon(
                                AppIcons.boardGame,
                                size: AppIcons.xs,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Expanded(
                                child: Text(
                                  '${widget.tournament.gameTemplateName} · ${widget.tournament.cafeName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _StatusChip(status: widget.tournament.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MetaItem(
                      icon: AppIcons.schedule,
                      label: dateFmt.format(widget.tournament.startTime),
                    ),
                    _MetaItem(
                      icon: AppIcons.clock,
                      label: timeFmt.format(widget.tournament.startTime),
                    ),
                    _MetaItem(
                      icon: AppIcons.cash,
                      label: widget.tournament.isFree
                          ? 'Miễn phí'
                          : '${_formatVnd(widget.tournament.registrationFee!)}đ',
                      emphasized: !widget.tournament.isFree,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      AppIcons.users,
                      size: AppIcons.sm,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${widget.tournament.currentParticipants}/${widget.tournament.maxParticipants} người tham gia',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (widget.tournament.requiresKarma) ...[
                      Icon(
                        AppIcons.elo,
                        size: AppIcons.sm,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Karma ≥ ${widget.tournament.minKarmaRequirement}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.radiusFullAll,
                  child: LinearProgressIndicator(
                    value: widget.tournament.fillRatio,
                    minHeight: AppSpacing.xs,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                if (widget.tournament.hasPrizePool) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: AppRadius.radiusSmAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.level,
                          size: AppIcons.sm,
                          color: AppColors.accentDark,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Tổng giải thưởng: ${_formatVnd(widget.tournament.prizePool)}đ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.accent
                                : AppColors.accentDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatVnd(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _TournamentIcon extends StatelessWidget {
  final Color color;

  const _TournamentIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Icon(AppIcons.tournament, size: AppIcons.xl, color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.tagRadius,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: AppIcons.xs, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppIcons.sm,
          color: emphasized
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: emphasized ? theme.colorScheme.primary : null,
            fontWeight: emphasized ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}

Color _statusColor(ThemeData theme, TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return theme.colorScheme.secondary;
    case TournamentStatus.registrationOpen:
      return AppColors.success;
    case TournamentStatus.registrationClosed:
      return theme.colorScheme.tertiary;
    case TournamentStatus.ongoing:
      return theme.colorScheme.primary;
    case TournamentStatus.completed:
      return theme.colorScheme.onSurfaceVariant;
    case TournamentStatus.cancelled:
      return theme.colorScheme.error;
  }
}

IconData _statusIcon(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return AppIcons.pending;
    case TournamentStatus.registrationOpen:
      return AppIcons.userCheck;
    case TournamentStatus.registrationClosed:
      return AppIcons.lock;
    case TournamentStatus.ongoing:
      return Icons.play_circle_outline_rounded;
    case TournamentStatus.completed:
      return AppIcons.flag;
    case TournamentStatus.cancelled:
      return AppIcons.close;
  }
}
