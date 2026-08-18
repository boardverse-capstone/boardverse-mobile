import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/animated_section_header.dart';
import '../widgets/board_game_card.dart';
import '../widgets/cafe_search_card.dart';
import '../widgets/empty_board_game_illustration.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/game_skeleton.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/search/active_filter_bar.dart';
import '../widgets/search/error_retry_view.dart';
import '../widgets/search/quick_filter_row.dart';
import 'board_game_detail_page.dart';
import 'cafe_detail_page.dart';

/// Tab hiển thị trong unified search page.
enum SearchTab { boardgames, cafes }

class SearchPage extends StatefulWidget {
  final MatchmakingCubit matchmakingCubit;

  const SearchPage({super.key, required this.matchmakingCubit});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  int? _minPlayers;
  int? _maxPlayers;

  final Set<DurationRange> _selectedDurationRanges = <DurationRange>{};

  late final TabController _tabController;
  SearchTab _activeTab = SearchTab.boardgames;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final next = SearchTab.values[_tabController.index];
      setState(() => _activeTab = next);
      // Khi đổi tab, refresh lại theo query hiện tại.
      if (next == SearchTab.cafes) {
        _triggerCafeSearch();
      } else {
        _loadGames();
      }
    }
  }

  void _loadGames() {
    widget.matchmakingCubit.searchGames();
  }

  void _triggerCafeSearch() {
    final query = _searchController.text.trim();
    // Cafe tab:
    // - Có query → tìm theo tên (searchCafes).
    // - Không query → gọi /api/cafes/nearby/me trực tiếp (backend đã bỏ
    //   yêu cầu bắt buộc gameTemplateId). Không cần pre-fetch popular
    //   game trước khi load cafe — đơn giản hoá flow.
    widget.matchmakingCubit.loadCafesNearbyForCurrentUser(
      name: query,
    );
  }

  Future<void> _refresh() async {
    if (_activeTab == SearchTab.cafes) {
      _triggerCafeSearch();
    } else {
      widget.matchmakingCubit.searchGames(query: _searchController.text);
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  void _onSubmitted(String value) {
    final query = value.trim();
    if (_activeTab == SearchTab.cafes) {
      // Khi submit, có/không có query đều dùng cùng 1 method — nó tự
      // branch sang searchCafes nếu có query, hoặc loadCafesNearbyForCurrentUser
      // nếu rỗng. Backend /api/cafes/nearby/me không còn yêu cầu bắt buộc
      // gameTemplateId.
      widget.matchmakingCubit.loadCafesNearbyForCurrentUser(
        name: query,
      );
    } else {
      widget.matchmakingCubit.searchGames(
        query: query,
        category: _selectedCategory,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
      );
    }
  }

  void _onClearQuery() {
    _searchController.clear();
    setState(() {});
    if (_activeTab == SearchTab.cafes) {
      // Quay về chế độ "quán gần player" sau khi clear query.
      widget.matchmakingCubit.loadCafesNearbyForCurrentUser();
    } else {
      widget.matchmakingCubit.searchGames(
        category: _selectedCategory,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
      );
    }
  }

  void _showFilterDrawer(BuildContext context) {
    FilterBottomSheet.show(
      context,
      selectedCategory: _selectedCategory,
      minPlayers: _minPlayers,
      maxPlayers: _maxPlayers,
      selectedDurationRanges: _selectedDurationRanges,
      onApply: (category, minP, maxP, durationRanges) {
        setState(() {
          _selectedCategory = category;
          _minPlayers = minP;
          _maxPlayers = maxP;
          _selectedDurationRanges
            ..clear()
            ..addAll(durationRanges);
        });
        widget.matchmakingCubit.searchGames(
          query: _searchController.text,
          category: category,
          minPlayers: minP,
          maxPlayers: maxP,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Search bar + filter button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: NeoBrutalismTheme.borderWidth,
                          ),
                          boxShadow: NeoBrutalismTheme.lightShadow(
                            shadowColor:
                                AppColors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: _activeTab == SearchTab.cafes
                                ? 'Tìm quán cafe theo tên...'
                                : 'Tìm kiếm board game...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              _activeTab == SearchTab.cafes
                                  ? Icons.storefront_rounded
                                  : Icons.search,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            suffixIcon: ValueListenableBuilder<
                                TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, _) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(Icons.clear),
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  onPressed: _onClearQuery,
                                );
                              },
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                          ),
                          onSubmitted: _onSubmitted,
                          // Bỏ `onChanged: setState` — rebuild full Scaffold
                          // mỗi keystroke kết hợp với BlocBuilder + PageView
                          // auto-scroll gây loop "Assertion failed" tại
                          // mouse_tracker.dart:199. Suffix icon giờ rebuild
                          // độc lập qua ValueListenableBuilder ở trên.
                        ),
                      ),
                    ),
                    // Filter button chỉ hiện ở tab boardgame
                    if (_activeTab == SearchTab.boardgames) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: (_selectedCategory != null ||
                                  _minPlayers != null ||
                                  _selectedDurationRanges.isNotEmpty)
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: NeoBrutalismTheme.borderWidth,
                          ),
                          boxShadow: NeoBrutalismTheme.lightShadow(
                            shadowColor: (_selectedCategory != null ||
                                    _minPlayers != null ||
                                    _selectedDurationRanges.isNotEmpty)
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showFilterDrawer(context),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Icon(
                                Icons.tune,
                                color: (_selectedCategory != null ||
                                        _minPlayers != null ||
                                        _selectedDurationRanges.isNotEmpty)
                                    ? AppColors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tab bar
              _SearchTabBar(
                controller: _tabController,
                isDark: isDark,
              ),

              // Boardgame filters (chỉ hiện ở tab boardgame)
              if (_activeTab == SearchTab.boardgames) ...[
                QuickFilterRow(
                  selectedCategory: _selectedCategory,
                  selectedDurationRanges: _selectedDurationRanges,
                  onCategoryTap: (cat) {
                    setState(() {
                      _selectedCategory = _selectedCategory == cat ? null : cat;
                    });
                    widget.matchmakingCubit.searchGames(
                      query: _searchController.text,
                      category: _selectedCategory,
                    );
                  },
                  onDurationTap: (range) {
                    setState(() {
                      if (_selectedDurationRanges.contains(range)) {
                        _selectedDurationRanges.remove(range);
                      } else {
                        _selectedDurationRanges.add(range);
                      }
                    });
                    widget.matchmakingCubit.searchGames(
                      query: _searchController.text,
                      category: _selectedCategory,
                      minPlayers: _minPlayers,
                      maxPlayers: _maxPlayers,
                    );
                  },
                ),
                if (_selectedCategory != null ||
                    _minPlayers != null ||
                    _selectedDurationRanges.isNotEmpty)
                  ActiveFilterBar(
                    selectedCategory: _selectedCategory,
                    minPlayers: _minPlayers,
                    selectedDurationRanges: _selectedDurationRanges,
                    onRemoveCategory: () {
                      setState(() => _selectedCategory = null);
                      widget.matchmakingCubit.searchGames(
                        query: _searchController.text,
                      );
                    },
                    onRemovePlayerCount: () {
                      setState(() {
                        _minPlayers = null;
                        _maxPlayers = null;
                      });
                      widget.matchmakingCubit.searchGames(
                        query: _searchController.text,
                      );
                    },
                    onRemoveDuration: (range) {
                      setState(
                          () => _selectedDurationRanges.remove(range));
                      widget.matchmakingCubit.searchGames(
                        query: _searchController.text,
                        category: _selectedCategory,
                        minPlayers: _minPlayers,
                        maxPlayers: _maxPlayers,
                      );
                    },
                  ),
              ],

              // Results
              Expanded(
                child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
                  builder: (context, state) {
                    if (_activeTab == SearchTab.cafes) {
                      return _buildCafesBody(context, state);
                    }
                    return _buildBoardGamesBody(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardGamesBody(
    BuildContext context,
    MatchmakingState state,
  ) {
    final games = state is MatchmakingSearchResults
        ? state.games
        : <BoardGameEntity>[];
    final featured = _pickFeaturedGames(games);

    if (state is MatchmakingLoading) {
      return const GameSkeletonList();
    }
    if (state is MatchmakingFailure) {
      return ErrorRetryView(
        message: state.message,
        onRetry: () => widget.matchmakingCubit.searchGames(),
      );
    }
    if (state is MatchmakingSearchResults) {
      if (state.games.isEmpty) {
        return EmptyBoardGameState(
          title: 'Không tìm thấy game phù hợp',
          message: 'Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm nhé.',
          actionLabel: 'Đặt lại bộ lọc',
          actionIcon: Icons.refresh,
          onAction: () {
            _searchController.clear();
            _selectedCategory = null;
            _minPlayers = null;
            _maxPlayers = null;
            _selectedDurationRanges.clear();
            widget.matchmakingCubit.searchGames();
          },
        );
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            if (featured.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: HeroBannerCarousel(
                  featuredGames: featured,
                  onTapGame: (game) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoardGameDetailPage(
                        gameId: game.id,
                        matchmakingCubit: widget.matchmakingCubit,
                      ),
                    ),
                  ).then((_) => _loadGames()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: AnimatedSectionHeader(
                  title: 'Tất cả board game',
                  subtitle: '${state.games.length} game sẵn sàng',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 4 / 5,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final game = state.games[index];
                  return BoardGameCard(
                    game: game,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoardGameDetailPage(
                          gameId: game.id,
                          matchmakingCubit: widget.matchmakingCubit,
                        ),
                      ),
                    ).then((_) => _loadGames()),
                  );
                }, childCount: state.games.length),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCafesBody(
    BuildContext context,
    MatchmakingState state,
  ) {
    final query = _searchController.text.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state is MatchmakingLoading) {
      return const GameSkeletonList();
    }
    if (state is MatchmakingFailure) {
      return ErrorRetryView(
        message: state.message,
        onRetry: _triggerCafeSearch,
      );
    }
    if (state is MatchmakingCafeSearchResults) {
      final cafes = state.cafes;
      if (cafes.isEmpty) {
        return _CafesEmptyState(
          query: query,
          emptyResultMessage: state.emptyResultMessage,
          onReset: () {
            _searchController.clear();
            // Reset về "quán gần player" — gọi trực tiếp, không cần
            // truyền preferredGameId vì backend đã bỏ yêu cầu bắt buộc.
            widget.matchmakingCubit.loadCafesNearbyForCurrentUser();
            setState(() {});
          },
        );
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _CafesSectionHeader(
                isDark: isDark,
                query: query,
                totalCount: cafes.length,
                fallbackGameName: state.fallbackGameName,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cafe = cafes[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CafeSearchCard(
                        cafe: cafe,
                        onTap: () async {
                          // Truyền query hiện tại để restore kết quả search
                          // sau khi player back từ flow đặt chỗ.
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CafeDetailPage(
                                cafeId: cafe.id,
                                cafeEntity: cafe,
                                matchmakingCubit: widget.matchmakingCubit,
                                searchQuery: query.isEmpty ? null : query,
                              ),
                            ),
                          );
                          // Khi player back từ CafeDetailPage (sau khi đã
                          // đi vào LobbyConfigPage), cubit state đã bị đổi
                          // sang SearchResults cho games. Nếu trước đó
                          // player đang search cafe, cần re-trigger để UI
                          // hiển thị lại danh sách cafe.
                          if (!mounted) return;
                          if (_activeTab == SearchTab.cafes &&
                              widget.matchmakingCubit.state
                                  is! MatchmakingCafeSearchResults) {
                            _triggerCafeSearch();
                          }
                        },
                      ),
                    );
                  },
                  childCount: cafes.length,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const GameSkeletonList();
  }

  List<BoardGameEntity> _pickFeaturedGames(List<BoardGameEntity> games) {
    if (games.isEmpty) return const [];
    final sorted = [...games]
      ..sort((a, b) {
        final aScore =
            (a.rating >= 4.5 ? 2 : 0) + (a.category == 'Giải trí' ? 1 : 0);
        final bScore =
            (b.rating >= 4.5 ? 2 : 0) + (b.category == 'Giải trí' ? 1 : 0);
        return bScore.compareTo(aScore);
      });
    return sorted.take(5).toList();
  }
}

class _SearchTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _SearchTabBar({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppColors.white,
        unselectedLabelColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino_outlined, size: 18),
                SizedBox(width: AppSpacing.xs),
                Text('Board game'),
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_cafe_outlined, size: 18),
                SizedBox(width: AppSpacing.xs),
                Text('Quán cafe'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CafesEmptyState extends StatelessWidget {
  final String query;
  final String? emptyResultMessage;
  final VoidCallback onReset;

  const _CafesEmptyState({
    required this.query,
    required this.onReset,
    this.emptyResultMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMessage = emptyResultMessage != null && emptyResultMessage!.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container neo-brutalism
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                borderColor: AppColors.primary,
                bold: true,
                borderRadius: 20,
              ),
              child: Icon(
                query.isEmpty
                    ? Icons.location_off_rounded
                    : Icons.search_off_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              query.isEmpty
                  ? 'Chưa có quán cafe nào gần bạn'
                  : 'Không tìm thấy quán phù hợp',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasMessage
                  ? emptyResultMessage!
                  : (query.isEmpty
                      ? 'Hãy bật vị trí trên profile hoặc thử lại sau nhé.'
                      : 'Thử thay đổi từ khoá tìm kiếm.'),
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.primary,
                borderColor: isDark ? AppColors.borderDark : AppColors.border,
                bold: true,
                borderRadius: 12,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onReset,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: AppColors.white, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'ĐẶT LẠI',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header cho cafe list — gradient strip với icon + label +
/// count badge. Tự nhận biết đang ở chế độ search hay nearby.
class _CafesSectionHeader extends StatelessWidget {
  final bool isDark;
  final String query;
  final int totalCount;
  final String? fallbackGameName;

  const _CafesSectionHeader({
    required this.isDark,
    required this.query,
    required this.totalCount,
    this.fallbackGameName,
  });

  @override
  Widget build(BuildContext context) {
    final isSearch = query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Container(
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor: isSearch
              ? AppColors.primary
              : AppColors.secondary,
          borderColor: isDark ? AppColors.borderDark : AppColors.border,
          shadowColor: (isSearch ? AppColors.primary : AppColors.secondary)
              .withValues(alpha: 0.4),
          bold: true,
          borderRadius: 14,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSearch
                      ? Icons.search_rounded
                      : Icons.near_me_rounded,
                  size: 20,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSearch
                          ? 'Kết quả cho "$query"'
                          : 'Quán cafe gần bạn',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fallbackGameName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Có game: $fallbackGameName',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.black, width: 1.5),
                ),
                child: Text(
                  totalCount == 1 ? '1 quán' : '$totalCount quán',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
