import 'package:flutter/material.dart';

import '../../domain/entities/game_category_entity.dart';

/// Search bar widget for board game search
class GameSearchBar extends StatefulWidget {
  final String? initialQuery;
  final List<GameCategoryEntity> categories;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<String?>? onCategoryChanged;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;

  const GameSearchBar({
    super.key,
    this.initialQuery,
    this.categories = const [],
    this.onQueryChanged,
    this.onCategoryChanged,
    this.onSearch,
    this.onClear,
  });

  @override
  State<GameSearchBar> createState() => _GameSearchBarState();
}

class _GameSearchBarState extends State<GameSearchBar> {
  late TextEditingController _controller;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Text Field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm game...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onClear?.call();
                      widget.onQueryChanged?.call('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
          onChanged: widget.onQueryChanged,
          onSubmitted: (_) => widget.onSearch?.call(),
        ),
        
        const SizedBox(height: 12),
        
        // Category Filter Chips
        if (widget.categories.isNotEmpty) ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.categories.length + 1,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = null);
                      widget.onCategoryChanged?.call(null);
                    },
                  );
                }
                
                final category = widget.categories[index - 1];
                return FilterChip(
                  label: Text(category.name),
                  avatar: Icon(
                    _getCategoryIcon(category.iconName),
                    size: 18,
                  ),
                  selected: _selectedCategory == category.id,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category.id : null;
                    });
                    widget.onCategoryChanged?.call(
                      selected ? category.id : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'account_tree':
        return Icons.account_tree;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'celebration':
        return Icons.celebration;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.games;
    }
  }
}
