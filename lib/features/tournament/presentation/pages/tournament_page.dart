import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/mock_tournaments.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_status.dart';
import '../widgets/tournament_empty_state.dart';
import '../widgets/tournament_list_card.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  static const _allLabel = 'Tất cả';
  static const _filterLabels = <String>[
    _allLabel,
    'Đang mở',
    'Sắp diễn ra',
    'Đang diễn ra',
    'Đã kết thúc',
  ];
  static const _heroHeight = 224.0;

  int _selectedFilter = 0;
  late List<TournamentEntity> _allTournaments;

  @override
  void initState() {
    super.initState();
    _allTournaments = MockTournaments.getAll();
  }

  List<TournamentEntity> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.registrationOpen)
            .toList();
      case 2:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.upcoming)
            .toList();
      case 3:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.ongoing)
            .toList();
      case 4:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.finished)
            .toList();
      default:
        return _allTournaments;
    }
  }

  void _showTournamentDetail(TournamentEntity tournament) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TournamentDetailSheet(tournament: tournament),
    );
  }

  void _showNotificationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSmAll),
        content: const Text('Tính năng thông báo đang phát triển'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
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
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: IconButton(
                  tooltip: 'Thông báo',
                  onPressed: _showNotificationMessage,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
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
              background: _TournamentHero(
                totalCount: _allTournaments.length,
                openCount: _allTournaments
                    .where((t) => t.status == TournamentStatus.registrationOpen)
                    .length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khám phá giải đấu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filterLabels.length, (index) {
                        final selected = _selectedFilter == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(_filterLabels[index]),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedFilter = index),
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
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.chipRadius,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: filtered.isEmpty
            ? const TournamentEmptyState()
            : ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                      onTap: () => _showTournamentDetail(tournament),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _TournamentHero extends StatelessWidget {
  final int totalCount;
  final int openCount;

  const _TournamentHero({required this.totalCount, required this.openCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, AppColors.primaryDark, 0.35) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -24,
            child: _HeroOrb(
              size: 160,
              color: onPrimary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 72,
            right: 32,
            child: Icon(
              AppIcons.tournament,
              size: AppIcons.xxl,
              color: onPrimary.withValues(alpha: 0.18),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                88,
                68,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cạnh tranh. Kết nối. Chiến thắng.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tìm sân chơi phù hợp và viết nên thành tích của bạn.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPrimary.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _HeroMetric(
                        icon: AppIcons.tournament,
                        value: '$totalCount',
                        label: 'giải đấu',
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _HeroMetric(
                        icon: AppIcons.userCheck,
                        value: '$openCount',
                        label: 'đang mở',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIcons.sm, color: onPrimary.withValues(alpha: 0.8)),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: onPrimary.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TournamentDetailSheet extends StatelessWidget {
  final TournamentEntity tournament;

  const _TournamentDetailSheet({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRegister = tournament.status == TournamentStatus.registrationOpen;

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
        child: SingleChildScrollView(
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
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: AppSpacing.xxs,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: AppRadius.radiusFullAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.radiusMdAll,
                    ),
                    child: Icon(
                      AppIcons.tournament,
                      size: AppIcons.xl,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${tournament.gameName} · ${tournament.cafeName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailStatusPill(status: tournament.status),
              const SizedBox(height: AppSpacing.md),
              Container(
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
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Thông tin giải đấu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: AppRadius.radiusMdAll,
                ),
                child: Column(
                  children: [
                    _detailRow(
                      theme,
                      AppIcons.schedule,
                      'Bắt đầu',
                      _dateFmt.format(tournament.startDate),
                    ),
                    _detailRow(
                      theme,
                      AppIcons.schedule,
                      'Hạn đăng ký',
                      _dateFmt.format(tournament.registrationDeadline),
                    ),
                    _detailRow(
                      theme,
                      AppIcons.users,
                      'Người tham gia',
                      '${tournament.currentParticipants}/${tournament.maxParticipants}',
                    ),
                    if (tournament.requiresElo)
                      _detailRow(
                        theme,
                        AppIcons.elo,
                        'ELO tối thiểu',
                        '${tournament.minEloRequired}',
                      ),
                    if (tournament.entryFee != null && tournament.entryFee! > 0)
                      _detailRow(
                        theme,
                        AppIcons.cash,
                        'Phí tham gia',
                        '${_vnd(tournament.entryFee!)}đ',
                      )
                    else
                      _detailRow(
                        theme,
                        AppIcons.available,
                        'Phí tham gia',
                        'Miễn phí',
                      ),
                    if (tournament.prizePool > 0)
                      _detailRow(
                        theme,
                        AppIcons.level,
                        'Tổng giải thưởng',
                        '${_vnd(tournament.prizePool)}đ',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canRegister
                      ? () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.radiusSmAll,
                              ),
                              content: Text(
                                'Đã gửi yêu cầu đăng ký "${tournament.name}". Tính năng sẽ được kích hoạt khi backend sẵn sàng.',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(AppIcons.userCheck),
                  label: Text(
                    canRegister ? 'Đăng ký tham gia' : 'Hiện chưa mở đăng ký',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcons.sm, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _dateFmt = _DateFormat();

  String _vnd(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _DetailStatusPill extends StatelessWidget {
  final TournamentStatus status;

  const _DetailStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: AppIcons.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(ThemeData theme, TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return theme.colorScheme.secondary;
    case TournamentStatus.registrationOpen:
      return AppColors.success;
    case TournamentStatus.ongoing:
      return theme.colorScheme.primary;
    case TournamentStatus.finished:
      return theme.colorScheme.onSurfaceVariant;
  }
}

IconData _statusIcon(TournamentStatus status) {
  switch (status) {
    case TournamentStatus.upcoming:
      return AppIcons.pending;
    case TournamentStatus.registrationOpen:
      return AppIcons.userCheck;
    case TournamentStatus.ongoing:
      return Icons.play_circle_outline_rounded;
    case TournamentStatus.finished:
      return Icons.flag_outlined;
  }
}

class _DateFormat {
  String format(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
