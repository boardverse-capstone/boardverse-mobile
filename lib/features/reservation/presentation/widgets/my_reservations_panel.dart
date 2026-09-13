// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../domain/entities/entities.dart';
import '../cubit/my_reservations_cubit.dart';
import '../cubit/my_reservations_state.dart';
import '../pages/reservation_detail_page.dart';
import '../widgets/reservation_card_skeleton.dart';
import '../widgets/reservation_grid_card.dart';

/// Panel hiển thị danh sách reservation của user cho tab "Lịch đặt" —
/// sử dụng endpoint `GET /api/v1/reservations/my` (mới thêm Sep 2026).
///
/// **Layout:**
/// ```
/// ┌──────────────────────────────────────────────────┐
/// │ ┌────────────┬────────────┐                       │ ← Tab strip
/// │ │ CHỦ PHÒNG │ THÀNH VIÊN │                       │   "Chủ phòng (N)
/// │ │            │            │                       │    Thành viên (M)"
/// │ └────────────┴────────────┘                       │
/// ├──────────────────────────────────────────────────┤
/// │ ┌─ Filter chips row (status, date range) ─────┐ │
/// │ │ ▢Trạng thái  ▢Từ ngày  ▢Đến ngày          │ │
/// │ └────────────────────────────────────────────┘ │
/// ├──────────────────────────────────────────────────┤
/// │  ╔════════════════════════════════════════════╗ │
/// │  ║ Reservation card (host — orange border)    ║ │
/// │  ╚════════════════════════════════════════════╝ │
/// │  ╔════════════════════════════════════════════╗ │
/// │  ║ Reservation card (member — blue border)    ║ │
/// │  ╚════════════════════════════════════════════╝ │
/// └──────────────────────────────────────────────────┘
/// ```
///
/// **Visual distinction giữa Host vs Member:**
/// - Border card: Host → cam (primary), Member → xanh dương (info).
/// - Participation badge trên artwork cover: "CHỦ PHÒNG" (cam + crown icon)
///   vs "THÀNH VIÊN" (xanh + group icon).
///
/// Mục tiêu: player nhìn là biết ngay đâu là lịch hẹn do mình tạo, đâu là
/// lịch hẹn mình tham gia — không cần đọc text.
class MyReservationsPanel extends StatefulWidget {
  /// Padding bottom của list (để chừa chỗ cho FAB hoặc nav bar).
  final double listBottomPadding;

  /// Hiển thị header (title + actions). Mặc định `true`.
  final bool showTabStrip;

  const MyReservationsPanel({
    super.key,
    this.listBottomPadding = AppSpacing.xl,
    this.showTabStrip = true,
  });

  @override
  State<MyReservationsPanel> createState() => _MyReservationsPanelState();
}

class _MyReservationsPanelState extends State<MyReservationsPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Auto-load khi panel mount.
    Future.microtask(() {
      if (!mounted) return;
      context.read<MyReservationsCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MyReservationsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      child: Column(
        children: [
          if (widget.showTabStrip) _buildTabStrip(context),
          _buildFilterChips(context),
          const SizedBox(height: AppSpacing.xs),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  // ─── Tab strip "Chủ phòng (N) | Thành viên (M)" ──────────────

  Widget _buildTabStrip(BuildContext context) {
    return BlocBuilder<MyReservationsCubit, MyReservationsState>(
      buildWhen: (prev, curr) {
        // Re-render khi summary count hoặc active tab đổi.
        if (curr is MyReservationsLoaded) return true;
        if (curr is MyReservationsFailure) return true;
        if (curr is MyReservationsLoading) return true;
        return false;
      },
      builder: (context, state) {
        final cubit = context.read<MyReservationsCubit>();
        // Mặc định lấy active tab từ state; nếu initial thì lấy Host.
        // Quan trọng: đọc `activeTab` từ `MyReservationsLoading` nữa để
        // khi user vừa bấm chuyển tab, indicator highlight chuyển ngay —
        // không phải đợi API trả về mới cập nhật.
        final activeTab = state is MyReservationsLoaded
            ? state.activeTab
            : state is MyReservationsFailure
                ? state.activeTab
                : state is MyReservationsLoading
                    ? state.activeTab
                    : ReservationParticipationType.host;

        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: RoleTab(
                  type: ReservationParticipationType.host,
                  isActive: activeTab == ReservationParticipationType.host,
                  onTap: () => cubit.switchTab(ReservationParticipationType.host),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: RoleTab(
                  type: ReservationParticipationType.member,
                  isActive: activeTab == ReservationParticipationType.member,
                  onTap: () => cubit.switchTab(ReservationParticipationType.member),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Filter chips (Neo-brutalism) ────────────────────────────

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<MyReservationsCubit, MyReservationsState>(
      buildWhen: (prev, curr) {
        if (curr is MyReservationsLoaded) return true;
        if (curr is MyReservationsFailure) return true;
        return false;
      },
      builder: (context, _) {
        final cubit = context.read<MyReservationsCubit>();
        final state = cubit.state;
        final filter = state is MyReservationsLoaded
            ? state.filter
            : (state is MyReservationsFailure && state.filter != null
                ? state.filter!
                : MyReservationsFilter.empty);
        final hasAnyFilter = filter.hasAnyFilter;

        return SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            children: [
              _NeoFilterChip(
                icon: Icons.flag,
                label: filter.statuses != null && filter.statuses!.isNotEmpty
                    ? 'Trạng thái (${filter.statuses!.length})'
                    : 'Trạng thái',
                isActive:
                    filter.statuses != null && filter.statuses!.isNotEmpty,
                activeColor: AppColors.accent,
                foregroundColor: AppColors.black,
                onTap: () => _openStatusFilter(context),
                onClear:
                    filter.statuses != null && filter.statuses!.isNotEmpty
                        ? () => cubit.setStatuses(null)
                        : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _NeoFilterChip(
                icon: Icons.calendar_today,
                label: filter.fromDate != null
                    ? 'Từ ${DateFormatter.dateOnly(filter.fromDate!)}'
                    : 'Từ ngày',
                isActive: filter.fromDate != null,
                activeColor: AppColors.secondary,
                onTap: () => _pickFromDate(context),
                onClear: filter.fromDate != null
                    ? () => cubit.setDateRange(null, filter.toDate)
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _NeoFilterChip(
                icon: Icons.event,
                label: filter.toDate != null
                    ? 'Đến ${DateFormatter.dateOnly(filter.toDate!)}'
                    : 'Đến ngày',
                isActive: filter.toDate != null,
                activeColor: AppColors.secondary,
                onTap: () => _pickToDate(context),
                onClear: filter.toDate != null
                    ? () => cubit.setDateRange(filter.fromDate, null)
                    : null,
              ),
              if (hasAnyFilter) ...[
                const SizedBox(width: AppSpacing.xs),
                _NeoFilterClearButton(
                  onPressed: () => cubit.clearFilters(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final cubit = context.read<MyReservationsCubit>();
    final filter = cubit.state is MyReservationsLoaded
        ? (cubit.state as MyReservationsLoaded).filter
        : MyReservationsFilter.empty;

    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.fromDate != null && filter.fromDate!.isAfter(firstDate)
          ? filter.fromDate!
          : DateTime.now(),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked != null && context.mounted) {
      cubit.setDateRange(picked, filter.toDate);
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final cubit = context.read<MyReservationsCubit>();
    final filter = cubit.state is MyReservationsLoaded
        ? (cubit.state as MyReservationsLoaded).filter
        : MyReservationsFilter.empty;

    final firstDate =
        filter.fromDate ?? DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.toDate != null && filter.toDate!.isAfter(firstDate)
          ? filter.toDate!
          : firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày kết thúc',
    );
    if (picked != null && context.mounted) {
      cubit.setDateRange(filter.fromDate, picked);
    }
  }

  Future<void> _openStatusFilter(BuildContext context) async {
    final cubit = context.read<MyReservationsCubit>();
    final current = cubit.state;
    final initial = current is MyReservationsLoaded
        ? (current.filter.statuses ?? const <String>[])
        : const <String>[];

    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusFilterSheet(initial: initial),
    );
    if (selected != null && context.mounted) {
      cubit.setStatuses(selected);
    }
  }

  // ─── Results ──────────────────────────────────────────────────

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<MyReservationsCubit, MyReservationsState>(
      builder: (context, state) {
        // Wrap phần thân trong AnimatedSwitcher với FadeTransition để
        // chuyển đổi skeleton ↔ list mượt mà (đặc biệt khi switch tab:
        // skeleton hiện ngay → fade ra khi data về → fade in list mới).
        final child = _buildResultsContent(context, state);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      },
    );
  }

  /// Trả về widget cho state hiện tại — wrap trong ValueKey để
  /// AnimatedSwitcher nhận biết khi nào cần cross-fade.
  Widget _buildResultsContent(BuildContext context, MyReservationsState state) {
    if (state is MyReservationsInitial) {
      return _buildLoadingSkeleton(context, key: const ValueKey('skeleton-initial'));
    }
    if (state is MyReservationsLoading) {
      // Tab switch / filter change / refresh:
      // - Tab switch (cubit đã set previousItems = []) → skeleton ngay.
      // - Filter change (còn previousItems) → giữ list cũ + spinner dưới.
      if (state.previousItems.isEmpty) {
        return _buildLoadingSkeleton(
          context,
          key: const ValueKey('skeleton-loading'),
        );
      }
      return _buildItemsList(
        context,
        state.previousItems,
        isLoadMore: state.isLoadMore,
        hasNextPage: false,
        key: const ValueKey('list-paginating'),
      );
    }
    if (state is MyReservationsFailure) {
      if (state.previousItems.isNotEmpty) {
        return Column(
          key: const ValueKey('list-with-error-banner'),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.error,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Không tải được trang tiếp: ${state.message}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildItemsList(
                context,
                state.previousItems,
                isLoadMore: false,
                hasNextPage: false,
                key: const ValueKey('list-paginating'),
              ),
            ),
          ],
        );
      }
      return ErrorStateWidget(
        key: const ValueKey('error-state'),
        message: state.message,
        onRetry: () => context.read<MyReservationsCubit>().refresh(),
      );
    }
    if (state is MyReservationsLoaded) {
      if (state.items.isEmpty) {
        return _buildEmptyState(
          context,
          state,
          key: ValueKey('empty-${state.activeTab.name}-${state.filter.hashCode}'),
        );
      }
      return Column(
        key: ValueKey('list-loaded-${state.activeTab.name}-${state.filter.hashCode}'),
        children: [
          _buildResultSummary(context, state),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  context.read<MyReservationsCubit>().refresh(),
              child: _buildItemsList(
                context,
                state.items,
                isLoadMore: state.isLoadMore,
                hasNextPage: state.hasNextPage,
                key: const ValueKey('list-loaded-items'),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildLoadingSkeleton(BuildContext context, {Key? key}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 220,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const ReservationCardSkeleton(),
    );
  }

  Widget _buildResultSummary(BuildContext context, MyReservationsLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabLabel = state.activeTab == ReservationParticipationType.host
        ? 'CHỦ PHÒNG'
        : 'THÀNH VIÊN';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradientOrange,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: AppRadius.radiusXsAll,
              ),
              child: Icon(
                state.activeTab == ReservationParticipationType.host
                    ? Icons.workspace_premium_rounded
                    : Icons.groups_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tabLabel · ${state.totalItems} LỊCH HẸN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (state.totalPages > 1)
                    Text(
                      'Trang ${state.page}/${state.totalPages}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    MyReservationsLoaded state, {
    Key? key,
  }) {
    final isHost = state.activeTab == ReservationParticipationType.host;
    final hasFilter = state.filter.hasAnyFilter;

    if (hasFilter) {
      // Có filter nhưng không có data → "Không tìm thấy".
      return EmptyStateWidget(
        key: key,
        icon: Icons.search_off,
        title: 'KHÔNG TÌM THẤY',
        message:
            'Không có lịch hẹn nào khớp với bộ lọc hiện tại. Thử nới lỏng điều kiện lọc.',
        compact: true,
      );
    }

    return EmptyStateWidget(
      key: key,
      icon: isHost
          ? Icons.event_available_outlined
          : Icons.group_outlined,
      title: isHost ? 'CHƯA CÓ LỊCH HẸN DO BẠN TẠO' : 'CHƯA THAM GIA LỊCH HẸN NÀO',
      message: isHost
          ? 'Bạn chưa tạo lịch hẹn nào. Hãy tạo phòng chờ đầu tiên để mời bạn bè cùng chơi.'
          : 'Bạn chưa tham gia lịch hẹn nào. Hãy khám phá các phòng chờ đang mở và tham gia ngay.',
      compact: true,
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<ReservationEntity> items, {
    required bool isLoadMore,
    required bool hasNextPage,
    Key? key,
  }) {
    // Sắp xếp: hoạt động trước, sau đó theo scheduledTime giảm dần.
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
      key: key,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ).copyWith(bottom: widget.listBottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 220,
      ),
      itemCount: sorted.length + (hasNextPage || isLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sorted.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        final r = sorted[index];
        return ReservationCardModern(
          reservation: r,
          // `isOwnedByMe` ở đây vẫn dùng để trigger border đậm — với
          // tab Host (chỉ trả về reservation do mình host) → đều true.
          // Với tab Member (chỉ trả về reservation mình tham gia) → false.
          isOwnedByMe: r.isUserHost,
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

// ═══════════════════════════════════════════════════════════════════════
// ROLE TAB — neo-brutalism pill với count badge
// ═══════════════════════════════════════════════════════════════════════

class RoleTab extends StatefulWidget {
  final ReservationParticipationType type;
  final bool isActive;
  final VoidCallback onTap;

  const RoleTab({
    super.key,
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<RoleTab> createState() => _RoleTabState();
}

class _RoleTabState extends State<RoleTab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHost = widget.type == ReservationParticipationType.host;

    // Host: cam (primary). Member: xanh dương (info).
    final activeColor = isHost ? AppColors.primary : AppColors.info;
    final inactiveFg = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    final label = isHost ? 'CHỦ PHÒNG' : 'THÀNH VIÊN';
    final icon = isHost
        ? Icons.workspace_premium_rounded
        : Icons.groups_rounded;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeColor
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: widget.isActive
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isActive
                ? NeoBrutalismTheme.lightShadow(
                    bold: true,
                    shadowColor: activeColor.withValues(alpha: 0.4),
                  )
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: widget.isActive ? Colors.white : inactiveFg,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: widget.isActive ? Colors.white : inactiveFg,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FILTER CHIPS (neo-brutalism) — shared styling với search panel
// ═══════════════════════════════════════════════════════════════════════

class _NeoFilterChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color? foregroundColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _NeoFilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.onClear,
    this.foregroundColor,
  });

  @override
  State<_NeoFilterChip> createState() => _NeoFilterChipState();
}

class _NeoFilterChipState extends State<_NeoFilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = widget.foregroundColor ??
        (widget.isActive ? Colors.white : AppColors.textPrimary);
    final bg = widget.isActive
        ? widget.activeColor
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.chipRadius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isActive
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: widget.activeColor.withValues(alpha: 0.4),
                  )
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                if (widget.onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 12, color: fg),
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
}

class _NeoFilterClearButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _NeoFilterClearButton({required this.onPressed});

  @override
  State<_NeoFilterClearButton> createState() => _NeoFilterClearButtonState();
}

class _NeoFilterClearButtonState extends State<_NeoFilterClearButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.chipRadius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.filter_alt_off, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'Xóa lọc',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATUS FILTER SHEET — neo-brutalism
// ═══════════════════════════════════════════════════════════════════════

class _StatusFilterSheet extends StatefulWidget {
  final List<String> initial;

  const _StatusFilterSheet({required this.initial});

  @override
  State<_StatusFilterSheet> createState() => _StatusFilterSheetState();
}

class _StatusFilterSheetState extends State<_StatusFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allStatuses = ReservationStatus.values
        .where((s) => s != ReservationStatus.draft)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: AppRadius.bottomSheetRadius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              bold: true,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: AppRadius.radiusXsAll,
                      border: Border.all(
                        color:
                            isDark ? AppColors.borderDark : AppColors.border,
                        width: NeoBrutalismTheme.borderWidth,
                      ),
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: AppColors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'LỌC THEO TRẠNG THÁI',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: allStatuses.map((s) {
                  final isSelected = _selected.contains(s.name);
                  return _SheetChip(
                    label: s.displayName,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(s.name);
                        } else {
                          _selected.add(s.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'BỎ LỌC',
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(<String>[]),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'ÁP DỤNG',
                      icon: Icons.check,
                      color: AppColors.primary,
                      onPressed: () =>
                          Navigator.of(context).pop(_selected.toList()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Shared neo-brutalism button primitives (subset)
// ═══════════════════════════════════════════════════════════════════════

class _SheetChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SheetChip> createState() => _SheetChipState();
}

class _SheetChipState extends State<_SheetChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.isSelected
        ? AppColors.accent
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.chipRadius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isSelected
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.accent.withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: widget.isSelected
                  ? AppColors.black
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoFilledButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_NeoFilledButton> createState() => _NeoFilledButtonState();
}

class _NeoFilledButtonState extends State<_NeoFilledButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: widget.color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 16),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoOutlineButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_NeoOutlineButton> createState() => _NeoOutlineButtonState();
}

class _NeoOutlineButtonState extends State<_NeoOutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}