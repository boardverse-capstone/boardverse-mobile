import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/reservation_list_cubit.dart';
import '../cubit/reservation_list_state.dart';
import '../widgets/reservation_card_skeleton.dart';
import '../widgets/reservation_grid_card.dart';
import 'reservation_detail_page.dart';
import 'reservation_search_page.dart';

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
              tooltip: 'Tìm kiếm',
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReservationSearchPage(),
                  ),
                );
              },
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
            return ErrorStateWidget(
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

    // Wrap với RefreshIndicator để pull-to-refresh
    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) header(),
          if (showHeader) const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await context.read<ReservationListCubit>().refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content(),
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        if (showHeader) header(),
        if (showHeader) const SizedBox(height: AppSpacing.sm),
        RefreshIndicator(
          onRefresh: () async {
            await context.read<ReservationListCubit>().refresh();
          },
          child: content(),
        ),
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
      return const ReservationEmptyState(
        customTitle: 'CHƯA CÓ LỊCH HẸN',
        customMessage: 'Bạn chưa tạo đơn reservation nào.\nHãy tạo lịch hẹn mới để bắt đầu.',
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 220,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final r = sorted[i];
        return ReservationCardModern(
          reservation: r,
          isOwnedByMe: r.isHost ?? false,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReservationDetailPage(reservation: r),
            ),
          ),
        );
      },
    );
  }
}