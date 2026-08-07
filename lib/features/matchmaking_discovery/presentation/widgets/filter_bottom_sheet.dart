import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/search_filter_entity.dart';
import 'filter/filter_bottom_bar.dart';
import 'filter/filter_category_grid.dart';
import 'filter/filter_duration_grid.dart';
import 'filter/filter_header.dart';
import 'filter/filter_player_slider.dart';
import 'filter/filter_section_title.dart';

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
              FilterHeader(onReset: _reset),
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
                    const FilterSectionTitle(
                      icon: Icons.category_outlined,
                      label: 'Thể loại',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilterCategoryGrid(
                      selected: _category,
                      onTap: (cat) => setState(() {
                        _category = _category == cat ? null : cat;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilterSectionTitle(
                      icon: Icons.schedule,
                      label: 'Thời gian chơi',
                      trailing: '(${_durationRanges.length} đã chọn)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilterDurationGrid(
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
                    FilterSectionTitle(
                      icon: Icons.groups_outlined,
                      label: 'Số người chơi',
                      trailing:
                          '${_playerRange.start.toInt()}–${_playerRange.end.toInt()}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilterPlayerSlider(
                      values: _playerRange,
                      onChanged: (v) => setState(() => _playerRange = v),
                    ),
                  ],
                ),
              ),
              FilterBottomBar(
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