import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/reservation_list_cubit.dart';
import '../cubit/reservation_list_state.dart';
import '../widgets/reservation_card.dart';
import '../widgets/reservation_card_skeleton.dart';
import 'reservation_detail_page.dart';

/// Trang / tab danh sách reservation của player.
///
/// Tách ra từ `core/navigation/pages/bookings_page.dart` để UI thuộc về
/// feature `reservation`. Có thể nhúng vào bất kỳ page nào (tab,
/// sub-page) thông qua widget `ReservationListView` — nó tự cung cấp
/// cubit riêng và quản lý state.
///
/// API: `GET /api/v1/reservations` với filter `hostedByMe` / `joinedByMe`.
class ReservationListPage extends StatelessWidget {
  /// `hostedByMeOnly`: true → chỉ reservation user host; null/false → tất cả.
  /// `title`: tiêu đề section hiển thị phía trên.
  /// `scrollable`: nếu `false`, danh sách sẽ không tự cuộn (dùng khi nhúng
  ///   vào `TabBarView` — outer scroll sẽ cuộn thay).
  const ReservationListPage({
    super.key,
    this.hostedByMeOnly = true,
    this.title = 'Lịch đặt của tôi',
    this.subtitle = 'Các đơn reservation đã tạo qua BVC',
    this.scrollable = true,
  });

  final bool? hostedByMeOnly;
  final String title;
  final String subtitle;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationListCubit>(
      create: (_) => ReservationListCubit(
        repository: sl<ReservationRepository>(),
      )..load(hostedByMe: hostedByMeOnly),
      child: ReservationListView(
        title: title,
        subtitle: subtitle,
        scrollable: scrollable,
      ),
    );
  }
}

/// View widget — không tự tạo cubit, dùng cubit có sẵn trong context.
///
/// Dùng khi page cha đã cung cấp cubit (ví dụ qua `MultiBlocProvider`),
/// hoặc khi cần test với cubit giả.
class ReservationListView extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool scrollable;
  final bool showHeader;

  const ReservationListView({
    super.key,
    this.title = 'Lịch đặt của tôi',
    this.subtitle = 'Các đơn reservation đã tạo qua BVC',
    this.scrollable = true,
    this.showHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget header() {
      if (!showHeader) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: AppRadius.radiusSmAll,
              ),
              child: Icon(
                Icons.event_note,
                color: colors.onPrimaryContainer,
                size: 20,
              ),
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
              onPressed: () => context.read<ReservationListCubit>().refresh(),
            ),
          ],
        ),
      );
    }

    Widget content() {
      return BlocBuilder<ReservationListCubit, ReservationListState>(
        builder: (context, state) {
          if (state is ReservationListLoading) {
            return _buildSkeleton(context);
          }
          if (state is ReservationListFailure) {
            return _ErrorBox(
              message: state.message,
              onRetry: () => context.read<ReservationListCubit>().refresh(),
            );
          }
          if (state is ReservationListLoaded) {
            return _buildLoaded(context, state.items);
          }
          return const SizedBox.shrink();
        },
      );
    }

    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) header(),
          if (showHeader) const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: content(),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        if (showHeader) header(),
        if (showHeader) const SizedBox(height: AppSpacing.sm),
        content(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: ReservationCardSkeleton(),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<ReservationEntity> items) {
    if (items.isEmpty) {
      return const _EmptyBox(
        icon: Icons.event_busy,
        message: 'Bạn chưa tạo đơn reservation nào.',
      );
    }
    // Sắp xếp: hoạt động trước, sau đó theo thời gian scheduledTime giảm dần.
    final sorted = [...items]..sort((a, b) {
        final aActive = a.status.isActive ||
            (a.lobbyStatus?.isActive ?? false);
        final bActive = b.status.isActive ||
            (b.lobbyStatus?.isActive ?? false);
        if (aActive != bActive) {
          return aActive ? -1 : 1;
        }
        return b.scheduledTime.compareTo(a.scheduledTime);
      });

    return Column(
      children: [
        for (final r in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ReservationCard(
              reservation: r,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReservationDetailPage(reservation: r),
                ),
              ),
            ),
          ),
      ],
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
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.3),
        ),
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
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                foregroundColor: colors.onErrorContainer,
              ),
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}