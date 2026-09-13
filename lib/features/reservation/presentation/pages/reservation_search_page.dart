// ignore_for_file: deprecated_member_use, prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/search_reservations_cubit.dart';
import '../cubit/search_reservations_state.dart';
import '../widgets/reservation_grid_card.dart';
import '../widgets/reservation_card_skeleton.dart';
import 'reservation_detail_page.dart';

/// Trang Search Reservations — cho phép Player tra cứu lại lịch hẹn trong
/// lịch sử bằng cách filter theo tên game, khoảng ngày, trạng thái, quán.
///
/// Tích hợp API `GET /api/v1/reservations/search` (xem
/// `.agents/docs/apis_docs/reservation.md` §GET /search).
///
/// Luồng UX:
/// 1. User mở trang → thấy search bar + filter chips rỗng (không auto-load).
/// 2. Nhập tên game và/hoặc chọn khoảng ngày / status → bấm "Tìm".
/// 3. Cubit gọi API → hiển thị kết quả dạng infinite scroll.
/// 4. Bấm vào card → sang trang chi tiết.
class ReservationSearchPage extends StatelessWidget {
  const ReservationSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchReservationsCubit>(
      create: (_) => SearchReservationsCubit(
        repository: sl<ReservationRepository>(),
      ),
      child: const _ReservationSearchView(),
    );
  }
}

class _ReservationSearchView extends StatefulWidget {
  const _ReservationSearchView();

  @override
  State<_ReservationSearchView> createState() => _ReservationSearchViewState();
}

class _ReservationSearchViewState extends State<_ReservationSearchView> {
  final TextEditingController _gameNameController = TextEditingController();
  final FocusNode _gameNameFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  ReservationSearchQuery _currentQuery = ReservationSearchQuery.empty;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      // Sắp tới cuối list → load more
      context.read<SearchReservationsCubit>().loadMore();
    }
  }

  void _runSearch() {
    final query = ReservationSearchQuery(
      gameName: _gameNameController.text.trim().isEmpty
          ? null
          : _gameNameController.text.trim(),
      fromDate: _fromDate,
      toDate: _toDate,
      statuses: _currentQuery.statuses,
      cafeId: _currentQuery.cafeId,
      scope: _currentQuery.scope,
    );
    setState(() => _currentQuery = query);
    context.read<SearchReservationsCubit>().search(query);
    _gameNameFocus.unfocus();
  }

  void _clearAll() {
    _gameNameController.clear();
    setState(() {
      _fromDate = null;
      _toDate = null;
      _currentQuery = ReservationSearchQuery.empty;
    });
    context.read<SearchReservationsCubit>().clearFilters();
  }

  Future<void> _pickFromDate() async {
    final initial = _fromDate ?? DateTime.now();
    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? DateTime.now() : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final initial = _toDate ?? (_fromDate ?? DateTime.now());
    final firstDate = _fromDate ?? DateTime.now().subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày kết thúc',
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  void _openStatusFilter() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusFilterSheet(
        initial: _currentQuery.statuses ?? const [],
      ),
    );
    if (selected != null) {
      setState(() {
        _currentQuery = _currentQuery.copyWith(
          statuses: selected.isEmpty ? null : selected,
          clearStatuses: selected.isEmpty,
        );
      });
      // Auto-search nếu đã có gameName/fromDate filter.
      if (_currentQuery.hasAnyFilter) {
        _runSearch();
      }
    }
  }

  void _openScopeFilter() async {
    final scope = await showModalBottomSheet<SearchScope>(
      context: context,
      builder: (_) => _ScopeFilterSheet(initial: _currentQuery.scope),
    );
    if (scope != null && scope != _currentQuery.scope) {
      setState(() {
        _currentQuery = _currentQuery.copyWith(scope: scope);
      });
      if (_currentQuery.hasAnyFilter) {
        _runSearch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Tìm lịch hẹn'),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            tooltip: 'Xóa bộ lọc',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(colors),
            _buildFilterChips(colors),
            const Divider(height: 1),
            Expanded(child: _buildResults(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _gameNameController,
              focusNode: _gameNameFocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên game (vd: Catan, Splendor)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _gameNameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _gameNameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMdAll,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onSubmitted: (_) => _runSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _runSearch,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Tìm'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colors) {
    final hasFrom = _fromDate != null;
    final hasTo = _toDate != null;
    final hasStatuses =
        _currentQuery.statuses != null && _currentQuery.statuses!.isNotEmpty;
    final hasScope = _currentQuery.scope != SearchScope.all;

    if (!hasFrom && !hasTo && !hasStatuses && !hasScope) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          InputChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              hasFrom
                  ? 'Từ: ${DateFormatter.dateOnly(_fromDate!)}'
                  : 'Từ ngày',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _pickFromDate,
            onDeleted: hasFrom ? () => setState(() => _fromDate = null) : null,
          ),
          InputChip(
            avatar: const Icon(Icons.event, size: 16),
            label: Text(
              hasTo
                  ? 'Đến: ${DateFormatter.dateOnly(_toDate!)}'
                  : 'Đến ngày',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _pickToDate,
            onDeleted: hasTo ? () => setState(() => _toDate = null) : null,
          ),
          InputChip(
            avatar: const Icon(Icons.flag, size: 16),
            label: Text(
              hasStatuses
                  ? 'Trạng thái: ${_currentQuery.statuses!.length}'
                  : 'Trạng thái',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _openStatusFilter,
            onDeleted: hasStatuses
                ? () => setState(() {
                      _currentQuery =
                          _currentQuery.copyWith(clearStatuses: true);
                    })
                : null,
          ),
          InputChip(
            avatar: const Icon(Icons.person, size: 16),
            label: Text(
              _scopeLabel(_currentQuery.scope),
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: _openScopeFilter,
            onDeleted: hasScope
                ? () => setState(() {
                      _currentQuery = _currentQuery.copyWith(
                        scope: SearchScope.all,
                      );
                    })
                : null,
          ),
        ],
      ),
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

  Widget _buildResults(ColorScheme colors) {
    return BlocBuilder<SearchReservationsCubit, SearchReservationsState>(
      builder: (context, state) {
        if (state is SearchReservationsInitial) {
          return const EmptyStateWidget(
            icon: Icons.search,
            title: 'Tìm kiếm lịch hẹn',
            message:
                'Nhập tên game hoặc chọn khoảng ngày rồi nhấn "Tìm" để tra cứu lại các lịch hẹn trong lịch sử của bạn.',
            compact: true,
          );
        }
        if (state is SearchReservationsLoading) {
          return ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: ReservationCardSkeleton(),
              ),
            ),
          );
        }
        if (state is SearchReservationsFailure) {
          if (state.previousItems.isNotEmpty) {
            // Có data cũ → hiển thị data cũ + banner lỗi
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: colors.errorContainer,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colors.onErrorContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Không tải được trang tiếp: ${state.message}',
                          style: TextStyle(color: colors.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildItemsList(context, state.previousItems, colors),
                ),
              ],
            );
          }
          return ErrorStateWidget(
            message: state.message,
            onRetry: _runSearch,
          );
        }
        if (state is SearchReservationsLoaded) {
          if (state.items.isEmpty) {
            return SearchEmptyState(
              query: _gameNameController.text,
              onClearSearch: _clearAll,
            );
          }
          return Column(
            children: [
              _buildResultSummary(state, colors),
              Expanded(
                child: _buildItemsList(context, state.items, colors,
                    isLoadMore: state.isLoadMore, hasNextPage: state.hasNextPage),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildResultSummary(SearchReservationsLoaded state, ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Text(
        'Tìm thấy ${state.totalItems} kết quả'
        '${state.totalPages > 1 ? ' (trang ${state.page}/${state.totalPages})' : ''}',
        style: TextStyle(
          fontSize: 12,
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<ReservationEntity> items,
    ColorScheme colors, {
    bool isLoadMore = false,
    bool hasNextPage = false,
  }) {
    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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
      itemCount: items.length + (hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
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

// ─── Status filter bottom sheet ─────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Lấy tất cả status của Reservation từ enum.
    final allStatuses = ReservationStatus.values
        .where((s) => s != ReservationStatus.draft) // Bỏ draft — chưa hiển thị
        .toList();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lọc theo trạng thái',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: allStatuses.map((s) {
                final isSelected = _selected.contains(s.name);
                return FilterChip(
                  label: Text(s.displayName),
                  selected: isSelected,
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _selected.add(s.name);
                      } else {
                        _selected.remove(s.name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(<String>[]),
                    child: const Text('Bỏ lọc'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _selected.toList(),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scope filter bottom sheet ──────────────────────────────────────────

class _ScopeFilterSheet extends StatelessWidget {
  final SearchScope initial;

  const _ScopeFilterSheet({required this.initial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Phạm vi tìm kiếm',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final scope in SearchScope.values)
              RadioListTile<SearchScope>(
                value: scope,
                groupValue: initial,
                title: Text(_scopeLabel(scope)),
                onChanged: (val) {
                  if (val != null) Navigator.of(context).pop(val);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return 'Tất cả (cả host và thành viên)';
      case SearchScope.hostedOnly:
        return 'Chỉ lịch hẹn tôi host';
      case SearchScope.joinedOnly:
        return 'Chỉ lịch hẹn tôi tham gia';
    }
  }
}
