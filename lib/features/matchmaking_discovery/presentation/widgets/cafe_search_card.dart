import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/cafe_entity.dart';

/// Neo-brutalism Cafe card — magazine style dùng cho tab Cafe ở SearchPage.
/// Layout: Hero image lớn (top) + body trắng (bottom) chứa name, địa chỉ,
/// distance, available tables/boxes. Bám sát design system (border 3px,
/// hard offset shadow, press animation, semantic colors).
class CafeSearchCard extends StatefulWidget {
  final CafeEntity cafe;
  final VoidCallback? onTap;

  const CafeSearchCard({
    super.key,
    required this.cafe,
    this.onTap,
  });

  @override
  State<CafeSearchCard> createState() => _CafeSearchCardState();
}

class _CafeSearchCardState extends State<CafeSearchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cafe = widget.cafe;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) {
                // Defer animation tới post-frame để không rebuild giữa
                // pointer event dispatch — tránh
                // "Assertion failed: mouse_tracker.dart:199".
                _pressCtrl.stop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _pressCtrl.forward();
                });
                HapticFeedback.lightImpact();
              },
        onTapUp: widget.onTap == null ? null : (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pressCtrl.reverse();
          });
        },
        onTapCancel: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pressCtrl.reverse();
          });
        },
        onTap: widget.onTap,
        child: Container(
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surface,
            borderColor: isDark ? AppColors.borderDark : AppColors.border,
            shadowColor: AppColors.black.withValues(alpha: 0.35),
            bold: true,
            borderRadius: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CafeHero(cafe: cafe, isDark: isDark),
              _CafeBody(cafe: cafe, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero image với overlay chips: distance (top-left) + status (top-right).
class _CafeHero extends StatelessWidget {
  final CafeEntity cafe;
  final bool isDark;

  const _CafeHero({required this.cafe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(15),
          ),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: SafeNetworkImage(
              url: cafe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _CafePlaceholder(isDark: isDark),
            ),
          ),
        ),
        // Distance chip overlay (top-left)
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: _DistanceChip(distanceMeters: cafe.distanceMeters),
        ),
        // Status chip overlay (top-right)
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: _StatusChip(cafe: cafe),
        ),
        // Bottom gradient fade for text legibility (nếu muốn thêm text ở
        // overlay sau này — giờ giữ nhẹ)
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Body: tên + địa chỉ + meta row.
class _CafeBody extends StatelessWidget {
  final CafeEntity cafe;
  final bool isDark;

  const _CafeBody({required this.cafe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row + rating pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cafe.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cafe.rating > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                _RatingPill(rating: cafe.rating),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cafe.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Bàn trống',
                  value:
                      '${cafe.availableTableCount}/${cafe.totalTableCount}',
                  accent: _availabilityColor(
                    cafe.availableTableCount,
                    cafe.totalTableCount,
                    AppColors.success,
                    AppColors.warningDark,
                    AppColors.error,
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatBox(
                  icon: Icons.casino_rounded,
                  label: 'Box game',
                  value:
                      '${cafe.availableGameCount}/${cafe.totalGameBoxCount}',
                  accent: AppColors.secondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StatBox(
                  icon: Icons.event_seat_rounded,
                  label: 'Ghế trống',
                  // Chỉ hiển thị tổng sức chứa (totalSeats) thay vì
                  // "X/Y" — vì availableSeats từ API là tổng ghế trống
                  // cộng dồn qua 4 time-slot, không phải ghế trống hiện tại.
                  value: '${cafe.totalSeats}',
                  accent: _seatColor(cafe),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          // Wait time banner (chỉ hiện khi đang chờ game)
          if (cafe.isWaitingForGame && cafe.estimatedWaitMinutes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _WaitBanner(minutes: cafe.estimatedWaitMinutes!),
          ],
        ],
      ),
    );
  }

  Color _availabilityColor(
    int available,
    int total,
    Color okColor,
    Color warnColor,
    Color errColor,
  ) {
    if (total == 0) return okColor;
    if (available == 0) return errColor;
    if (available <= total * 0.3) return warnColor;
    return okColor;
  }

  Color _seatColor(CafeEntity cafe) {
    switch (cafe.seatStatus) {
      case CafeSeatStatus.full:
        return AppColors.error;
      case CafeSeatStatus.limited:
        return AppColors.warningDark;
      case CafeSeatStatus.available:
        return AppColors.success;
    }
  }
}

class _CafePlaceholder extends StatelessWidget {
  final bool isDark;
  const _CafePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.primaryLight.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_rounded,
        size: 56,
        color: isDark ? AppColors.textTertiaryDark : AppColors.primary,
      ),
    );
  }
}

/// Distance chip overlay lên hero image — gradient cam.
class _DistanceChip extends StatelessWidget {
  final double distanceMeters;
  const _DistanceChip({required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            size: 12,
            color: AppColors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _format(distanceMeters),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double meters) {
    if (meters <= 0) return '—';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Status chip overlay — dùng AppColors.success / warning / error
/// theo seat status.
class _StatusChip extends StatelessWidget {
  final CafeEntity cafe;
  const _StatusChip({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final cfg = switch (cafe.seatStatus) {
      CafeSeatStatus.available => _ChipCfg(
          bg: AppColors.success,
          fg: AppColors.white,
          icon: Icons.check_circle_rounded,
          label: 'Còn chỗ',
        ),
      CafeSeatStatus.limited => _ChipCfg(
          bg: AppColors.warning,
          fg: AppColors.black,
          icon: Icons.schedule_rounded,
          label: 'Sắp hết',
        ),
      CafeSeatStatus.full => _ChipCfg(
          bg: AppColors.error,
          fg: AppColors.white,
          icon: Icons.do_not_disturb_rounded,
          label: 'Hết chỗ',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 12, color: cfg.fg),
          const SizedBox(width: 4),
          Text(
            cfg.label.toUpperCase(),
            style: TextStyle(
              color: cfg.fg,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipCfg {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;

  const _ChipCfg({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
  });
}

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.black,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat box compact — icon + label + value. Màu value theo accent semantic.
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool isDark;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wait banner khi game đang chờ — amber + icon hourglass.
class _WaitBanner extends StatelessWidget {
  final int minutes;
  const _WaitBanner({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warningDark, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_bottom_rounded,
            size: 16,
            color: AppColors.black,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tựa game đang chờ ~$minutes phút',
              style: const TextStyle(
                color: AppColors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
