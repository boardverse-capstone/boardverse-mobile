// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/entities.dart';
import '../cubit/search_reservations_cubit.dart';
import '../cubit/search_reservations_state.dart';
import '../pages/reservation_detail_page.dart';
import '../widgets/reservation_card_skeleton.dart';
import '../widgets/reservation_grid_card.dart';

/// Widget kết hợp search bar + filter chips + danh sách kết quả
/// cho `SearchReservationsCubit` — Neo-Brutalism style.
///
/// Dùng làm nội dung chính của tab "Lịch đặt" trong BookingsPage.
///
/// **Layout:**
/// ```
/// ┌─────────────────────────────────────┐
/// │  ╔════════════════════════════════╗ │  ← Neo-brutalism search bar
/// │  ║ 🔍 [Tìm theo tên game...]     ║ │     (border 3px + hard shadow)
/// │  ╚════════════════════════════════╝ │
/// ├─────────────────────────────────────┤
/// │  ▢Từ ngày ▢Đến ngày ▢Trạng thái ▢ │  ← Neo filter chips
/// │  Phạm vi                            │     (press animation)
/// ├─────────────────────────────────────┤
/// │ ╔═══ Tìm thấy N kết quả ════════╗ │  ← Result summary banner
/// │ ║ Trang X/Y                       ║ │
/// │ ╚══════════════════════════════════╝ │
/// ├─────────────────────────────────────┤
/// │ ┌─ Reservation card (neo-brutalism)┐│
/// │ ┌─ Reservation card                 ┐│
/// │ ┌─ Reservation card                 ┐│
/// └─────────────────────────────────────┘
/// ```
class ReservationSearchPanel extends StatefulWidget {
  /// Hiển thị header tóm tắt "Tìm thấy N kết quả". Mặc định `true`.
  final bool showResultSummary;

  /// Padding bottom của list (để chừa chỗ cho FAB hoặc nav bar).
  final double listBottomPadding;

  const ReservationSearchPanel({
    super.key,
    this.showResultSummary = true,
    this.listBottomPadding = AppSpacing.xl,
  });

  @override
  State<ReservationSearchPanel> createState() => _ReservationSearchPanelState();
}

class _ReservationSearchPanelState extends State<ReservationSearchPanel> {
  final TextEditingController _gameNameController = TextEditingController();
  final FocusNode _gameNameFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Sync controller text với cubit query hiện tại.
    final cubit = context.read<SearchReservationsCubit>();
    _gameNameController.text = cubit.currentQuery.gameName ?? '';
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _gameNameFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchReservationsCubit>().loadMore();
    }
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final cubit = context.read<SearchReservationsCubit>();
    final currentFrom = cubit.currentQuery.fromDate;
    final currentTo = cubit.currentQuery.toDate;

    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: currentFrom != null && currentFrom.isAfter(firstDate)
          ? currentFrom
          : DateTime.now(),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked != null) {
      cubit.setDateRange(picked, currentTo);
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final cubit = context.read<SearchReservationsCubit>();
    final currentFrom = cubit.currentQuery.fromDate;
    final currentTo = cubit.currentQuery.toDate;

    final firstDate =
        currentFrom ?? DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: currentTo != null && currentTo.isAfter(firstDate)
          ? currentTo
          : firstDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày kết thúc',
    );
    if (picked != null) {
      cubit.setDateRange(currentFrom, picked);
    }
  }

  Future<void> _openStatusFilter(BuildContext context) async {
    final cubit = context.read<SearchReservationsCubit>();
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusFilterSheet(
        initial: cubit.currentQuery.statuses ?? const [],
      ),
    );
    if (selected != null) {
      cubit.setStatuses(selected);
    }
  }

  Future<void> _openScopeFilter(BuildContext context) async {
    final cubit = context.read<SearchReservationsCubit>();
    final scope = await showModalBottomSheet<SearchScope>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScopeFilterSheet(initial: cubit.currentQuery.scope),
    );
    if (scope != null) {
      cubit.setScope(scope);
    }
  }

  void _clearAll(BuildContext context) {
    _gameNameController.clear();
    context.read<SearchReservationsCubit>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      child: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          const SizedBox(height: AppSpacing.xs),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  // ─── Search bar (Neo-brutalism) ──────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalismTheme.borderWidthBold,
          ),
          boxShadow: NeoBrutalismTheme.lightShadow(
            bold: true,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Search icon đầu dòng — icon badge neo-brutalism
            Container(
              margin: const EdgeInsets.all(AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.radiusSmAll,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidth,
                ),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
            // TextField
            Expanded(
              child: TextField(
                controller: _gameNameController,
                focusNode: _gameNameFocus,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên game (vd: Catan, Splendor)',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  context.read<SearchReservationsCubit>().setGameName(value);
                  setState(() {});
                },
                onSubmitted: (_) => _gameNameFocus.unfocus(),
              ),
            ),
            // Clear button
            if (_gameNameController.text.isNotEmpty)
              _NeoIconButton(
                icon: Icons.close,
                onPressed: () {
                  _gameNameController.clear();
                  context.read<SearchReservationsCubit>().setGameName('');
                  setState(() {});
                },
                color: AppColors.error,
                tooltip: 'Xóa',
              ),
            const SizedBox(width: AppSpacing.xxs),
          ],
        ),
      ),
    );
  }

  // ─── Filter chips (Neo-brutalism) ────────────────────────────────

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<SearchReservationsCubit, SearchReservationsState>(
      buildWhen: (prev, curr) {
        if (curr is SearchReservationsLoaded) return true;
        if (curr is SearchReservationsFailure) return true;
        if (curr is SearchReservationsInitial) return true;
        return false;
      },
      builder: (context, _) {
        final cubit = context.read<SearchReservationsCubit>();
        final query = cubit.currentQuery;
        final hasAnyFilter = query.hasAnyFilter;

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
                icon: Icons.calendar_today,
                label: query.fromDate != null
                    ? 'Từ ${DateFormatter.dateOnly(query.fromDate!)}'
                    : 'Từ ngày',
                isActive: query.fromDate != null,
                activeColor: AppColors.secondary,
                onTap: () => _pickFromDate(context),
                onClear: query.fromDate != null
                    ? () => cubit.setDateRange(null, query.toDate)
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _NeoFilterChip(
                icon: Icons.event,
                label: query.toDate != null
                    ? 'Đến ${DateFormatter.dateOnly(query.toDate!)}'
                    : 'Đến ngày',
                isActive: query.toDate != null,
                activeColor: AppColors.secondary,
                onTap: () => _pickToDate(context),
                onClear: query.toDate != null
                    ? () => cubit.setDateRange(query.fromDate, null)
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _NeoFilterChip(
                icon: Icons.flag,
                label: query.statuses != null && query.statuses!.isNotEmpty
                    ? 'Trạng thái (${query.statuses!.length})'
                    : 'Trạng thái',
                isActive:
                    query.statuses != null && query.statuses!.isNotEmpty,
                activeColor: AppColors.accent,
                foregroundColor: AppColors.black,
                onTap: () => _openStatusFilter(context),
                onClear:
                    query.statuses != null && query.statuses!.isNotEmpty
                        ? () => cubit.setStatuses(null)
                        : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _NeoFilterChip(
                icon: query.scope == SearchScope.hostedOnly
                    ? Icons.person
                    : (query.scope == SearchScope.joinedOnly
                        ? Icons.group
                        : Icons.public),
                label: _scopeLabel(query.scope),
                isActive: query.scope != SearchScope.all,
                activeColor: AppColors.info,
                onTap: () => _openScopeFilter(context),
                onClear: query.scope != SearchScope.all
                    ? () => cubit.setScope(SearchScope.all)
                    : null,
              ),
              if (hasAnyFilter) ...[
                const SizedBox(width: AppSpacing.xs),
                _NeoIconButton(
                  icon: Icons.filter_alt_off,
                  label: 'Xóa lọc',
                  onPressed: () => _clearAll(context),
                  color: AppColors.error,
                  withLabel: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _scopeLabel(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return 'Tất cả';
      case SearchScope.hostedOnly:
        return 'Tôi host';
      case SearchScope.joinedOnly:
        return 'Tôi tham gia';
    }
  }

  // ─── Results ──────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<SearchReservationsCubit, SearchReservationsState>(
      builder: (context, state) {
        if (state is SearchReservationsLoading) {
          return _buildLoadingSkeleton();
        }
        if (state is SearchReservationsFailure) {
          if (state.previousItems.isNotEmpty) {
            return Column(
              children: [
                _NeoErrorBanner(
                    message:
                        'Không tải được trang tiếp: ${state.message}'),
                Expanded(
                  child: _buildItemsList(
                    context,
                    state.previousItems,
                    isLoadMore: false,
                    hasNextPage: false,
                  ),
                ),
              ],
            );
          }
          return _NeoEmptyState(
            icon: Icons.error_outline,
            title: 'ĐÃ XẢY RA LỖI',
            message: state.message,
            actionLabel: 'THỬ LẠI',
            actionIcon: Icons.refresh,
            onAction: () => context.read<SearchReservationsCubit>().refresh(),
            variant: NeoEmptyStateVariant.error,
          );
        }
        if (state is SearchReservationsLoaded) {
          if (state.items.isEmpty) {
            return _NeoEmptyState(
              icon: Icons.event_busy,
              title: state.query.hasAnyFilter
                  ? 'KHÔNG TÌM THẤY'
                  : 'CHƯA CÓ LỊCH HẸN',
              message: _buildNoResultHint(state.query),
              actionLabel: state.query.hasAnyFilter ? 'XÓA BỘ LỌC' : null,
              actionIcon: Icons.filter_alt_off,
              onAction: state.query.hasAnyFilter
                  ? () => context.read<SearchReservationsCubit>().clearFilters()
                  : null,
              variant: state.query.hasAnyFilter
                  ? NeoEmptyStateVariant.empty
                  : NeoEmptyStateVariant.neutral,
            );
          }
          return Column(
            children: [
              if (widget.showResultSummary)
                _NeoResultSummary(state: state),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      context.read<SearchReservationsCubit>().refresh(),
                  child: _buildItemsList(
                    context,
                    state.items,
                    isLoadMore: state.isLoadMore,
                    hasNextPage: state.hasNextPage,
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    // Layout khớp 100% với grid đã load: 2 cột, cùng padding, cùng
    // mainAxisExtent (220). Mỗi cell dùng `ReservationCardSkeleton`
    // (vertical cover + content layout) — không còn skeleton horizontal
    // cũ nữa, tránh việc cell loading nhìn khác hẳn cell đã load.
    return GridView.builder(
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

  String _buildNoResultHint(ReservationSearchQuery query) {
    if (query.hasAnyFilter) {
      return 'Không có lịch hẹn nào khớp với điều kiện của bạn. Thử nới lỏng bộ lọc.';
    }
    return 'Bạn chưa tạo hoặc tham gia lịch hẹn nào. Hãy đặt phòng chờ đầu tiên của bạn.';
  }

  Widget _buildItemsList(
    BuildContext context,
    List<ReservationEntity> items, {
    required bool isLoadMore,
    required bool hasNextPage,
  }) {
    return GridView.builder(
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
      itemCount: items.length + (hasNextPage || isLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
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
        final r = items[index];
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

// ═══════════════════════════════════════════════════════════════════════
// Neo-brutalism UI components — tách riêng để dễ tái sử dụng
// ═══════════════════════════════════════════════════════════════════════

/// Filter chip neo-brutalism — có press animation + active state nổi bật.
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

/// Icon button nhỏ neo-brutalism — dùng cho clear filter, v.v.
class _NeoIconButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color color;
  final String? tooltip;
  final bool withLabel;

  const _NeoIconButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.label,
    this.tooltip,
    this.withLabel = false,
  });

  @override
  State<_NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<_NeoIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btn = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 2,
          ),
          padding: widget.withLabel
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                )
              : const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: AppRadius.chipRadius,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: widget.color.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 14),
              if (widget.label != null && widget.withLabel) ...[
                const SizedBox(width: 4),
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Banner tóm tắt kết quả — neo-brutalism với gradient cam.
class _NeoResultSummary extends StatelessWidget {
  final SearchReservationsLoaded state;

  const _NeoResultSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // Icon badge
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: AppRadius.radiusXsAll,
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TÌM THẤY ${state.totalItems} KẾT QUẢ',
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
}

/// Banner lỗi inline — neo-brutalism với border đỏ.
class _NeoErrorBanner extends StatelessWidget {
  final String message;

  const _NeoErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(
          color: AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty/Error state — neo-brutalism với icon lớn + button bold.
enum NeoEmptyStateVariant { empty, neutral, error }

class _NeoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final NeoEmptyStateVariant variant;

  const _NeoEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.variant,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconBg;
    Color iconFg;
    Color accent;
    switch (variant) {
      case NeoEmptyStateVariant.empty:
        iconBg = AppColors.accent;
        iconFg = AppColors.black;
        accent = AppColors.primary;
        break;
      case NeoEmptyStateVariant.error:
        iconBg = AppColors.error;
        iconFg = Colors.white;
        accent = AppColors.error;
        break;
      case NeoEmptyStateVariant.neutral:
        iconBg = isDark ? AppColors.surfaceContainerDark : AppColors.surfaceVariant;
        iconFg = isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
        accent = AppColors.primary;
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big icon badge neo-brutalism
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppRadius.radiusLgAll,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  bold: true,
                  shadowColor: iconBg.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(icon, size: 56, color: iconFg),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _NeoActionButton(
                label: actionLabel!,
                icon: actionIcon ?? Icons.refresh,
                color: accent,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Action button neo-brutalism — dùng cho "Thử lại", "Xóa bộ lọc"...
class _NeoActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _NeoActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_NeoActionButton> createState() => _NeoActionButtonState();
}

class _NeoActionButtonState extends State<_NeoActionButton> {
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
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              bold: true,
              shadowColor: widget.color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.xs),
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

// ═══════════════════════════════════════════════════════════════════════
// Bottom sheets — neo-brutalism style
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
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Title với icon badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: AppRadius.radiusXsAll,
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
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
              // Chips grid
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
              // Action buttons
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

class _ScopeFilterSheet extends StatefulWidget {
  final SearchScope initial;

  const _ScopeFilterSheet({required this.initial});

  @override
  State<_ScopeFilterSheet> createState() => _ScopeFilterSheetState();
}

class _ScopeFilterSheetState extends State<_ScopeFilterSheet> {
  late SearchScope _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              shadowColor: AppColors.info.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: AppRadius.radiusXsAll,
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        width: NeoBrutalismTheme.borderWidth,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PHẠM VI TÌM KIẾM',
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
              // Options
              for (final scope in SearchScope.values) ...[
                _ScopeOptionTile(
                  scope: scope,
                  isSelected: _selected == scope,
                  onTap: () => setState(() => _selected = scope),
                ),
                if (scope != SearchScope.values.last)
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Action
              SizedBox(
                width: double.infinity,
                child: _NeoFilledButton(
                  label: 'ÁP DỤNG',
                  icon: Icons.check,
                  color: AppColors.primary,
                  onPressed: () =>
                      Navigator.of(context).pop(_selected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeOptionTile extends StatelessWidget {
  final SearchScope scope;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeOptionTile({
    required this.scope,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? AppColors.info
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Radio badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: NeoBrutalismTheme.borderWidth,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Icon
            Icon(
              scope == SearchScope.hostedOnly
                  ? Icons.person
                  : (scope == SearchScope.joinedOnly
                      ? Icons.group
                      : Icons.public),
              size: 20,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _scopeTitle(scope),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _scopeSubtitle(scope),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
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

  String _scopeTitle(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return 'Tất cả';
      case SearchScope.hostedOnly:
        return 'Chỉ lịch hẹn tôi host';
      case SearchScope.joinedOnly:
        return 'Chỉ lịch hẹn tôi tham gia';
    }
  }

  String _scopeSubtitle(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return 'Hiển thị cả lịch hẹn bạn host và tham gia';
      case SearchScope.hostedOnly:
        return 'Chỉ những lịch hẹn bạn là người tạo';
      case SearchScope.joinedOnly:
        return 'Chỉ những lịch hẹn bạn tham gia';
    }
  }
}

// ─── Chip + Button helpers ─────────────────────────────────────────────

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
