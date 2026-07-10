import 'package:flutter/material.dart';

import '../../domain/entities/search_filter_entity.dart';

/// Widget filter chips cho tìm kiếm nâng cao
class GameFilterChips extends StatelessWidget {
  final SearchFilterEntity currentFilter;
  final ValueChanged<SearchFilterEntity> onFilterChanged;
  final VoidCallback? onClearAll;

  const GameFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Player Count Filter
        _buildPlayerCountChip(context, theme),
        
        // Time Duration Filter
        _buildTimeFilterChip(context, theme),
        
        // Karma Filter
        _buildKarmaFilterChip(context, theme),
        
        // Clear All Button
        if (currentFilter.hasActiveFilters && onClearAll != null)
          ActionChip(
            avatar: const Icon(Icons.clear_all, size: 18),
            label: const Text('Xóa lọc'),
            onPressed: onClearAll,
          ),
      ],
    );
  }

  Widget _buildPlayerCountChip(BuildContext context, ThemeData theme) {
    final hasFilter = currentFilter.minPlayers != null || currentFilter.maxPlayers != null;
    final label = _getPlayerCountLabel();

    return FilterChip(
      avatar: Icon(
        Icons.people,
        size: 18,
        color: hasFilter ? theme.colorScheme.primary : null,
      ),
      label: Text(label),
      selected: hasFilter,
      onSelected: (_) => _showPlayerCountPicker(context),
    );
  }

  Widget _buildTimeFilterChip(BuildContext context, ThemeData theme) {
    final hasFilter = currentFilter.estimatedMinutesMax != null;
    final label = hasFilter
        ? '≤${currentFilter.estimatedMinutesMax} phút'
        : 'Thời gian';

    return FilterChip(
      avatar: Icon(
        Icons.timer,
        size: 18,
        color: hasFilter ? theme.colorScheme.primary : null,
      ),
      label: Text(label),
      selected: hasFilter,
      onSelected: (_) => _showTimePicker(context),
    );
  }

  Widget _buildKarmaFilterChip(BuildContext context, ThemeData theme) {
    final hasFilter = currentFilter.minKarma != null;
    final label = hasFilter
        ? 'Karma ≥${currentFilter.minKarma}'
        : 'Karma';

    return FilterChip(
      avatar: Icon(
        Icons.star,
        size: 18,
        color: hasFilter ? Colors.amber : null,
      ),
      label: Text(label),
      selected: hasFilter,
      onSelected: (_) => _showKarmaPicker(context),
    );
  }

  String _getPlayerCountLabel() {
    final min = currentFilter.minPlayers;
    final max = currentFilter.maxPlayers;

    if (min != null && max != null) {
      return '$min-$max người';
    } else if (min != null) {
      return '$min+ người';
    } else if (max != null) {
      return '≤$max người';
    }
    return 'Số người';
  }

  void _showPlayerCountPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PlayerCountPicker(
        initialMin: currentFilter.minPlayers,
        initialMax: currentFilter.maxPlayers,
        onSelected: (min, max) {
          onFilterChanged(currentFilter.copyWith(
            minPlayers: min,
            maxPlayers: max,
            clearMinPlayers: min == null,
            clearMaxPlayers: max == null,
          ));
        },
      ),
    );
  }

  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TimePicker(
        initialValue: currentFilter.estimatedMinutesMax,
        onSelected: (value) {
          onFilterChanged(currentFilter.copyWith(
            estimatedMinutesMax: value,
            clearEstimatedMinutesMax: value == null,
          ));
        },
      ),
    );
  }

  void _showKarmaPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _KarmaPicker(
        initialValue: currentFilter.minKarma,
        onSelected: (value) {
          onFilterChanged(currentFilter.copyWith(
            minKarma: value,
            clearMinKarma: value == null,
          ));
        },
      ),
    );
  }
}

// ─── Picker Widgets ─────────────────────────────────────────────────────────

class _PlayerCountPicker extends StatefulWidget {
  final int? initialMin;
  final int? initialMax;
  final void Function(int?, int?) onSelected;

  const _PlayerCountPicker({
    this.initialMin,
    this.initialMax,
    required this.onSelected,
  });

  @override
  State<_PlayerCountPicker> createState() => _PlayerCountPickerState();
}

class _PlayerCountPickerState extends State<_PlayerCountPicker> {
  late int? _min;
  late int? _max;

  final _playerOptions = List.generate(16, (i) => i + 2); // 2-17 players

  @override
  void initState() {
    super.initState();
    _min = widget.initialMin;
    _max = widget.initialMax;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số người chơi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _min,
                  decoration: const InputDecoration(
                    labelText: 'Tối thiểu',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Không chọn')),
                    ..._playerOptions.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('$p người'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _min = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _max,
                  decoration: const InputDecoration(
                    labelText: 'Tối đa',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Không chọn')),
                    ..._playerOptions.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('$p người'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _max = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSelected(_min, _max);
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatefulWidget {
  final int? initialValue;
  final void Function(int?) onSelected;

  const _TimePicker({
    this.initialValue,
    required this.onSelected,
  });

  @override
  State<_TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<_TimePicker> {
  late int? _value;

  final _timeOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thời gian chơi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _value == null,
                onSelected: (_) => setState(() => _value = null),
              ),
              ..._timeOptions.map((t) => ChoiceChip(
                    label: Text('$t phút'),
                    selected: _value == t,
                    onSelected: (_) => setState(() => _value = t),
                  )),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSelected(_value);
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KarmaPicker extends StatefulWidget {
  final int? initialValue;
  final void Function(int?) onSelected;

  const _KarmaPicker({
    this.initialValue,
    required this.onSelected,
  });

  @override
  State<_KarmaPicker> createState() => _KarmaPickerState();
}

class _KarmaPickerState extends State<_KarmaPicker> {
  late int? _value;

  final _karmaOptions = [50, 60, 70, 80, 90, 95];

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điểm Karma tối thiểu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Lọc theo điểm uy tín của người chơi (BR-10)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _value == null,
                onSelected: (_) => setState(() => _value = null),
              ),
              ..._karmaOptions.map((k) => ChoiceChip(
                    label: Text('≥$k'),
                    selected: _value == k,
                    onSelected: (_) => setState(() => _value = k),
                  )),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSelected(_value);
                Navigator.pop(context);
              },
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }
}
