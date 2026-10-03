import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/recommended_board_game_entity.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/saved_games_state.dart';

/// Card hiển thị một board game được gợi ý.
///
/// Layout (nested gesture recognizers):
/// ```
/// +-----------------------------------------+
/// | +--Hero thumbnail--------------------+ |
/// | | [weight badge]                  [🔖] | |  <- save bookmark ở top-right
/// | |                                   | |     icon đen trên nền trắng,
/// | |         Board game image          | |     hard offset shadow. Tap
/// | |                                   | |     save → toggleSave() (Stack
/// | | [category chip]                   | |     sibling nên không bị outer
/// | +------------------------------------+ |     GestureDetector nuốt).
/// | +--Info-----------------------------+ |
/// | | Game title            [score 88]   | |  <- tap phần còn lại →
/// | | -- Stats grid (Players/Time/Wt.)  | |     navigate detail.
/// | | -- Match reasons list             | |
/// | +------------------------------------+ |
/// +-----------------------------------------+
/// ```
///
/// Style: Neo-brutalism — border 3px, hard offset shadow, vibrant colors.
/// Save icon ở top-right cùng style với `_HeaderSaveButton` ở boardgame
/// detail page (cùng 40x40 white circle + black border + black bookmark
/// icon) → user nhận diện đây là cùng 1 control dù context khác nhau.
class RecommendedGameCard extends StatelessWidget {
  final RecommendedBoardGameEntity game;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RecommendedGameCard({
    super.key,
    required this.game,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = _scoreColor(game.score);

    // Tap hierarchy:
    //
    //  ┌───────────────────────────────────────────────┐
    //  │ Stack                                          │
    //  │   ┌─────────────────────────────────────────┐ │
    //  │   │ _CardWithPress (outer GestureDetector)  │ │ ← tap → open detail
    //  │   │   ┌───────────────────────────────────┐ │ │
    //  │   │   │ Container (decoration)            │ │ │
    //  │   │   │   ┌─────────────────────────────┐ │ │ │
    //  │   │   │   │ Stack (hero + overlays)      │ │ │ │
    //  │   │   │   │   ┌───────────────────────┐ │ │ │ │
    //  │   │   │   │   │ _HeroSection          │ │ │ │ │
    //  │   │   │   │   └───────────────────────┘ │ │ │ │
    //  │   │   │   └─────────────────────────────┘ │ │ │
    //  │   │   │   ┌─────────────────────────────┐ │ │ │
    //  │   │   │   │ Info section                │ │ │ │
    //  │   │   │   └─────────────────────────────┘ │ │ │
    //  │   │   └───────────────────────────────────┘ │ │
    //  │   └─────────────────────────────────────────┘ │
    //  │   ┌─────────────────────────────────────────┐ │
    //  │   │ _CardSaveButton (SIBLING, không phải    │ │ │ ← tap → save/unsave
    //  │   │   child của _CardWithPress)             │ │ │   Đặt NGOÀI outer
    //  │   │   → own GestureDetector + Material      │ │ │   GestureDetector
    //  │   │     wrap → không bị outer "nuốt" tap   │ │ │   để tránh gesture
    //  │   └─────────────────────────────────────────┘ │   arena conflict.
    //  └───────────────────────────────────────────────┘
    //
    // ────────────────────────────────────────────────────────────
    // Tại sao tách save button ra Stack sibling (thay vì nested):
    //
    // Trước đây save button được lồng (nested) BÊN TRONG
    // _CardWithPress. Lý thuyết: inner GestureDetector thắng arena
    // ở cùng hit area. Thực tế: outer _CardWithPress cũng có
    // `onTapDown` gây `setState` rebuild → trong quá trình rebuild,
    // gesture recognizer bị tear-down → arena không ổn định → tap
    // đi vào outer (navigate detail) thay vì inner (toggle save).
    //
    // Fix: Tách save button ra NGOÀI _CardWithPress (Stack sibling),
    // wrap trong `Material` widget (cung cấp hit-test boundary rõ
    // ràng). Stack đặt save button TRÊN cùng (Positioned top: xs,
    // right: xs). Vì save button không phải child của outer
    // GestureDetector, hit test không bị outer nhận → save button
    // GestureDetector độc lập xử lý tap 100%.
    //
    // Vì Stack pass hit-test xuống cả 2 children (card body bên dưới
    // + save button bên trên), nhưng Material widget của save button
    // có HitTestBehavior.opaque (mặc định cho Material) → hit test
    // được consume bởi save button khi user tap vào vùng bookmark.
    // → outer GestureDetector không nhận onTap khi tap vào save button.
    // ────────────────────────────────────────────────────────────
    return Stack(
      children: [
        // 1. Card body (có GestureDetector để navigate detail).
        _CardWithPress(
          onTap: onTap,
          child: Container(
            decoration: NeoBrutalismTheme.autoBox(
              context,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.surface,
              // Shadow tô màu theo score -> visual cue "game nay match tot".
              shadowColor: scoreColor.withValues(alpha: 0.25),
              borderRadius: 20,
              bold: true,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HERO: anh + overlays (weight, category).
                // Save button đã được tách ra Stack level (sibling) —
                // không còn Positioned(_CardSaveButton) bên trong hero.
                _HeroSection(
                  game: game,
                  isDark: isDark,
                  scoreColor: scoreColor,
                ),

                // INFO: ten game + score chip + stats grid + reasons.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: ten game (trai) + score chip (phai).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              game.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _ScoreChip(
                            score: game.score,
                            color: scoreColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Stats grid: 3 mini-card ngang (Players / Time / Wt.).
                      _StatsGrid(game: game, isDark: isDark),

                      // Match reasons (hien thi day du, khong truncate).
                      if (game.matchReasons.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _MatchReasonsSection(
                          reasons: game.matchReasons,
                          isDark: isDark,
                        ),
                      ],

                      // Trailing slot (optional).
                      if (trailing != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Save button (SIBLING — NGOÀI _CardWithPress).
        // Positioned trên Stack + Material wrap → tap area độc lập
        // với card body. outer GestureDetector KHÔNG nhận onTap khi
        // user tap vào save button (Material opaque consume hit test).
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: _CardSaveButton(
            gameId: game.id,
            gameName: game.name,
            initialIsSaved: game.isSaved,
          ),
        ),
      ],
    );
  }

  /// Mau theo score: xanh (cao) -> vang -> cam -> xam (thap).
  Color _scoreColor(double s) {
    if (s >= 80) return AppColors.success;
    if (s >= 65) return AppColors.warning;
    if (s >= 50) return AppColors.primary;
    return AppColors.textTertiary;
  }
}

// ============================================================================
// HERO SECTION -- anh + overlays (weight badge, category)
// ============================================================================
//
// Lưu ý: save bookmark được đặt ở Stack level của `RecommendedGameCard`
// (Stack chứa `_HeroSection` + `Positioned(_CardSaveButton)`). Stack
// này nằm BÊN TRONG `_CardWithPress` GestureDetector → save button là
// nested GestureDetector, inner recognizer sẽ thắng arena ở cùng
// hit area so với outer `_CardWithPress` → toggleSave() chắc chắn
// được gọi khi user tap icon.

class _HeroSection extends StatelessWidget {
  final RecommendedBoardGameEntity game;
  final bool isDark;
  final Color scoreColor;

  const _HeroSection({
    required this.game,
    required this.isDark,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail anh.
        _Thumbnail(
          imageUrl: game.imageUrl,
          height: 148,
          isDark: isDark,
        ),

        // Top + bottom gradient overlay (badge contrast).
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.20),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Weight badge (top-left).
        if (game.weight != null)
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _WeightBadge(weight: game.weight!),
          ),

        // Save bookmark đã được tách ra NGOÀI `_CardWithPress`
        // (Stack sibling của card body) tại `RecommendedGameCard.build`.
        // Lý do: tránh gesture arena conflict với outer
        // `_CardWithPress.onTap` (navigate detail). Xem comment block
        // trong `RecommendedGameCard.build` để hiểu chi tiết.

        // Primary category chip (bottom-left).
        if (game.categories.isNotEmpty)
          Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _CategoryOverlay(category: game.categories.first),
          ),
      ],
    );
  }
}

// ============================================================================
// SCORE CHIP -- chip nho canh ten game trong info section
// ============================================================================

/// Chip diem so nho hien thi trong info section, thay the cho score ring
/// overlay cu (user feedback: "0 YEU" tren goc hinh bi rac, xoa di).
class _ScoreChip extends StatelessWidget {
  final double score;
  final Color color;

  const _ScoreChip({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WEIGHT BADGE -- top-left, co icon balance + color coding
// ============================================================================

class _WeightBadge extends StatelessWidget {
  final double weight;

  const _WeightBadge({required this.weight});

  @override
  Widget build(BuildContext context) {
    final color = _weightColor(weight);
    final label = _weightLabel(weight);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: Colors.black.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.balance_rounded, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${weight.toStringAsFixed(1)})',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  String _weightLabel(double w) {
    if (w <= 1.99) return 'NHE';
    if (w <= 2.99) return 'TB NHE';
    if (w <= 3.49) return 'TRUNG BINH';
    if (w <= 3.99) return 'TB NANG';
    return 'NANG';
  }

  Color _weightColor(double w) {
    if (w <= 1.99) return AppColors.success;
    if (w <= 2.99) return const Color(0xFF8BC34A);
    if (w <= 3.49) return AppColors.warning;
    if (w <= 3.99) return AppColors.primary;
    return AppColors.error;
  }
}

// ============================================================================
// CATEGORY OVERLAY -- chip overlay goc duoi-trai cua hero
// ============================================================================

class _CategoryOverlay extends StatelessWidget {
  final String category;

  const _CategoryOverlay({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        // Dark glassmorphism overlay -> text trang de doc tren anh.
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.6,
          height: 1.0,
        ),
      ),
    );
  }
}

// ============================================================================
// STATS GRID -- 3 mini-card: Players / Time / Weight
// ============================================================================

class _StatsGrid extends StatelessWidget {
  final RecommendedBoardGameEntity game;
  final bool isDark;

  const _StatsGrid({required this.game, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.groups_rounded,
            label: game.playerRangeDisplay,
            sublabel: 'nguoi',
            color: AppColors.secondary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatTile(
            icon: Icons.schedule_rounded,
            label: '${game.playTimeMinutes}',
            sublabel: 'phut',
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _StatTile(
            icon: Icons.balance_rounded,
            label: game.weight != null
                ? game.weight!.toStringAsFixed(1)
                : '...',
            sublabel: 'weight',
            color: _weightStatColor(game.weight),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Color _weightStatColor(double? w) {
    if (w == null) return AppColors.textTertiary;
    if (w <= 1.99) return AppColors.success;
    if (w <= 2.99) return const Color(0xFF8BC34A);
    if (w <= 3.49) return AppColors.warning;
    if (w <= 3.99) return AppColors.primary;
    return AppColors.error;
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.10);
    final borderColor = isDark
        ? color.withValues(alpha: 0.45)
        : color.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              height: 1.0,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
              letterSpacing: 0.3,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATCH REASONS -- danh sach doc voi check icon, hien thi day du
// ============================================================================

class _MatchReasonsSection extends StatelessWidget {
  final List<String> reasons;
  final bool isDark;

  const _MatchReasonsSection({required this.reasons, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        // Subtle success background -> "match" connotation.
        color: isDark
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row.
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 11,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                'VI SAO PHU HOP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.successLight
                      : AppColors.successDark,
                  letterSpacing: 0.6,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs + 2),
          // Reason items - hien thi day du, wrap nhieu dong neu can.
          ...reasons.asMap().entries.map((entry) {
            final i = entry.key;
            final reason = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < reasons.length - 1 ? 2 : 0,
              ),
              child: _ReasonRow(text: reason, isDark: isDark),
            );
          }),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final String text;
  final bool isDark;

  const _ReasonRow({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              height: 1.3,
              letterSpacing: 0.1,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CARD WITH PRESS -- neo-brutalism press feedback
// ============================================================================

class _CardWithPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardWithPress({required this.child, this.onTap});

  @override
  State<_CardWithPress> createState() => _CardWithPressState();
}

class _CardWithPressState extends State<_CardWithPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// THUMBNAIL -- anh board game + shimmer/placeholder
// ============================================================================

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final bool isDark;

  const _Thumbnail({
    required this.imageUrl,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(18));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base background.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.surfaceContainerDark,
                          AppColors.surfaceElevatedDark,
                        ]
                      : [
                          AppColors.surfaceVariant,
                          AppColors.background,
                        ],
                ),
              ),
            ),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              SafeNetworkImage(
                url: imageUrl!,
                fit: BoxFit.cover,
                // Web: SafeNetworkImage wrap <img> qua HtmlElementView nen
                // browser render truc tiep - bypass CORS CDN BGG khong co
                // header Access-Control-Allow-Origin.
                // Mobile: hoat dong nhon <img> binh thuong.
                loadingBuilder: (context, child, event) {
                  if (event == null) return child;
                  return const _ThumbnailShimmer();
                },
                errorBuilder: (context, error, stack) => const _PlaceholderImage(),
              )
            else
              const _PlaceholderImage(),
          ],
        ),
      ),
    );
  }
}

/// Placeholder hiển thị khi ảnh chưa load được hoặc URL rỗng.
///
/// **Thiết kế**: Màu neutral (xám nhạt) với icon subtle — KHÔNG dùng
/// màu brand orange/yellow. Trước đây dùng `primaryLight` + `accentLight`
/// tạo gradient cam-vàng rất chói, bị nhầm thành "khung đỏ" che mất
/// ảnh thật. Giờ đổi sang surfaceVariant (xám nhạt) + outline icon để
/// placeholder trông như loading state thật, không gây rối mắt.
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceVariant;
    final bgBottom = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.background;
    final iconColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgTop, bgBottom],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_outlined,
          size: 44,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Shimmer effect hien thi trong khi thumbnail dang load.
///
/// Tren web, `loadingBuilder` khong duoc goi (vi `SafeNetworkImage`
/// dung `<img>` qua HtmlElementView - khong co progress event); widget
/// nay thuc te chi active tren mobile. Tren web, base gradient background
/// cua `_Thumbnail` dong vai tro loading indicator.
class _ThumbnailShimmer extends StatefulWidget {
  const _ThumbnailShimmer();

  @override
  State<_ThumbnailShimmer> createState() => _ThumbnailShimmerState();
}

class _ThumbnailShimmerState extends State<_ThumbnailShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceVariant;
    final highlight = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surface;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: base),
            // Shimmer band sweeps left -> right.
            FractionallySizedBox(
              widthFactor: 0.6,
              alignment: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      base,
                      highlight,
                      base,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SAVE BUTTON -- bookmark icon toggle
// ============================================================================
//
// **Visual đồng bộ với `_HeaderSaveButton` ở boardgame detail page**:
// cùng style 40x40 white circle + 2px black border + hard offset shadow
// + 18px black bookmark icon. Chỉ thay đổi filled ↔ outline để phản
// ánh state saved/unsaved. Lý do đồng bộ:
// - Nhất quán UX: user nhận diện cùng 1 control dù đang ở màn hình
//   nào (discovery results / boardgame detail).
// - Cùng tập visual cue → không gây confusion khi user save ở đây rồi
//   vào detail page thấy icon "trông khác" (trước đây _CardSaveButton
//   dùng nền đen/white toggle theo state, _HeaderSaveButton dùng nền
//   trắng cố định → cùng 1 game nhưng icon trông khác nhau ở 2 màn).
//
// Trước đây `_CardSaveButton` đổi cả nền/viền/icon màu theo state
// (nền đen + icon trắng khi chưa lưu, nền trắng + icon đen khi đã
// lưu). Design intent cũ là để tăng visibility trên ảnh nhiều màu
// sắc (white border/icon nổi bật trên dark image). Nhưng cách này
// làm icon "thay đổi hoàn toàn" sau khi tap → user có thể nghĩ là
// 2 control khác nhau. Style mới giữ button luôn visually giống
// nhau, chỉ icon filled/outline thay đổi → rõ ràng hơn về state.

/// Bookmark icon toggle cho Recommend card.
///
/// Đọc trạng thái saved từ [SavedGamesCubit] (cache local) và gọi
/// `toggleSave(gameId)` khi user nhấn. Optimistic update → UI
/// phản hồi ngay không cần đợi API.
///
/// Icon: BOOKMARK (không dùng heart) theo yêu cầu user.
/// - bookmark_border_rounded (outline) — chưa lưu
/// - bookmark_rounded (filled) — đã lưu
///
/// **Side effects**: subscribe [SavedGamesCubit.actions] stream để show
/// toast khi save/unsave thành công (message từ BE) hoặc thất bại.
///
/// **Vị trí trong widget tree**: là Stack SIBLING của `_CardWithPress`
/// (không phải child). Save button có GestureDetector riêng, tap vào
/// vùng bookmark sẽ trigger toggleSave() — KHÔNG navigate cho detail.
///
/// **Tap reliability**:
/// - `GestureDetector + HitTestBehavior.opaque` → opaque hit-test
///   boundary, ngăn hit propagate xuống `_CardWithPress` bên dưới Stack.
/// - `GestureDetector` ổn định trên mọi platform (mobile + web), không
///   phụ thuộc Material ancestor hay theme.
class _CardSaveButton extends StatefulWidget {
  final String gameId;
  final String gameName;

  /// Trang thai `isSaved` tu API response (recommendation / survey).
  /// Dung lam fallback khi [SavedGamesCubit] chua co data tin cay
  /// (SavedGamesInitial / SavedGamesError khong co savedIds) → icon
  /// luon hien thi dung DB state ngay tu frame dau tien.
  final bool initialIsSaved;

  const _CardSaveButton({
    required this.gameId,
    this.gameName = '',
    this.initialIsSaved = false,
  });

  @override
  State<_CardSaveButton> createState() => _CardSaveButtonState();
}

class _CardSaveButtonState extends State<_CardSaveButton>
    with SingleTickerProviderStateMixin {
  StreamSubscription<SaveActionMessage>? _actionSub;

  /// Pulse animation khi state thay doi (saved <-> unsaved).
  /// Tao feedback ro rang cho user biet da luu thanh cong.
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  /// Local press state — khi user nhan giu (tap down) icon, scale nho
  /// lai de tao cam giac "bam". Reset khi tap up / cancel.
  ///
  /// **Tai sao can state rieng (khong dung `_pulseScale`)?**
  /// - `_pulseScale` chi kich khi save action thanh cong (subscribe
  ///   tu cubit stream) → scale 1.35 roi ve 1.0.
  /// - `_localPressed` kich ngay khi user nhan (onTapDown) → scale
  ///   0.85 roi ve 1.0. 2 animation doc lap, khong xung dot.
  bool _localPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseCtrl);

    // Subscribe stream de show toast khi save/unsave hoan tat.
    //
    // **Defensive**: bọc try-catch để an toàn khi:
    // - Cubit da bi close (closed stream → `.actions` tra empty stream
    //   va listen() complete silently).
    // - Race condition tren web khi cubit dispose nhung widget van dang
    //   rebuild.
    //
    // Lưu ý: KHÔNG dùng `_hasSavedGamesProvider` check trong initState
    // — nó dựa vào `findAncestorWidgetOfExactType` không đáng tin cậy
    // (có thể trả về null khi cubit vẫn tồn tại trong tree qua
    // BlocProvider.value/MultiBlocProvider). Để `context.read` throw →
    // catch nuốt → tiếp tục render. Tap handler sẽ check lúc user
    // ấn (lúc đó context đã ổn định).
    try {
      _actionSub = context
          .read<SavedGamesCubit>()
          .actions
          .where((action) => action.gameTemplateId == widget.gameId)
          .listen(_onAction);
    } catch (_) {
      // Khong co cubit, cubit da close, hoac loi runtime khac →
      // bo qua, card van render binh thuong (chi khong co toast).
    }
  }

  @override
  void dispose() {
    _actionSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onAction(SaveActionMessage action) {
    if (!mounted) return;
    // Pulse animation de user biet icon da thay doi thanh cong.
    _pulseCtrl.forward(from: 0);
    if (action.isSuccess) {
      AppToast.showSuccess(context, action.message);
    } else {
      AppToast.showError(context, action.message);
    }
  }

  /// Tap handler — LUÔN enable. Cubit access defer đến lúc tap để
  /// tránh crash khi widget mounted trong môi trường thiếu cubit.
  void _onTap() {
    debugPrint('[CardSaveButton] _onTap called for gameId=${widget.gameId}');
    try {
      final cubit = context.read<SavedGamesCubit>();
      debugPrint(
        '[CardSaveButton] cubit found, calling toggleSave. '
        'current state=${cubit.state.runtimeType}',
      );
      cubit.toggleSave(widget.gameId);
    } catch (e, stack) {
      // Cubit không có sẵn (test env hoặc thiếu BlocProvider) →
      // log lỗi đầy đủ để debug, KHÔNG show toast (tránh spam).
      debugPrint(
        '[CardSaveButton] ERROR: cubit not found: $e\n$stack',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Doc trang thai saved tu cubit neu co (cubit la source of truth
    // cho user actions). Fallback ve `initialIsSaved` tu API neu
    // cubit chua co trong scope (vi du: card test voi cua test, hoac
    // page push ma caller quen pass cubit).
    //
    // Cach trien khai:
    // 1. Thu `context.read<SavedGamesCubit>()` truoc → neu throw
    //    (ProviderNotFoundException) → render button voi `initialIsSaved`
    //    tu API (reactive qua `setState` ben duoi neu can).
    // 2. Neu co cubit → dung `BlocBuilder` de reactive update khi state
    //    doi (tap save -> UI flip ngay).
    SavedGamesCubit? cubit;
    try {
      cubit = context.read<SavedGamesCubit>();
    } catch (_) {
      cubit = null;
    }

    if (cubit == null) {
      // Khong co cubit → render static button (chi dung initialIsSaved).
      // Tap handler cung co try/catch rieng (trong `_onTap`) → neu user
      // bam vao luc cubit chua co → show error toast nhe, khong crash.
      return _buildButton(
        context: context,
        isSaved: widget.initialIsSaved,
      );
    }

    return BlocBuilder<SavedGamesCubit, SavedGamesState>(
      // Chi rebuild khi tap thanh vien set thay doi (savedIds).
      // Tranh rebuild toan bo card khi state khac doi (games list refresh).
      buildWhen: (prev, curr) {
        final prevIds = _idsOf(prev);
        final currIds = _idsOf(curr);
        return prevIds != currIds;
      },
      builder: (context, state) {
        final isSaved = _computeIsSaved(state);
        return _buildButton(
          context: context,
          isSaved: isSaved,
        );
      },
    );
  }

  /// Selector logic tach rieng de test va reuse.
  ///
  /// Cubit chỉ "tin cậy" khi đã có data (Loaded / Refreshing /
  /// LoadingFromCache / Error có savedIds). Initial / Error
  /// không có savedIds → fallback `initialIsSaved` từ API để
  /// icon luôn hiển thị đúng DB state ngay khi render.
  bool _computeIsSaved(SavedGamesState state) {
    final ids = _idsOf(state);
    final cubitHasReliableData = state is SavedGamesLoaded ||
        state is SavedGamesRefreshing ||
        state is SavedGamesLoadingFromCache ||
        (state is SavedGamesError && state.savedIds != null);
    if (cubitHasReliableData) {
      return ids.contains(widget.gameId);
    }
    return ids.contains(widget.gameId) || widget.initialIsSaved;
  }

  Widget _buildButton({
    required BuildContext context,
    required bool isSaved,
  }) {
    // Visual state — đồng bộ với `_HeaderSaveButton` ở boardgame detail:
    // - Luôn nền trắng + viền đen 2px + hard offset shadow (neo-brutalism)
    // - Icon đen cố định; chỉ thay đổi bookmark filled ↔ outline để phản
    //   ánh state saved/unsaved.
    // - Lý do đồng bộ: nhất quán UX toàn app — user nhận diện cùng 1
    //   control dù đang ở màn hình nào. Trước đây `_CardSaveButton`
    //   đổi cả nền/viền/icon màu theo state → dễ gây rối khi user
    //   so sánh với `_HeaderSaveButton` ở trang detail (cùng board game
    //   nhưng icon trông khác nhau). Giờ cả 2 nơi dùng cùng style chỉ
    //   khác filled/outline icon.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (mounted) {
          setState(() => _localPressed = true);
        }
      },
      onTapUp: (_) {
        if (mounted) {
          setState(() => _localPressed = false);
        }
      },
      onTapCancel: () {
        if (mounted) {
          setState(() => _localPressed = false);
        }
      },
      onTap: _onTap,
      child: Tooltip(
        message: isSaved
            ? 'Đã lưu vào danh sách yêu thích'
            : 'Lưu vào danh sách yêu thích',
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: AnimatedScale(
          // Press feedback: scale nhỏ lại khi user đang giữ, scale
          // về 1.0 khi release. Cung cấp "cảm giác bấm" cho user
          // (visual confirmation đã ấn vào icon).
          scale: _localPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              // Hard offset shadow — neo-brutalism signature. Khác
              // với soft shadow cũ (lightShadow), hard shadow tạo cảm
              // giác "sticker dán nổi" rõ ràng, đồng bộ với header save
              // button ở boardgame detail page.
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _pulseScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey(isSaved),
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lay set id da save tu state hien tai (xu ly cac state khac nhau).
  Set<String> _idsOf(SavedGamesState state) {
    if (state is SavedGamesLoaded) return state.savedIds;
    if (state is SavedGamesRefreshing && state.games.isNotEmpty) {
      // Refreshing khong co savedIds truc tiep; suy ra tu games list.
      return state.games.map((g) => g.gameTemplateId).toSet();
    }
    if (state is SavedGamesLoadingFromCache) return state.cachedIds;
    if (state is SavedGamesError) {
      return state.savedIds ?? <String>{};
    }
    return const <String>{};
  }
}