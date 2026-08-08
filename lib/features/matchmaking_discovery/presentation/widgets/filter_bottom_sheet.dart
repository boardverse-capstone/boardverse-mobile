import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/search_filter_entity.dart';
import 'filter/filter_bottom_bar.dart';
import 'filter/filter_category_grid.dart';
import 'filter/filter_duration_grid.dart';
import 'filter/filter_header.dart';
import 'filter/filter_player_slider.dart';
import 'filter/filter_section_title.dart';

/// Neo-brutalism Filter Bottom Sheet — pattern DraggableScrollableSheet.
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
      barrierColor: AppColors.black.withValues(alpha: 0.6),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.7, 0.92],
      builder: (context, scrollController) {
        return Stack(
          children: [
            // Hard shadow offset
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.only(top: 3, left: 3, right: 3),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
              ),
            ),
            // Main container
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                child: Column(
                  children: [
                    FilterHeader(onReset: _reset),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
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
                            trailing: '${_durationRanges.length} đã chọn',
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
                                '${_playerRange.start.toInt()}-${_playerRange.end.toInt()}',
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
              ),
            ),
          ],
        );
      },
    );
  }
}
