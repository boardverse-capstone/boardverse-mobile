import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/game_category_entity.dart';
import '../../utils/category_icon_mapper.dart';
import 'filter_selectable_card.dart';

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

class FilterCategoryGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onTap;

  const FilterCategoryGrid({
    super.key,
    required this.selected,
    required this.onTap,
  });

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
        return FilterSelectableCard(
          icon: CategoryIconMapper.iconFor(cat),
          label: cat.name,
          selected: isSelected,
          onTap: () => onTap(cat.name),
        );
      },
    );
  }
}