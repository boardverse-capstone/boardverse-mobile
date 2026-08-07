import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/game_category_entity.dart';
import '../../../domain/entities/search_filter_entity.dart';
import '../../utils/category_icon_mapper.dart';
import '../quick_filter_chip.dart';

/// Danh sách thể loại hiển thị trong quick filter row — hardcode VI theo
/// seed backend (`an-vai`, `chien-thuat`, ...). Icon lấy qua
/// [CategoryIconMapper]. Cùng nguồn với grid trong FilterBottomSheet,
/// tránh trùng UI và không phải gọi API `/board-games/categories` riêng.
const List<GameCategoryEntity> _kHardcodedCategories = <GameCategoryEntity>[
  GameCategoryEntity(id: 'an-vai', name: 'Ẩn vai', slug: 'an-vai'),
  GameCategoryEntity(id: 'chien-thuat', name: 'Chiến thuật', slug: 'chien-thuat'),
  GameCategoryEntity(id: 'giai-tri', name: 'Giải trí', slug: 'giai-tri'),
  GameCategoryEntity(id: 'hop-tac', name: 'Hợp tác', slug: 'hop-tac'),
  GameCategoryEntity(id: 'doi-khang', name: 'Đối kháng', slug: 'doi-khang'),
  GameCategoryEntity(id: 'phieu-luu', name: 'Phiêu lưu', slug: 'phieu-luu'),
];

class QuickFilterRow extends StatelessWidget {
  final String? selectedCategory;
  final Set<DurationRange> selectedDurationRanges;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<DurationRange> onDurationTap;

  const QuickFilterRow({
    super.key,
    required this.selectedCategory,
    required this.selectedDurationRanges,
    required this.onCategoryTap,
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

    // Category chips — dùng cùng hardcoded list với FilterBottomSheet,
    // không gọi API backend. Icon resolve qua CategoryIconMapper.
    for (final cat in _kHardcodedCategories) {
      items.add(
        QuickFilterItem(
          label: cat.name,
          icon: CategoryIconMapper.iconFor(cat),
          selected: selectedCategory == cat.name,
          onTap: () => onCategoryTap(cat.name),
        ),
      );
    }

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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: QuickFilterChipBar(items: items),
    );
  }
}