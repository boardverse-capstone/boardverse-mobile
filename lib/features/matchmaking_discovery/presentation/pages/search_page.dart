import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/board_game_card.dart';
import 'board_game_detail_page.dart';

class SearchPage extends StatefulWidget {
  final MatchmakingCubit matchmakingCubit;

  const SearchPage({
    super.key,
    required this.matchmakingCubit,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  int? _minPlayers;
  int? _maxPlayers;

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
    widget.matchmakingCubit.searchGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        categories: _categories,
        onApply: (category, minP, maxP) {
          setState(() {
            _selectedCategory = category;
            _minPlayers = minP;
            _maxPlayers = maxP;
          });
          widget.matchmakingCubit.searchGames(
            query: _searchController.text,
            category: category,
            minPlayers: minP,
            maxPlayers: maxP,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tìm kiếm Board Game'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                          borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _showFilterDrawer(context),
                    icon: Badge(
                      isLabelVisible:
                          _selectedCategory != null || _minPlayers != null,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedCategory != null || _minPlayers != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_selectedCategory != null)
                      Chip(
                        label: Text(_selectedCategory!),
                        onDeleted: () {
                          setState(() => _selectedCategory = null);
                          widget.matchmakingCubit.searchGames(
                            query: _searchController.text,
                          );
                        },
                      ),
                    if (_minPlayers != null)
                      Chip(
                        label: Text('$_minPlayers+ người'),
                        onDeleted: () {
                          setState(() {
                            _minPlayers = null;
                            _maxPlayers = null;
                          });
                          widget.matchmakingCubit.searchGames(
                            query: _searchController.text,
                          );
                        },
                      ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
                builder: (context, state) {
                  if (state is MatchmakingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MatchmakingFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => widget.matchmakingCubit.searchGames(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MatchmakingSearchResults) {
                    if (state.games.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('Không tìm thấy game phù hợp'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.games.length,
                      itemBuilder: (context, index) {
                        final game = state.games[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BoardGameCard(
                            game: game,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BoardGameDetailPage(
                                      gameId: game.id,
                                      matchmakingCubit: widget.matchmakingCubit,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final int? minPlayers;
  final int? maxPlayers;
  final List<String> categories;
  final Function(String?, int?, int?) onApply;

  const _FilterBottomSheet({
    this.selectedCategory,
    this.minPlayers,
    this.maxPlayers,
    required this.categories,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _category;
  late RangeValues _playerRange;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _playerRange = RangeValues(
      (widget.minPlayers ?? 2).toDouble(),
      (widget.maxPlayers ?? 20).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => widget.onApply(null, null, null),
                child: const Text('Xóa lọc'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Thể loại',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.categories.map((cat) {
              final isSelected = _category == cat;
              return FilterChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _category = selected ? cat : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Số người chơi: ${_playerRange.start.toInt()} - ${_playerRange.end.toInt()}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: _playerRange,
            min: 2,
            max: 20,
            divisions: 18,
            labels: RangeLabels(
              _playerRange.start.toInt().toString(),
              _playerRange.end.toInt().toString(),
            ),
            onChanged: (values) {
              setState(() => _playerRange = values);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onApply(
                _category,
                _playerRange.start.toInt(),
                _playerRange.end.toInt(),
              ),
              child: const Text('Áp dụng'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
