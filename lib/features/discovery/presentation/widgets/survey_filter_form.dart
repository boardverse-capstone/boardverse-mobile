import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/entities/game_category_discovery_entity.dart';
import 'weight_range_selector.dart';

/// Form bộ lọc khảo sát — dùng inline trên trang khảo sát.
///
/// Trước đây nội dung này được bọc trong `DraggableScrollableSheet` (popup).
/// Nay đã được tách ra để nhúng trực tiếp vào `_SoloTabContent`, cho phép
/// player chọn thông tin khảo sát ngay trên màn hình chính thay vì phải
/// mở popup riêng.
///
/// Nội dung form gồm:
/// - Player count selector
/// - Weight range (độ phức tạp)
/// - Duration selector (thời gian chơi)
/// - Categories chip multi-select
/// - Nút "Đặt lại" và "Áp dụng"
class SurveyFilterForm extends StatefulWidget {
  final DiscoveryRequestEntity currentRequest;
  final List<GameCategoryDiscoveryEntity> categories;
  final ValueChanged<DiscoveryRequestEntity> onApply;

  /// Optional: nhãn nút áp dụng. Mặc định là 'ÁP DỤNG'.
  final String applyLabel;

  /// Optional: ẩn nút reset (khi dùng trong card nhỏ).
  final bool showResetButton;

  const SurveyFilterForm({
    super.key,
    required this.currentRequest,
    required this.categories,
    required this.onApply,
    this.applyLabel = 'ÁP DỤNG',
    this.showResetButton = true,
  });

  @override
  State<SurveyFilterForm> createState() => _SurveyFilterFormState();
}

class _SurveyFilterFormState extends State<SurveyFilterForm> {
  /// Default so nguoi choi khi chua co filter hoac sau khi reset.
  static const int _defaultPlayerCount = 4;

  late int _playerCount;
  late List<int> _weightRanges;
  late List<String> _preferredDurations;
  late List<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.currentRequest.playerCount ?? _defaultPlayerCount;
    _weightRanges = List.from(widget.currentRequest.weightRanges ?? []);
    _preferredDurations =
        List.from(widget.currentRequest.preferredDurations ?? []);
    _selectedCategoryIds =
        List.from(widget.currentRequest.categoryIds ?? []);
  }

  void _resetFilters() {
    setState(() {
      _playerCount = _defaultPlayerCount;
      _weightRanges = [];
      _preferredDurations = [];
      _selectedCategoryIds = [];
    });
  }

  void _applyFilters() {
    final request = DiscoveryRequestEntity(
      playerCount: _playerCount,
      categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
      preferredDurations:
          _preferredDurations.isEmpty ? null : _preferredDurations,
      weightRanges: _weightRanges.isEmpty ? null : _weightRanges,
    );
    widget.onApply(request);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header row (title + reset pill) ────────────────────────
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2.5),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BỘ LỌC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Tinh chỉnh gợi ý',
                    style: TextStyle(
                      fontSize: 22,
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
            if (widget.showResetButton)
              _ResetPillButton(onPressed: _resetFilters),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ─── Player count ──────────────────────────────────────────
        const _SectionTitle(
          title: 'Số người chơi',
          icon: Icons.people_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PlayerCountSelector(
          value: _playerCount,
          onChanged: (v) => setState(() => _playerCount = v),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ─── Weight range ──────────────────────────────────────────
        const _SectionTitle(
          title: 'Độ phức tạp',
          icon: Icons.scale_rounded,
          hint: 'Chọn 1',
        ),
        const SizedBox(height: AppSpacing.sm),
        WeightRangeSelector(
          selectedValues: _weightRanges,
          onChanged: (v) => setState(() => _weightRanges = v),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ─── Duration ──────────────────────────────────────────────
        const _SectionTitle(
          title: 'Thời gian chơi',
          icon: Icons.timer_outlined,
          hint: 'Chọn 1',
        ),
        const SizedBox(height: AppSpacing.sm),
        _DurationSelector(
          selected: _preferredDurations,
          onChanged: (v) => setState(() => _preferredDurations = v),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ─── Categories ────────────────────────────────────────────
        const _SectionTitle(
          title: 'Thể loại',
          icon: Icons.category_rounded,
          hint: 'Chọn nhiều',
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs + 2,
          runSpacing: AppSpacing.xs + 2,
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

        // ─── Apply button ──────────────────────────────────────────
        _ApplyButton(label: widget.applyLabel, onPressed: _applyFilters),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  /// Optional subtitle ngắn hiển thị bên phải (vd: '(Chọn 1)') để gợi ý
  /// người dùng biết field này single-select.
  final String? hint;

  const _SectionTitle({
    required this.title,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              hint!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.9)
                    : AppColors.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ],
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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
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
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                'Đặt lại',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
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
  final int value;
  final ValueChanged<int> onChanged;

  /// Min/max bounds cua slider. Co dinh 1-5.
  static const int minValue = 1;
  static const int maxValue = 5;

  /// Kich thuoc cua thumb de can chinh vi tri floating chip
  /// (phai khop voi SliderTheme ben duoi).
  static const double _thumbRadius = 13.0;

  const _PlayerCountSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Track thuc su = tong width tru di 2 dau thumb.
        final trackWidth =
            constraints.maxWidth - _thumbRadius * 2;
        final ratio = (value - minValue) / (maxValue - minValue);
        // Vi tri tam cua thumb trong he toa do widget.
        final thumbCenterX = _thumbRadius + trackWidth * ratio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Floating chip (bam theo thumb) ─────────────────
            SizedBox(
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dung FractionalTranslation de chip luon can giua
                  // tren thumb, khong phu thuoc vao width cua chip.
                  Positioned(
                    left: thumbCenterX,
                    top: 0,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: _ValueChip(value: value),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // ─── Slider ────────────────────────────────────────
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor:
                    AppColors.primary.withValues(alpha: 0.18),
                thumbColor: Colors.white,
                overlayColor:
                    AppColors.primary.withValues(alpha: 0.18),
                trackHeight: 7,
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 13,
                  elevation: 2,
                  pressedElevation: 4,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 24,
                ),
                // Khong hien indicator mac dinh - chip noi tren
                // da hien thi gia tri lien tuc.
                showValueIndicator: ShowValueIndicator.never,
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: value.toDouble(),
                min: minValue.toDouble(),
                max: maxValue.toDouble(),
                divisions: maxValue - minValue,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),

            // ─── Min / Max labels ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minValue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$maxValue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pill nhỏ hiển thị số người chơi — chip nổi phía trên thumb.
///
/// Layout:
/// ```
///   [3 người]   ← chip (border + rounded-pill bg primary)
///   ────●────── ← thumb slider
/// ```
class _ValueChip extends StatelessWidget {
  final int value;

  const _ValueChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 3),
          const Text(
            'người',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
            // Single-select: bấm lại chip đang chọn sẽ bỏ chọn,
            // bấm chip khác sẽ thay thế lựa chọn cũ.
            if (isSelected) {
              onChanged(const <String>[]);
            } else {
              onChanged(<String>[opt.value]);
            }
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
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? borderColor
                  : widget.color.withValues(alpha: 0.3),
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
              fontSize: 14,
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
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
                size: 14,
                color: Color(0xFF3D1E00),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
  final String label;
  final VoidCallback onPressed;
  const _ApplyButton({required this.label, required this.onPressed});

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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primary, AppColors.accentDark],
            ),
            borderRadius: BorderRadius.circular(18),
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
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 1.4,
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