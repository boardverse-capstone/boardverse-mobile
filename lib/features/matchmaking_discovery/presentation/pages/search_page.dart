import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../widgets/search/quick_filter_row.dart';
import '../widgets/search/search_error_retry_view.dart';
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
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: BlocBuilder<MatchmakingCubit, MatchmakingState>(
          builder: (context, state) {
            final games = state is MatchmakingSearchResults
                ? state.games
                : <BoardGameEntity>[];
            // Lấy top 5 game nổi bật (rating cao nhất hoặc đầu list)
            final featured = _pickFeaturedGames(games);

            return Column(
              children: [
                Padding(
                  padding: AppSpacing.paddingAllMd,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm game...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.matchmakingCubit.searchGames();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.radiusSmAll,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.radiusSmAll,
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.radiusSmAll,
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                          ),
                          onSubmitted: (value) {
                            widget.matchmakingCubit.searchGames(
                              query: value,
                              category: _selectedCategory,
                              minPlayers: _minPlayers,
                              maxPlayers: _maxPlayers,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Material(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: AppRadius.radiusSmAll,
                        child: InkWell(
                          borderRadius: AppRadius.radiusSmAll,
                          onTap: () => _showFilterDrawer(context),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm + 2),
                            child: Badge(
                              backgroundColor: theme.colorScheme.primary,
                              isLabelVisible: _selectedCategory != null ||
                                  _minPlayers != null ||
                                  _selectedDurationRanges.isNotEmpty,
                              child: Icon(
                                Icons.tune,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick filter chips pill-style (luôn hiển thị)
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
                Expanded(child: _buildResultsBody(context, state, featured)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Chọn tối đa 5 game nổi bật để hiển thị trên Hero Carousel.
  /// Ưu tiên: rating >= 4.5, sau đó đến category "Giải trí" (slug `giai-tri`),
  /// còn lại lấy theo thứ tự trong list. Nếu không có game nào thì trả empty.
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
      return SearchErrorRetryView(
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
            // Hero carousel (chỉ hiện khi có featured games)
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
              padding: AppSpacing.paddingAllMd,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  // Tỉ lệ card khớp với AspectRatio 4/5 bên trong BoardGameCard
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