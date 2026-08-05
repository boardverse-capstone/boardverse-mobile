import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../cubit/booking_history_cubit.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/no_show_badge.dart';
import '../widgets/status_pill.dart';
import 'booking_detail_page.dart';

/// Trang lịch hẹn của user — 2 tab: Sắp tới + Lịch sử.
///
/// Body-only widget (`BookingHistoryPageContent`) để có thể nhúng từ
/// `BookingsPage` (kèm banner resume). Wrapper `BookingHistoryPage` cũ
/// đã được xoá khi tab Bookings chuyển sang dùng Reservation API +
/// `MyLobbiesCubit` (không còn `BookingRefreshSignal`).
///
/// Body của `BookingHistoryPage` — dùng [BookingHistoryCubit] từ context.
class BookingHistoryPageContent extends StatelessWidget {
  final BookingHistoryState? state;
  final Future<void> Function()? onRefresh;

  /// Khi != null, hiển thị 1 tab duy nhất "Lịch quán" (gap #14).
  /// Khi null, hiển thị 2 tab Sắp tới + Lịch sử (mặc định).
  final String? cafeViewCafeId;

  const BookingHistoryPageContent({
    super.key,
    this.state,
    this.onRefresh,
    this.cafeViewCafeId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
      builder: (context, current) {
        final effectiveState = state ?? current;
        Future<void> Function() refresh;
        if (onRefresh != null) {
          refresh = onRefresh!;
        } else {
          final cubit = context.read<BookingHistoryCubit>();
          // Chọn loadForCafe nếu cafeViewCafeId có giá trị.
          if (cafeViewCafeId != null) {
            refresh = () => cubit.loadForCafe(cafeViewCafeId!);
          } else {
            refresh = cubit.loadAll;
          }
        }

        // TabBarView bắt buộc phải có `controller` (explicit) hoặc
        // tìm được `DefaultTabController` trong scope. Page content này
        // được nhúng từ nhiều nơi (standalone page, BookingsPage với
        // banner, ...), không phải lúc nào cũng có controller sẵn →
        // wrap với `DefaultTabController` để TabBarView hoạt động độc lập.
        return DefaultTabController(
          length: cafeViewCafeId != null ? 1 : 2,
          child: Builder(
            builder: (context) {
              // Cafe view mode (gap #14) — 1 tab.
              if (cafeViewCafeId != null) {
                return TabBarView(
                  children: [
                    _CafeViewTab(
                      state: effectiveState,
                      onRefresh: refresh,
                      cafeId: cafeViewCafeId!,
                    ),
                  ],
                );
              }

              return TabBarView(
                children: [
                  _UpcomingTab(state: effectiveState, onRefresh: refresh),
                  _HistoryTab(state: effectiveState, onRefresh: refresh),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Tab "Lịch quán" cho Player (gap #14) — render summary rút gọn.
class _CafeViewTab extends StatelessWidget {
  final BookingHistoryState? state;
  final Future<void> Function()? onRefresh;
  final String cafeId;

  const _CafeViewTab({
    required this.state,
    required this.onRefresh,
    required this.cafeId,
  });

  @override
  Widget build(BuildContext context) {
    if (state == null || state is BookingHistoryLoading) {
      return const _LoadingState();
    }
    if (state is BookingHistoryFailure) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được lịch quán',
        message: (state as BookingHistoryFailure).message,
        onRefresh: onRefresh ?? () async {},
      );
    }
    if (state is BookingHistoryLoaded) {
      final list = (state as BookingHistoryLoaded).cafeView;
      if (list.isEmpty) {
        return _EmptyState(
          icon: Icons.event_busy_rounded,
          title: 'Quán chưa có lịch',
          message: 'Hiện tại quán này không có booking công khai nào.',
          onRefresh: onRefresh ?? () async {},
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) await onRefresh!();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, index) {
            final b = list[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.event_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  '${b.scheduledStartTime.hour}:${b.scheduledStartTime.minute.toString().padLeft(2, '0')} '
                  '→ ${b.scheduleEndTime.hour}:${b.scheduleEndTime.minute.toString().padLeft(2, '0')}',
                ),
                subtitle: Text('${b.playerQuantity} người'),
                trailing: StatusPill(
                  label: BookingUiHelpers.statusToLabel(b.status),
                  variant: BookingUiHelpers.statusToVariant(b.status),
                ),
              ),
            );
          },
        ),
      );
    }
    return const _LoadingState();
  }
}

class _UpcomingTab extends StatelessWidget {
  final BookingHistoryState? state;
  final Future<void> Function()? onRefresh;

  const _UpcomingTab({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const _LoadingState();
    }
    if (state is BookingHistoryLoading) {
      return const _LoadingState();
    }

    final List<BookingEntity> upcomingBookings;
    if (state is BookingHistoryLoaded) {
      upcomingBookings = (state as BookingHistoryLoaded).upcoming;
    } else {
      upcomingBookings = const <BookingEntity>[];
    }

    Future<void> Function() refresh =
        onRefresh ?? () => context.read<BookingHistoryCubit>().loadAll();

    if (upcomingBookings.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Chưa có lịch hẹn nào',
        message:
            'Bạn chưa có đơn đặt chỗ nào sắp tới. Hãy khám phá các quán và tạo lobby để bắt đầu!',
        onRefresh: refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
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
          return _UpcomingBookingCard(booking: booking, onChanged: refresh);
        },
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final BookingEntity booking;
  final Future<void> Function() onChanged;

  const _UpcomingBookingCard({required this.booking, required this.onChanged});

  IconData _statusIcon() {
    switch (booking.status.name) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'checkedIn':
        return Icons.sports_esports_rounded;
      case 'pendingDeposit':
        return Icons.hourglass_top_rounded;
      case 'cancelled':
      case 'noShow':
        return Icons.cancel_rounded;
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
      case 'cancelled':
      case 'noShow':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _openDetail(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
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
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
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
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          Expanded(
                            child: _MetaItem(
                              icon: AppIcons.money,
                              label: BookingUiHelpers.formatVnd(
                                booking.depositAmount,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          label: BookingUiHelpers.statusToLabel(booking.status),
                          variant: BookingUiHelpers.statusToVariant(
                            booking.status,
                          ),
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

class _HistoryTab extends StatelessWidget {
  final BookingHistoryState? state;
  final Future<void> Function()? onRefresh;

  const _HistoryTab({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const _LoadingState();
    }
    if (state is BookingHistoryLoading) {
      return const _LoadingState();
    }

    final List<BookingHistoryEntity> historyItems;
    if (state is BookingHistoryLoaded) {
      historyItems = (state as BookingHistoryLoaded).history;
    } else {
      historyItems = const <BookingHistoryEntity>[];
    }

    Future<void> Function() refresh =
        onRefresh ?? () => context.read<BookingHistoryCubit>().loadAll();

    if (historyItems.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: 'Chưa có lịch sử đặt chỗ',
        message: 'Các phiên chơi đã hoàn tất sẽ xuất hiện ở đây.',
        onRefresh: refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
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

  BookingStatus get _baseStatus {
    switch (item.status) {
      case BookingStatus.cancelled:
        return BookingStatus.cancelled;
      case BookingStatus.noShow:
        return BookingStatus.noShow;
      case BookingStatus.checkedIn:
        return BookingStatus.checkedIn;
      default:
        return BookingStatus.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: () {},
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
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.6,
                        ),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                      label: BookingUiHelpers.statusToLabel(_baseStatus),
                      variant: BookingUiHelpers.statusToVariant(_baseStatus),
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
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
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
                if (item.status == BookingStatus.noShow) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Align(
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
        Icon(icon, size: AppIcons.sm, color: theme.colorScheme.primary),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

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
