import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/reservation_list_cubit.dart';
import '../cubit/reservation_list_state.dart';
import 'reservation_detail_page.dart';

/// Trang danh sách reservation của player — dùng trong tab "Lịch đặt".
///
/// Tách ra từ `core/navigation/pages/bookings_page.dart` để UI thuộc về
/// feature `reservation`. Page này chỉ hiển thị reservation; lobby list
/// vẫn do `bookings_page.dart` quản lý (vì đó là UI của lobby_management).
///
/// API: `GET /api/v1/reservations` với filter `hostedByMe` / `joinedByMe`.
class ReservationListPage extends StatelessWidget {
  /// `hostedByMeOnly`: true → chỉ reservation user host; null/false → tất cả.
  /// `title`: tiêu đề section hiển thị phía trên.
  const ReservationListPage({
    super.key,
    this.hostedByMeOnly = true,
    this.title = 'Lịch đặt của tôi',
    this.subtitle = 'Các đơn reservation đã tạo qua BVC',
  });

  final bool? hostedByMeOnly;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationListCubit>(
      create: (_) => ReservationListCubit(
        repository: sl<ReservationRepository>(),
      )..load(hostedByMe: hostedByMeOnly),
      child: _ReservationListView(title: title, subtitle: subtitle),
    );
  }
}

class _ReservationListView extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ReservationListView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(Icons.event_note,
                    color: colors.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(Icons.refresh),
                onPressed: () => context
                    .read<ReservationListCubit>()
                    .refresh(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<ReservationListCubit, ReservationListState>(
          builder: (context, state) {
            if (state is ReservationListLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is ReservationListFailure) {
              return _ErrorBox(message: state.message);
            }
            if (state is ReservationListLoaded) {
              final items = state.items;
              if (items.isEmpty) {
                return _EmptyBox(
                  icon: Icons.event_busy,
                  message: 'Bạn chưa tạo đơn reservation nào.',
                );
              }
              return Column(
                children: [
                  for (final r in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReservationCard(reservation: r),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final time = DateFormat('HH:mm • dd/MM')
        .format(reservation.scheduledTime.toLocal());
    final statusColor = _statusColor(colors, reservation.status);
    return InkWell(
      borderRadius: AppRadius.radiusMdAll,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationDetailPage(reservation: reservation),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: colors.outlineVariant),
          boxShadow: AppElevation.shadowSm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.gameName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusFullAll,
                  ),
                  child: Text(
                    reservation.status.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(icon: Icons.storefront, text: reservation.cafeName),
            _InfoRow(icon: Icons.schedule, text: time),
            _InfoRow(
              icon: Icons.confirmation_number,
              text: 'Cọc: ${reservation.finalDeposit} BVC',
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme colors, ReservationStatus status) {
    if (status.isTerminal) return colors.error;
    if (status.isActive) return colors.primary;
    return AppColors.warning;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}