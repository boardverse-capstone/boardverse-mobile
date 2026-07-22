import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import 'booking_ui_helpers.dart';
import 'no_show_badge.dart';
import 'status_pill.dart';

/// Card tóm tắt một booking sắp tới.
///
/// Dùng ở:
/// - `BookingHistoryPage` (tab "Sắp tới").
/// - `NearbyLobbiesPage` (section "Đặt chỗ của tôi") trong Discovery.
///
/// Tap → mở [BookingDetailPage] (xem `booking_detail_page.dart`). Caller
/// truyền callback `onChanged` để refresh list khi detail page trả về true
/// (vd: sau khi huỷ booking).
class UpcomingBookingSummaryCard extends StatelessWidget {
  final BookingEntity booking;
  final Future<void> Function() onChanged;

  /// Builder mở trang detail. Mặc định dùng `BookingDetailPage`. Cho phép
  /// override để tránh import vòng tròn khi dùng ở page khác.
  final Widget Function(BuildContext, BookingEntity)? detailPageBuilder;

  const UpcomingBookingSummaryCard({
    super.key,
    required this.booking,
    required this.onChanged,
    this.detailPageBuilder,
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

  Future<void> _openDetail(BuildContext context) async {
    final builder = detailPageBuilder;
    if (builder == null) {
      // Không có builder → fallback: thử dynamic import để tránh vòng lặp.
      // Caller luôn nên truyền detailPageBuilder để đảm bảo compile-time.
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => builder(ctx, booking)),
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
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        booking.cafeName,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
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
                          label: BookingUiHelpers.labelFromStringName(
                            booking.status.name,
                          ),
                          variant: BookingUiHelpers.variantFromStringName(
                            booking.status.name,
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

/// Card tóm tắt booking đã qua (read-only).
///
/// Dùng ở:
/// - `BookingHistoryPage` (tab "Lịch sử").
/// - `NearbyLobbiesPage` (section "Lịch sử đặt chỗ") trong Discovery.
class HistoryBookingSummaryCard extends StatelessWidget {
  final BookingHistoryEntity item;

  const HistoryBookingSummaryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: () {
          // Read-only — không có detail page.
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
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
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
                      if (item.hasNoShowBadge) const NoShowBadge(),
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

/// Meta item (icon + text) — dùng nội bộ trong card.
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
        Icon(icon, size: AppIcons.sm, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
