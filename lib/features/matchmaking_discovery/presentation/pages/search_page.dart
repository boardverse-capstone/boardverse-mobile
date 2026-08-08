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
import '../widgets/empty_board_game_illustration.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/game_skeleton.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/search/active_filter_bar.dart';
import '../widgets/search/error_retry_view.dart';
import '../widgets/search/quick_filter_row.dart';
import 'board_game_detail_page.dart';

class SearchPage extends StatefulWidget {
  final MatchmakingCubit matchmakingCubit;

  const SearchPage({super.key, required this.matchmakingCubit});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  int? _minPlayers;
  int? _maxPlayers;

  final Set<DurationRange> _selectedDurationRanges = <DurationRange>{};

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadGames() {
    widget.matchmakingCubit.searchGames();
  }

  Future<void> _refresh() async {
    widget.matchmakingCubit.searchGames(query: _searchController.text);
    await Future<void>.delayed(const Duration(milliseconds: 600));
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
          child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
            builder: (context, state) {
              final games = state is MatchmakingSearchResults
                  ? state.games
                  : <BoardGameEntity>[];
              final featured = _pickFeaturedGames(games);

              return Column(
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
                                hintText: 'Tìm kiếm board game...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                        onPressed: () {
                                          _searchController.clear();
                                          widget.matchmakingCubit.searchGames();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              onSubmitted: (value) {
                                widget.matchmakingCubit.searchGames(
                                  query: value,
                                  category: _selectedCategory,
                                  minPlayers: _minPlayers,
                                  maxPlayers: _maxPlayers,
                                );
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Filter button - Neo style
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
                    ),
                  ),

                  // Quick filter chips
                  QuickFilterRow(
                    selectedCategory: _selectedCategory,
                    selectedDurationRanges: _selectedDurationRanges,
                    onCategoryTap: (cat) {
                      setState(() {
                        _selectedCategory = _selectedCategory == cat
                            ? null
                            : cat;
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
                        setState(() => _selectedDurationRanges.remove(range));
                        widget.matchmakingCubit.searchGames(
                          query: _searchController.text,
                          category: _selectedCategory,
                          minPlayers: _minPlayers,
                          maxPlayers: _maxPlayers,
                        );
                      },
                    ),

                  Expanded(
                    child: _buildResultsBody(context, state, featured),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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

  Widget _buildResultsBody(
    BuildContext context,
    MatchmakingState state,
    List<BoardGameEntity> featured,
  ) {
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
            // Hero carousel
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
}
