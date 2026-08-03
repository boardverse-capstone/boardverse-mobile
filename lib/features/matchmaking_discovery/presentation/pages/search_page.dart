import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/game_category_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/animated_section_header.dart';
import '../widgets/board_game_card.dart';
import '../widgets/empty_board_game_illustration.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/game_skeleton.dart';
import '../widgets/hero_banner_carousel.dart';
import '../widgets/quick_filter_chip.dart';
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

  final Set<String> _selectedCategoryIds = <String>{};
  final Set<DurationRange> _selectedDurationRanges = <DurationRange>{};
  List<GameCategoryEntity> _availableCategories = const [];

  final List<String> _categories = [
    'Social Deduction',
    'Strategy',
    'Party',
    'Cooperative',
    'Card Game',
    'Abstract',
  ];

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
    final currentState = widget.matchmakingCubit.state;
    if (currentState is MatchmakingSearchResults &&
        currentState.games.isNotEmpty &&
        currentState.categories.isNotEmpty) {
      setState(() => _availableCategories = currentState.categories);
      return;
    }
    widget.matchmakingCubit.searchGames();
    widget.matchmakingCubit.loadCategories();
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
      categories: _categories,
      selectedCategoryIds: _selectedCategoryIds,
      availableCategories: _availableCategories,
      selectedDurationRanges: _selectedDurationRanges,
      onApply: (category, minP, maxP, categoryIds, durationRanges) {
        setState(() {
          _selectedCategory = category;
          _minPlayers = minP;
          _maxPlayers = maxP;
          _selectedCategoryIds
            ..clear()
            ..addAll(categoryIds);
          _selectedDurationRanges
            ..clear()
            ..addAll(durationRanges);
        });
        if (_selectedCategoryIds.isNotEmpty ||
            _selectedDurationRanges.isNotEmpty) {
          widget.matchmakingCubit.searchWithFilterPaged(
            query: _searchController.text,
            categoryIds: _selectedCategoryIds.toList(),
            playerCount: minP,
            durationRanges: _selectedDurationRanges.toList(),
          );
        } else {
          widget.matchmakingCubit.searchGames(
            query: _searchController.text,
            category: category,
            minPlayers: minP,
            maxPlayers: maxP,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: BlocListener<MatchmakingCubit, MatchmakingState>(
          listenWhen: (prev, curr) =>
              curr is MatchmakingSearchResults && curr.categories.isNotEmpty,
          listener: (context, state) {
            if (state is MatchmakingSearchResults) {
              setState(() => _availableCategories = state.categories);
            }
          },
          child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
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
                                isLabelVisible:
                                    _selectedCategory != null ||
                                    _minPlayers != null ||
                                    _selectedCategoryIds.isNotEmpty ||
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
                  _QuickFilterRow(
                    selectedCategory: _selectedCategory,
                    selectedCategoryIds: _selectedCategoryIds,
                    selectedDurationRanges: _selectedDurationRanges,
                    availableCategories: _availableCategories,
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
                    onCategoryIdTap: (id) {
                      setState(() {
                        if (_selectedCategoryIds.contains(id)) {
                          _selectedCategoryIds.remove(id);
                        } else {
                          _selectedCategoryIds.add(id);
                        }
                      });
                      _applyPagedSearch();
                    },
                    onDurationTap: (range) {
                      setState(() {
                        if (_selectedDurationRanges.contains(range)) {
                          _selectedDurationRanges.remove(range);
                        } else {
                          _selectedDurationRanges.add(range);
                        }
                      });
                      _applyPagedSearch();
                    },
                  ),
                  if (_selectedCategory != null ||
                      _minPlayers != null ||
                      _selectedCategoryIds.isNotEmpty ||
                      _selectedDurationRanges.isNotEmpty)
                    _ActiveFilterBar(
                      selectedCategory: _selectedCategory,
                      minPlayers: _minPlayers,
                      selectedCategoryIds: _selectedCategoryIds,
                      availableCategories: _availableCategories,
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
                      onRemoveCategoryId: (id) {
                        setState(() => _selectedCategoryIds.remove(id));
                        _applyPagedSearch();
                      },
                      onRemoveDuration: (range) {
                        setState(() => _selectedDurationRanges.remove(range));
                        _applyPagedSearch();
                      },
                    ),
                  Expanded(child: _buildResultsBody(context, state, featured)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Chọn tối đa 5 game nổi bật để hiển thị trên Hero Carousel.
  /// Ưu tiên: rating >= 4.5, sau đó đến category "Party", còn lại lấy
  /// theo thứ tự trong list. Nếu không có game nào thì trả empty.
  List<BoardGameEntity> _pickFeaturedGames(List<BoardGameEntity> games) {
    if (games.isEmpty) return const [];
    final sorted = [...games]
      ..sort((a, b) {
        final aScore =
            (a.rating >= 4.5 ? 2 : 0) + (a.category == 'Party' ? 1 : 0);
        final bScore =
            (b.rating >= 4.5 ? 2 : 0) + (b.category == 'Party' ? 1 : 0);
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
      return _ErrorRetryView(
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
            _selectedCategoryIds.clear();
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

  void _applyPagedSearch() {
    if (_selectedCategoryIds.isNotEmpty || _selectedDurationRanges.isNotEmpty) {
      widget.matchmakingCubit.searchWithFilterPaged(
        query: _searchController.text,
        categoryIds: _selectedCategoryIds.toList(),
        durationRanges: _selectedDurationRanges.toList(),
      );
    } else {
      widget.matchmakingCubit.searchGames(query: _searchController.text);
    }
  }
}

/// Thanh chip filter đang active — dễ thấy và dễ xoá.
class _ActiveFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final int? minPlayers;
  final Set<String> selectedCategoryIds;
  final List<GameCategoryEntity> availableCategories;
  final Set<DurationRange> selectedDurationRanges;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemovePlayerCount;
  final void Function(String id) onRemoveCategoryId;
  final void Function(DurationRange range) onRemoveDuration;

  const _ActiveFilterBar({
    required this.selectedCategory,
    required this.minPlayers,
    required this.selectedCategoryIds,
    required this.availableCategories,
    required this.selectedDurationRanges,
    required this.onRemoveCategory,
    required this.onRemovePlayerCount,
    required this.onRemoveCategoryId,
    required this.onRemoveDuration,
  });

  String _durationLabel(DurationRange range) {
    switch (range) {
      case DurationRange.under30:
        return '< 30 phút';
      case DurationRange.thirtyToSixty:
        return '30-60 phút';
      case DurationRange.over60:
        return '> 60 phút';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxxl,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.paddingHorizontalMd,
        children: [
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text(selectedCategory!),
                onDeleted: onRemoveCategory,
              ),
            ),
          if (minPlayers != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text('$minPlayers+ người'),
                onDeleted: onRemovePlayerCount,
              ),
            ),
          for (final id in selectedCategoryIds)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text(
                  availableCategories
                      .firstWhere(
                        (c) => c.id == id,
                        orElse: () => GameCategoryEntity(id: id, name: id),
                      )
                      .name,
                ),
                onDeleted: () => onRemoveCategoryId(id),
              ),
            ),
          for (final range in selectedDurationRanges)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: InputChip(
                label: Text(_durationLabel(range)),
                onDeleted: () => onRemoveDuration(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickFilterRow extends StatelessWidget {
  final String? selectedCategory;
  final Set<String> selectedCategoryIds;
  final Set<DurationRange> selectedDurationRanges;
  final List<GameCategoryEntity> availableCategories;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<String> onCategoryIdTap;
  final ValueChanged<DurationRange> onDurationTap;

  const _QuickFilterRow({
    required this.selectedCategory,
    required this.selectedCategoryIds,
    required this.selectedDurationRanges,
    required this.availableCategories,
    required this.onCategoryTap,
    required this.onCategoryIdTap,
    required this.onDurationTap,
  });

  String _durationLabel(DurationRange range) {
    switch (range) {
      case DurationRange.under30:
        return '< 30 phút';
      case DurationRange.thirtyToSixty:
        return '30-60 phút';
      case DurationRange.over60:
        return '> 60 phút';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <QuickFilterItem>[];

    items.add(
      QuickFilterItem(
        label: 'Party',
        icon: Icons.celebration,
        selected: selectedCategory == 'Party',
        onTap: () => onCategoryTap('Party'),
      ),
    );
    items.add(
      QuickFilterItem(
        label: 'Strategy',
        icon: Icons.psychology,
        selected: selectedCategory == 'Strategy',
        onTap: () => onCategoryTap('Strategy'),
      ),
    );
    items.add(
      QuickFilterItem(
        label: 'Co-op',
        icon: Icons.handshake,
        selected: selectedCategory == 'Cooperative',
        onTap: () => onCategoryTap('Cooperative'),
      ),
    );

    for (final range in DurationRange.values) {
      items.add(
        QuickFilterItem(
          label: _durationLabel(range),
          icon: Icons.timer_outlined,
          selected: selectedDurationRanges.contains(range),
          onTap: () => onDurationTap(range),
        ),
      );
    }

    for (final cat in availableCategories.take(3)) {
      items.add(
        QuickFilterItem(
          label: cat.name,
          icon: Icons.category_outlined,
          selected: selectedCategoryIds.contains(cat.id),
          onTap: () => onCategoryIdTap(cat.id),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: QuickFilterChipBar(items: items),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetryView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: AppSpacing.huge + AppSpacing.xs,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
