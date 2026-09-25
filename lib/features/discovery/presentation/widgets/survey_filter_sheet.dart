import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/entities/game_category_discovery_entity.dart';
import 'weight_range_selector.dart';

/// Modal bottom sheet chứa bộ lọc cho survey — neo-brutalism style.
///
/// Header có gradient + nút "Đặt lại" pill.
/// Body có search field, player count selector, weight, duration, categories.
/// Apply button lớn full-width với gradient cam.
class SurveyFilterSheet extends StatefulWidget {
  final DiscoveryRequestEntity currentRequest;
  final List<GameCategoryDiscoveryEntity> categories;
  final ValueChanged<DiscoveryRequestEntity> onApply;

  const SurveyFilterSheet({
    super.key,
    required this.currentRequest,
    required this.categories,
    required this.onApply,
  });

  @override
  State<SurveyFilterSheet> createState() => _SurveyFilterSheetState();
}

class _SurveyFilterSheetState extends State<SurveyFilterSheet> {
  late int? _playerCount;
  late List<int> _weightRanges;
  late List<String> _preferredDurations;
  late List<String> _selectedCategoryIds;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.currentRequest.playerCount;
    _weightRanges = List.from(widget.currentRequest.weightRanges ?? []);
    _preferredDurations =
        List.from(widget.currentRequest.preferredDurations ?? []);
    _selectedCategoryIds =
        List.from(widget.currentRequest.categoryIds ?? []);
    _searchController = TextEditingController(
      text: widget.currentRequest.searchKeyword ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: borderColor, width: 3),
              left: BorderSide(color: borderColor, width: 3),
              right: BorderSide(color: borderColor, width: 3),
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BỘ LỌC',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Tinh chỉnh gợi ý',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ResetPillButton(onPressed: _resetFilters),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Search
                    _SearchField(controller: _searchController),
                    const SizedBox(height: AppSpacing.lg),
                    // Player count
                    _SectionTitle(
                      title: 'Số người chơi',
                      icon: Icons.people_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PlayerCountSelector(
                      value: _playerCount,
                      onChanged: (v) => setState(() => _playerCount = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Weight range
                    _SectionTitle(
                      title: 'Độ phức tạp',
                      icon: Icons.scale_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    WeightRangeSelector(
                      selectedValues: _weightRanges,
                      onChanged: (v) => setState(() => _weightRanges = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Duration
                    _SectionTitle(
                      title: 'Thời gian chơi',
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DurationSelector(
                      selected: _preferredDurations,
                      onChanged: (v) =>
                          setState(() => _preferredDurations = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Categories
                    _SectionTitle(
                      title: 'Thể loại',
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: widget.categories.map((cat) {
                        final selected = _selectedCategoryIds.contains(cat.id);
                        return _CategoryChip(
                          label: cat.name,
                          isSelected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.remove(cat.id);
                              } else {
                                _selectedCategoryIds.add(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              // Apply button
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderColor, width: 2),
                  ),
                ),
                child: _ApplyButton(onPressed: _applyFilters),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _playerCount = null;
      _weightRanges = [];
      _preferredDurations = [];
      _selectedCategoryIds = [];
      _searchController.clear();
    });
  }

  void _applyFilters() {
    final request = DiscoveryRequestEntity(
      playerCount: _playerCount,
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
      preferredDurations:
          _preferredDurations.isEmpty ? null : _preferredDurations,
      weightRanges: _weightRanges.isEmpty ? null : _weightRanges,
      searchKeyword:
          _searchController.text.isEmpty ? null : _searchController.text,
    );
    widget.onApply(request);
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search field
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm game...',
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reset pill button
// ─────────────────────────────────────────────────────────────────────────────

class _ResetPillButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ResetPillButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                'Đặt lại',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player count selector
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerCountSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _PlayerCountSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [null, 2, 3, 4, 5, 6, 7, 8].map((v) {
        final label = v == null ? 'Tất cả' : '$v người';
        final isSelected = value == v;
        return _NeoChoiceChip(
          label: label,
          isSelected: isSelected,
          color: AppColors.primary,
          onTap: () => onChanged(v),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duration selector
// ─────────────────────────────────────────────────────────────────────────────

class _DurationSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _DurationSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (value: 'under30', label: '< 30 phút'),
    (value: '30to60', label: '30–60 phút'),
    (value: 'over60', label: '> 60 phút'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _options.map((opt) {
        final isSelected = selected.contains(opt.value);
        return _NeoChoiceChip(
          label: opt.label,
          isSelected: isSelected,
          color: AppColors.secondary,
          onTap: () {
            final next = List<String>.from(selected);
            if (isSelected) {
              next.remove(opt.value);
            } else {
              next.add(opt.value);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic neo choice chip
// ─────────────────────────────────────────────────────────────────────────────

class _NeoChoiceChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NeoChoiceChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NeoChoiceChip> createState() => _NeoChoiceChipState();
}

class _NeoChoiceChipState extends State<_NeoChoiceChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    final bgColor = widget.isSelected
        ? widget.color
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    final fgColor = widget.isSelected ? Colors.white : widget.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? borderColor : widget.color.withValues(alpha: 0.3),
              width: widget.isSelected
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isSelected
                ? null
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: widget.color.withValues(alpha: 0.2),
                  ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip (multi-select)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    final bgColor = isSelected
        ? AppColors.accent
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    final fgColor = isSelected
        ? const Color(0xFF3D1E00)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? borderColor : AppColors.borderLight,
            width: isSelected
                ? NeoBrutalismTheme.borderWidthBold
                : NeoBrutalismTheme.borderWidth,
          ),
          boxShadow: isSelected
              ? NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.accent.withValues(alpha: 0.4),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 12,
                color: Color(0xFF3D1E00),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: fgColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply button (gradient CTA)
// ─────────────────────────────────────────────────────────────────────────────

class _ApplyButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _ApplyButton({required this.onPressed});

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primary, AppColors.accentDark],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'ÁP DỤNG',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
