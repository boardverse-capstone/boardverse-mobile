import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/presentation/widgets/board_game_card.dart';
import '../../../matchmaking_discovery/presentation/widgets/empty_board_game_illustration.dart';

/// Bottom sheet chọn board game khi tạo lobby — redesign:
/// - Search bar realtime filter theo `name` (lowercase contains).
/// - Grid 2 cột với [BoardGameCard] (ảnh + rating + meta) — đồng nhất
///   với trang Search.
/// - Skeleton loading khi games rỗng (parent chưa fetch xong).
/// - Empty state riêng cho "không có kết quả" (sau khi search).
///
/// Contract với parent: trả về [BoardGameEntity] qua `Navigator.pop` —
/// không đổi.
class LobbyGamePickerSheet extends StatefulWidget {
  final List<BoardGameEntity> games;

  const LobbyGamePickerSheet({super.key, required this.games});

  @override
  State<LobbyGamePickerSheet> createState() => _LobbyGamePickerSheetState();
}

class _LobbyGamePickerSheetState extends State<LobbyGamePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BoardGameEntity> get _filteredGames {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.games;
    return widget.games
        .where((g) => g.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _onQueryChanged(String value) {
    if (value == _query) return;
    setState(() => _query = value);
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    // Chỉ render 1 container duy nhất — `showModalBottomSheet` của parent
    // đã cung cấp lớp BottomSheet + enableDrag + clip content. Không bọc
    // thêm `DraggableScrollableSheet` để tránh 2 thanh kéo trùng nhau.
    //
    // `isScrollControlled: true` ở parent cho phép sheet cao tùy ý, nên
    // ta giới hạn bằng `SizedBox(height: 85% screen)` để giữ UX cũ.
    return SizedBox(
      height: media.size.height * 0.85,
      child: SafeArea(
        top: false,
        child: Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              _buildSearchBar(theme, isDark),
              _buildMetaRow(theme),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header: title + subtitle + close ───────────────────────────────
  // Lưu ý: không vẽ drag handle ở đây — `BottomSheetThemeData.showDragHandle`
  // của app theme đã tự render handle mặc định ở mép trên (xem
  // `app_theme.dart`). Vẽ thủ công sẽ tạo 2 thanh kéo trùng nhau.
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.extension,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn board game',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Bắt đầu tạo phòng bằng cách chọn tựa game bạn muốn chơi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ─────────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Tìm tên game...',
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.primary,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearQuery,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Meta row: số kết quả hiện tại ─────────────────────────────────
  Widget _buildMetaRow(ThemeData theme) {
    // Chỉ hiển thị khi đã có game load xong (không phải skeleton).
    if (widget.games.isEmpty) return const SizedBox.shrink();

    final filtered = _filteredGames;
    final hasQuery = _query.trim().isNotEmpty;
    final label = hasQuery
        ? '${filtered.length}/${widget.games.length} kết quả cho "$_query"'
        : '${widget.games.length} game có sẵn';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            hasQuery ? Icons.filter_alt : Icons.sports_esports,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xxs + 2),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body: grid / skeleton / empty ─────────────────────────────────
  // ─── Body: grid / skeleton / empty ─────────────────────────────────
  Widget _buildBody() {
    if (widget.games.isEmpty) {
      // Loading skeleton: parent chưa fetch xong danh sách game.
      return const _PickerSkeletonGrid();
    }

    final filtered = _filteredGames;
    if (filtered.isEmpty) {
      // User search không ra kết quả.
      return EmptyBoardGameState(
        title: 'Không tìm thấy game',
        message: 'Thử từ khoá khác hoặc xoá bộ lọc để xem tất cả.',
        actionLabel: 'Xoá tìm kiếm',
        actionIcon: Icons.clear,
        onAction: _clearQuery,
      );
    }

    // Grid tự quản `ScrollController` của nó — không cần controller từ
    // ngoài vì đã bỏ `DraggableScrollableSheet` (xem build()).
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 4 / 5,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final game = filtered[index];
        return BoardGameCard(
          game: game,
          onTap: () => Navigator.pop(context, game),
        );
      },
    );
  }
}

/// Skeleton grid nội bộ — match tỉ lệ card [BoardGameCard] (4/5).
/// 6 ô (3 hàng × 2 cột) hiển thị shimmer animation khi parent chưa fetch.
class _PickerSkeletonGrid extends StatefulWidget {
  const _PickerSkeletonGrid();

  @override
  State<_PickerSkeletonGrid> createState() => _PickerSkeletonGridState();
}

class _PickerSkeletonGridState extends State<_PickerSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? AppColors.surfaceDark : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 4 / 5,
          ),
          itemCount: 6,
          itemBuilder: (context, _) {
            // Di chuyển điểm sáng từ trái → phải theo `_ctrl.value`.
            final t = _ctrl.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + t * 2, -0.3),
                  end: Alignment(1.0 + t * 2, 0.3),
                  colors: [base, highlight, base],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        );
      },
    );
  }
}