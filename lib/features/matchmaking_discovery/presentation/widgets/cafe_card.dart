import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import 'seat_availability_indicator.dart';

/// Neo-brutalism Cafe card — magazine-style, không dùng ảnh (do backend
/// chưa trả `imageUrl` cho cafe). Layout tổng thể:
///
/// ```
/// +--------------------------------------------------+
/// |  [icon] | Cafe name              [status chip]  |  <- header
/// |         | address line                          |
/// +--------------------------------------------------+
/// |  [Seats]    [Price]     [Game boxes]             |  <- 3 stat boxes
/// |   8/40      60k/giờ      20/20                    |
/// +--------------------------------------------------+
/// |  [Wait banner — nếu game đang chờ ~X phút]       |  <- optional
/// +--------------------------------------------------+
/// ```
///
/// **Lưu ý quan trọng về seats/price (build 2026-10-03):**
/// - BE trả 2 loại "capacity" riêng biệt:
///   - `totalSeats`/`availableSeats` — cho quán seat-based pricing.
///   - `availableTableCount`/`totalTableCount` — cho quán table-based.
///   - Một số quán chỉ track 1 loại (vd: `totalSeats: 0` nhưng
///     `totalTableCount: 10` — boardverse quán dùng table-based).
/// - **Logic "Ghế" (build 2026-10-03)**: CHỈ hiển thị khi `totalSeats > 0`.
///   Khi `totalSeats == 0` (table-based), stat box "Ghế" hiển thị "—"
///   (không fallback sang tables — bị user phản ánh là "ngược" vì
///   `Ghế 10/10` gây hiểu nhầm quán có 10 ghế trống trong khi thực tế
///   quán không track ghế).
/// - **Stat "Bàn trống" đã bỏ (build 2026-10-03)**: user cho rằng
///   "availableTableCount" chỉ là metadata nội bộ, không cần hiển thị
///   cho player. Thay vào đó hiển thị `basePrice` (giá cơ bản) để
///   player biết chi phí trước khi đặt.
/// - Logic màu stat box "Ghế": đỏ (0) / cam (≤ 20%) / xanh (còn nhiều).
class CafeCard extends StatefulWidget {
  final CafeEntity cafe;
  final VoidCallback? onTap;
  final VoidCallback? onBookingTap;
  final bool isSelected;
  final bool showFullDetails;
  final SeatAvailabilityEntity? seatAvailability;

  const CafeCard({
    super.key,
    required this.cafe,
    this.onTap,
    this.onBookingTap,
    this.isSelected = false,
    this.showFullDetails = false,
    this.seatAvailability,
  });

  @override
  State<CafeCard> createState() => _CafeCardState();
}

class _CafeCardState extends State<CafeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;
    final cafe = widget.cafe;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: isPressed ? const Offset(2, 2) : Offset.zero,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) {
                _pressCtrl.forward();
                HapticFeedback.lightImpact();
              },
        onTapUp: widget.onTap == null ? null : (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: Container(
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderColor: widget.isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            shadowColor: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.black.withValues(alpha: 0.35),
            bold: widget.isSelected,
            borderRadius: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CafeHeader(
                cafe: cafe,
                isDark: isDark,
                isSelected: widget.isSelected,
              ),
              _CafeBody(
                cafe: cafe,
                isDark: isDark,
                seatAvailability: widget.seatAvailability,
                showDetailedInfo: widget.showFullDetails,
              ),
              if (cafe.isWaitingForGame && cafe.estimatedWaitMinutes != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _WaitBanner(minutes: cafe.estimatedWaitMinutes!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Header card: decorative icon block + name/address + status chip +
/// distance chip. Không dùng ảnh vì backend chưa trả cafe.imageUrl.
class _CafeHeader extends StatelessWidget {
  final CafeEntity cafe;
  final bool isDark;
  final bool isSelected;

  const _CafeHeader({
    required this.cafe,
    required this.isDark,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CafeIconBlock(
            cafe: cafe,
            isSelected: isSelected,
            isDark: isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        cafe.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.3,
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
                const SizedBox(height: 4),
                if (cafe.address.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 13,
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
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _DistancePill(distanceMeters: cafe.distanceMeters),
                    const SizedBox(width: AppSpacing.xs),
                    _StatusChip(cafe: cafe),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative icon block thay cho ảnh cafe (chưa có imageUrl).
/// Gradient background theo seat status + icon storefront.
class _CafeIconBlock extends StatelessWidget {
  final CafeEntity cafe;
  final bool isSelected;
  final bool isDark;

  const _CafeIconBlock({
    required this.cafe,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (gradient, iconColor) = _gradientForStatus(cafe, isDark);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.25),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            color: iconColor,
            size: 32,
          ),
          if (cafe.availableGameCount > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.black,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.casino_rounded,
                  size: 10,
                  color: AppColors.white,
                ),
              ),
            ),
          if (isSelected)
            const Positioned(
              right: 4,
              top: 4,
              child: _SelectedBadge(),
            ),
        ],
      ),
    );
  }

  /// Gradient + icon color theo seat status:
  /// - available: cam nhạt → cam (energy/positive)
  /// - limited: vàng → vàng đậm (warning)
  /// - full: xám → xám đậm (unavailable)
  (Gradient, Color) _gradientForStatus(CafeEntity cafe, bool isDark) {
    switch (cafe.seatStatus) {
      case CafeSeatStatus.available:
        return (
          LinearGradient(
            colors: isDark
                ? [const Color(0xFFE64A19), const Color(0xFFFF8A50)]
                : [const Color(0xFFFF8A50), const Color(0xFFFFB088)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          AppColors.white,
        );
      case CafeSeatStatus.limited:
        return (
          LinearGradient(
            colors: isDark
                ? [const Color(0xFFFFB300), const Color(0xFFFFCA28)]
                : [const Color(0xFFFFCA28), const Color(0xFFFFE082)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          AppColors.black,
        );
      case CafeSeatStatus.full:
        return (
          LinearGradient(
            colors: isDark
                ? [const Color(0xFF424242), const Color(0xFF616161)]
                : [const Color(0xFFBDBDBD), const Color(0xFFE0E0E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          AppColors.black,
        );
    }
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.black,
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.check,
        size: 12,
        color: AppColors.white,
      ),
    );
  }
}

/// Body: 3 stat boxes (seats/tables/boxes) — hiển thị tỷ lệ X/Y với màu
/// semantic (đỏ = 0, xanh lá = còn nhiều, cam = sắp hết).
class _CafeBody extends StatelessWidget {
  final CafeEntity cafe;
  final bool isDark;
  final SeatAvailabilityEntity? seatAvailability;
  final bool showDetailedInfo;

  const _CafeBody({
    required this.cafe,
    required this.isDark,
    required this.seatAvailability,
    required this.showDetailedInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.event_seat_rounded,
                  label: 'Ghế trống',
                  value: _seatValue(cafe),
                  // Logic màu theo yêu cầu user:
                  // - totalSeats == 0 → grey (không track ghế, fallback
                  //   "—" hiển thị)
                  // - available = 0 → đỏ (hết)
                  // - available > 0 → xanh lá (còn)
                  // - 0 < available <= 20% total → cam (sắp hết)
                  accent: _seatAccent(cafe),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatBox(
                  // Icon price → bỏ "Bàn trống" (build 2026-10-03),
                  // thay bằng "Giá" để user biết chi phí trước khi đặt.
                  icon: Icons.payments_rounded,
                  label: 'Giá',
                  value: cafe.priceDisplay,
                  accent: AppColors.primary,
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
                  accent: _ratioAccent(
                    cafe.availableGameCount,
                    cafe.totalGameBoxCount,
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (seatAvailability != null && showDetailedInfo) ...[
            const SizedBox(height: AppSpacing.sm),
            SeatAvailabilityIndicator(
              cafe: cafe,
              availability: seatAvailability,
              showDetailedInfo: showDetailedInfo,
            ),
          ],
        ],
      ),
    );
  }

  /// Value cho stat box "ghế" (build 2026-10-03 — fix bug "ngược"):
  /// - Nếu `totalSeats > 0` → "{available}/{total}".
  /// - Nếu `totalSeats == 0` → "—" (KHÔNG fallback sang tables — user
  ///   phản ánh "Ghế 10/10" cho quán `totalSeats=0` gây hiểu nhầm quán
  ///   có 10 ghế trống trong khi thực tế quán chỉ track tables, không
  ///   có dữ liệu ghế).
  String _seatValue(CafeEntity cafe) {
    if (cafe.totalSeats > 0) {
      return '${cafe.availableSeats}/${cafe.totalSeats}';
    }
    // totalSeats == 0 → quán table-based, không có seat data.
    return '—';
  }

  /// Màu accent cho stat box "ghế" (build 2026-10-03 — fix bug "ngược"):
  /// - `totalSeats == 0` → grey (textTertiary) — quán không track ghế,
  ///   stat box hiển thị "—" thay vì ratio từ tables (bị user phản ánh).
  /// - `totalSeats > 0`:
  ///   - `available == 0` → đỏ (AppColors.error).
  ///   - `available > 0 && <= 20%` → cam (AppColors.warningDark).
  ///   - còn lại → xanh lá (AppColors.success).
  Color _seatAccent(CafeEntity cafe) {
    if (cafe.totalSeats <= 0) {
      // Quán không track ghế → grey, không suy ra từ tables.
      return AppColors.textTertiary;
    }
    return _seatStatusColor(cafe.seatStatus);
  }

  Color _seatStatusColor(CafeSeatStatus status) {
    switch (status) {
      case CafeSeatStatus.full:
        return AppColors.error; // Đỏ - hết ghế
      case CafeSeatStatus.limited:
        return AppColors.warningDark; // Cam đậm - sắp hết
      case CafeSeatStatus.available:
        return AppColors.success; // Xanh lá - còn ghế
    }
  }

  /// Màu cho stat box tỷ lệ X/Y (chỉ dùng cho "Box game" sau khi bỏ
  /// "Bàn trống" — build 2026-10-03).
  /// - available == 0 → đỏ.
  /// - available > 0 → xanh lá (hoặc cam nếu < 30% tổng).
  Color _ratioAccent(int available, int total) {
    if (total == 0) return AppColors.textSecondary;
    if (available == 0) return AppColors.error;
    if (available <= total * 0.3) return AppColors.warningDark;
    return AppColors.success;
  }
}

/// Compact stat box — icon + label + value với màu semantic.
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
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
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

/// Distance chip — small pill với icon near_me.
class _DistancePill extends StatelessWidget {
  final double distanceMeters;
  const _DistancePill({required this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.black.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_rounded,
            size: 12,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            DistanceFormatter.format(distanceMeters),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip — dùng AppColors.success / warning / error theo seat status.
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
        border: Border.all(
          color: AppColors.black,
          width: 1.5,
        ),
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
