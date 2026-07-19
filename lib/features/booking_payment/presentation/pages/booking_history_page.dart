import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/pages/bookings_page.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../cubit/booking_result_cubit.dart';
import '../cubit/booking_result_state.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/no_show_badge.dart';
import '../widgets/status_pill.dart';
import 'booking_detail_page.dart';

/// Trang lịch hẹn của user — có 2 tab: Sắp tới + Lịch sử.
class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  late final BookingResultCubit _cubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<BookingResultCubit>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    BookingRefreshSignal.instance.addListener(_onRefreshRequested);
    _loadData();
  }

  void _loadData() {
    _cubit.loadUpcomingAndHistory();
  }

  void _onRefreshRequested() {
    if (!mounted) return;
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    BookingRefreshSignal.instance.removeListener(_onRefreshRequested);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          Material(
            color: theme.appBarTheme.backgroundColor ??
                theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Sắp tới'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<BookingResultCubit, BookingResultState>(
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _UpcomingTab(
                      state: state,
                      onRefresh: () {
                        _cubit.loadUpcomingAndHistory();
                        return Future.value();
                      },
                      onChanged: _cubit.loadUpcomingBookings,
                    ),
                    _HistoryTab(
                      state: state,
                      onRefresh: () {
                        _cubit.loadUpcomingAndHistory();
                        return Future.value();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab: Các booking sắp tới (pending + confirmed + checkedIn + cancelled).
class _UpcomingTab extends StatelessWidget {
  final BookingResultState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChanged;

  const _UpcomingTab({
    required this.state,
    required this.onRefresh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (state is ResultLoading) {
      return _LoadingState();
    }

    final List<BookingEntity> upcomingBookings;
    if (state is ResultUpcomingBookings) {
      upcomingBookings = (state as ResultUpcomingBookings).bookings;
    } else if (state is ResultUpcomingAndHistory) {
      upcomingBookings = (state as ResultUpcomingAndHistory).upcoming;
    } else {
      upcomingBookings = const <BookingEntity>[];
    }

    if (upcomingBookings.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Chưa có lịch hẹn nào',
        message:
            'Bạn chưa có đơn đặt chỗ nào sắp tới. Hãy khám phá các quán và tạo lobby để bắt đầu!',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: upcomingBookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final booking = upcomingBookings[i];
          return _UpcomingBookingCard(
            booking: booking,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

/// Card tóm tắt booking — tap để mở trang chi tiết.
/// Hiển thị: icon + game + quán + giờ + số ghế + trạng thái + chevron.
class _UpcomingBookingCard extends StatelessWidget {
  final BookingEntity booking;
  final Future<void> Function() onChanged;

  const _UpcomingBookingCard({
    required this.booking,
    required this.onChanged,
  });

  IconData _statusIcon() {
    switch (booking.status.name) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'checkedIn':
        return Icons.sports_esports_rounded;
      case 'pendingDeposit':
        return Icons.hourglass_top_rounded;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _statusColor() {
    switch (booking.status.name) {
      case 'confirmed':
        return AppColors.info;
      case 'checkedIn':
        return AppColors.success;
      case 'pendingDeposit':
        return AppColors.warning;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _openDetail(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(booking: booking),
      ),
    );

    if (result == true) {
      await onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _statusColor();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.cardRadius,
      elevation: 0,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: AppRadius.cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: AppElevation.shadowXxs,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent strip + status pill
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.9),
                        accent.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: AppRadius.radiusSmAll,
                            ),
                            child: Icon(
                              _statusIcon(),
                              color: accent,
                              size: AppIcons.lg,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.gameName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      AppIcons.location,
                                      size: AppIcons.sm,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        booking.cafeName,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _MetaItem(
                              icon: AppIcons.clock,
                              label: BookingUiHelpers.formatDateTime(
                                booking.scheduledTime,
                                pattern: 'HH:mm • dd/MM',
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: _MetaItem(
                              icon: AppIcons.users,
                              label: '${booking.seatCount} người',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: _MetaItem(
                              icon: AppIcons.money,
                              label:
                                  BookingUiHelpers.formatVnd(booking.depositAmount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          label: BookingUiHelpers.labelFromStringName(
                              booking.status.name),
                          variant: BookingUiHelpers.variantFromStringName(
                              booking.status.name),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab: Lịch sử booking (đã qua).
class _HistoryTab extends StatelessWidget {
  final BookingResultState state;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (state is ResultLoading) {
      return _LoadingState();
    }

    final List<BookingHistoryEntity> historyItems;
    if (state is ResultHistory) {
      historyItems = (state as ResultHistory).items;
    } else if (state is ResultUpcomingAndHistory) {
      historyItems = (state as ResultUpcomingAndHistory).history;
    } else {
      historyItems = const <BookingHistoryEntity>[];
    }

    if (historyItems.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: 'Chưa có lịch sử đặt chỗ',
        message: 'Các phiên chơi đã hoàn tất sẽ xuất hiện ở đây.',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: historyItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) => _HistoryCard(item: historyItems[i]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BookingHistoryEntity item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: () {
          // History items are read-only; no detail page jump.
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: AppRadius.radiusSmAll,
                      ),
                      child: Icon(
                        AppIcons.boardGame,
                        color: theme.colorScheme.primary,
                        size: AppIcons.lg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.gameName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                AppIcons.location,
                                size: AppIcons.sm,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.cafeName,
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: BookingUiHelpers.historyLabel(item.status),
                      variant: BookingUiHelpers.historyVariant(item.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: AppRadius.radiusXsAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.clock,
                        size: AppIcons.sm,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        BookingUiHelpers.formatDateTime(
                          item.scheduledTime,
                          pattern: 'HH:mm • dd/MM/yyyy',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        AppIcons.money,
                        size: AppIcons.sm,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        BookingUiHelpers.formatVnd(item.depositAmount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.hasNoShowBadge) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: NoShowBadge(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small label + icon — dùng trong row meta của card.
class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: AppIcons.sm,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading state dùng shimmer placeholders.
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => AppShimmer.listItem(context: context),
    );
  }
}

/// Empty state đồng nhất theo design system.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.huge),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppIcons.xxl,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
