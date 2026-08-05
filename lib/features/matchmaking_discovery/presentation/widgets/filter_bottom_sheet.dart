import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/game_category_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../utils/category_icon_mapper.dart';

/// Filter Bottom Sheet hiện đại — pattern DraggableScrollableSheet:
///
/// - Mở ở peek height 60%, kéo lên full 92%
/// - Drag handle + sticky header (title + nút Xoá lọc)
/// - Body scroll được với 3 sections:
///   1. Thể loại — Grid 2 cột card-style (hardcode 6 thể loại VI)
///   2. Thời gian — 3 time-block cards
///   3. Số người chơi — Slider có bubble preview
/// - Sticky bottom bar: Reset + Áp dụng (hiển thị số filter đang chọn)
///
/// Lưu ý: Danh sách thể loại hiện đang là hardcode VI (theo seed backend)
/// để tránh gọi thêm API `/board-games/categories` và tránh trùng với
/// quick filter row đang hiển thị cùng data. Icon được resolve qua
/// [CategoryIconMapper] — key anchor trùng slug backend (`an-vai`, ...) để
/// khi backend đổi tên vẫn map được.
class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final int? minPlayers;
  final int? maxPlayers;
  final Set<DurationRange> selectedDurationRanges;
  final void Function(
    String? category,
    int? minPlayers,
    int? maxPlayers,
    Set<DurationRange> durationRanges,
  )
  onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    this.minPlayers,
    this.maxPlayers,
    required this.selectedDurationRanges,
    required this.onApply,
  });

  /// Helper để show filter sheet — bọc showModalBottomSheet.
  static Future<void> show(
    BuildContext context, {
    required String? selectedCategory,
    required int? minPlayers,
    required int? maxPlayers,
    required Set<DurationRange> selectedDurationRanges,
    required void Function(String?, int?, int?, Set<DurationRange>) onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      useSafeArea: true,
      builder: (ctx) => FilterBottomSheet(
        selectedCategory: selectedCategory,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        selectedDurationRanges: selectedDurationRanges,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _category;
  late RangeValues _playerRange;
  late Set<DurationRange> _durationRanges;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _playerRange = RangeValues(
      (widget.minPlayers ?? 1).toDouble(),
      (widget.maxPlayers ?? 20).toDouble(),
    );
    _durationRanges = {...widget.selectedDurationRanges};
  }

  int _totalSelected() {
    var n = 0;
    if (_category != null) n++;
    n += _durationRanges.length;
    return n;
  }

  void _reset() {
    setState(() {
      _category = null;
      _playerRange = const RangeValues(1, 20);
      _durationRanges = <DurationRange>{};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.radiusXl),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _Header(onReset: _reset),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  children: [
                    _SectionTitle(
                      icon: Icons.category_outlined,
                      label: 'Thể loại',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CategoryGrid(
                      selected: _category,
                      onTap: (cat) => setState(() {
                        _category = _category == cat ? null : cat;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(
                      icon: Icons.schedule,
                      label: 'Thời gian chơi',
                      trailing: '(${_durationRanges.length} đã chọn)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationGrid(
                      selected: _durationRanges,
                      onToggle: (r) => setState(() {
                        if (_durationRanges.contains(r)) {
                          _durationRanges.remove(r);
                        } else {
                          _durationRanges.add(r);
                        }
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(
                      icon: Icons.groups_outlined,
                      label: 'Số người chơi',
                      trailing:
                          '${_playerRange.start.toInt()}–${_playerRange.end.toInt()}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PlayerSlider(
                      values: _playerRange,
                      onChanged: (v) => setState(() => _playerRange = v),
                    ),
                  ],
                ),
              ),
              _BottomBar(
                totalSelected: _totalSelected(),
                onApply: () {
                  widget.onApply(
                    _category,
                    _playerRange.start.toInt(),
                    _playerRange.end.toInt(),
                    _durationRanges,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _Header extends StatelessWidget {
  final VoidCallback onReset;

  const _Header({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, size: AppSpacing.lg),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Bộ lọc',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: AppSpacing.md),
                label: const Text('Đặt lại'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;

  const _SectionTitle({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: AppSpacing.md, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.radiusFullAll,
            ),
            child: Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// CATEGORY GRID (2 cột, hardcode 6 thể loại VI)
// ============================================================================

/// Danh sách thể loại hiển thị trong filter sheet — hardcode VI theo seed
/// backend (`an-vai`, `chien-thuat`, ...). Slug được truyền kèm để
/// [CategoryIconMapper] resolve icon đúng (không phụ thuộc ngôn ngữ).
const List<GameCategoryEntity> _kHardcodedCategories = <GameCategoryEntity>[
  GameCategoryEntity(id: 'an-vai', name: 'Ẩn vai', slug: 'an-vai'),
  GameCategoryEntity(
    id: 'chien-thuat',
    name: 'Chiến thuật',
    slug: 'chien-thuat',
  ),
  GameCategoryEntity(id: 'giai-tri', name: 'Giải trí', slug: 'giai-tri'),
  GameCategoryEntity(id: 'hop-tac', name: 'Hợp tác', slug: 'hop-tac'),
  GameCategoryEntity(id: 'doi-khang', name: 'Đối kháng', slug: 'doi-khang'),
  GameCategoryEntity(id: 'phieu-luu', name: 'Phiêu lưu', slug: 'phieu-luu'),
];

class _CategoryGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onTap;

  const _CategoryGrid({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kHardcodedCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, index) {
        final cat = _kHardcodedCategories[index];
        final isSelected = selected == cat.name;
        return _SelectableCard(
          icon: CategoryIconMapper.iconFor(cat),
          label: cat.name,
          selected: isSelected,
          onTap: () => onTap(cat.name),
        );
      },
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSmAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusSmAll,
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: AppRadius.radiusXsAll,
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.md,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  size: AppSpacing.md,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DURATION GRID (3 cards lớn)
// ============================================================================

class _DurationGrid extends StatelessWidget {
  final Set<DurationRange> selected;
  final ValueChanged<DurationRange> onToggle;

  const _DurationGrid({required this.selected, required this.onToggle});

  static const _items = <(DurationRange, IconData, String)>[
    (DurationRange.under30, Icons.bolt, '< 30 phút'),
    (DurationRange.thirtyToSixty, Icons.schedule, '30-60 phút'),
    (DurationRange.over60, Icons.hourglass_bottom, '> 60 phút'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (range, icon, label) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _DurationRow(
              icon: icon,
              label: label,
              selected: selected.contains(range),
              onTap: () => onToggle(range),
            ),
          ),
      ],
    );
  }
}

class _DurationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSmAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.radiusSmAll,
            border: Border.all(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 1),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: AppRadius.radiusXsAll,
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.md + 2,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: AppSpacing.lg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PLAYER SLIDER
// ============================================================================

class _PlayerSlider extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  const _PlayerSlider({required this.values, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PlayerBubble(label: 'Min', value: values.start.toInt()),
            ),
            Container(
              width: AppSpacing.md,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _PlayerBubble(label: 'Max', value: values.end.toInt()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.primary.withValues(
              alpha: 0.18,
            ),
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: RangeSlider(
            values: values,
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _PlayerBubble extends StatelessWidget {
  final String label;
  final int value;

  const _PlayerBubble({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs + 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Text(
                  'người',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM BAR
// ============================================================================

class _BottomBar extends StatelessWidget {
  final int totalSelected;
  final VoidCallback onApply;

  const _BottomBar({required this.totalSelected, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadius.radiusFullAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: AppSpacing.sm + 2,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '$totalSelected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
