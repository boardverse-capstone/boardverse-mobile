import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_status.dart';

/// Neo-brutalism Tournament list card với press animation.
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
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');
    final status = widget.tournament.status;
    final statusColor = _statusColor(theme, status);
    final isCancelled = status == TournamentStatus.cancelled;

    // Cancelled tournaments vẫn cho phép tap (để xem thông tin lịch sử),
    // nhưng giảm độ tương phản để truyền tải trạng thái terminal.
    final effectiveBorderColor =
        isCancelled ? theme.colorScheme.outlineVariant : borderColor;
    final effectiveShadowColor = isCancelled
        ? AppColors.black.withValues(alpha: 0.02)
        : AppColors.black.withValues(alpha: 0.06);

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
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: effectiveBorderColor, width: NeoBrutalismTheme.borderWidth),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: effectiveShadowColor,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          // Giảm opacity cho giải đã hủy để UI phản ánh đúng trạng thái terminal
          // nhưng vẫn cho phép player tap vào xem chi tiết.
          child: Opacity(
            opacity: isCancelled ? 0.65 : 1.0,
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
                              fontWeight: FontWeight.w900,
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
                                    fontWeight: FontWeight.w600,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.black,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LinearProgressIndicator(
                      value: widget.tournament.fillRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
                if (widget.tournament.hasPrizePool) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.black,
                        width: NeoBrutalismTheme.borderWidth,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          blurRadius: 0,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.level,
                          size: AppIcons.sm,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'GIẢI THƯỞNG: ${_formatVnd(widget.tournament.prizePool)}đ',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
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
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: const Icon(
        AppIcons.tournament,
        size: AppIcons.xl,
        color: AppColors.white,
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
    final color = _statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 10, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
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
    final color = emphasized ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppIcons.sm,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Color _statusColor(ThemeData theme, TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return AppColors.secondary;
    case TournamentStatus.registrationOpen:
      return AppColors.success;
    case TournamentStatus.registrationClosed:
      return AppColors.accent;
    case TournamentStatus.ongoing:
      return AppColors.primary;
    case TournamentStatus.completed:
      return theme.colorScheme.onSurfaceVariant;
    case TournamentStatus.cancelled:
      return AppColors.error;
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