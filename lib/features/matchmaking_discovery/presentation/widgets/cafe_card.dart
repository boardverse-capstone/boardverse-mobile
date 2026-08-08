import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import 'seat_availability_indicator.dart';

/// Neo-brutalism Cafe card — bold borders + press animation.
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
    final hasDeposit = widget.cafe.depositAmount != null;
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

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
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: widget.isSelected
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: widget.isSelected
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  )
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.black.withValues(alpha: 0.06),
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CafeImage(
                      imageUrl: widget.cafe.imageUrl,
                      isSelected: widget.isSelected,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.cafe.name,
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.cafe.rating > 0) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _RatingPill(rating: widget.cafe.rating),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Distance + Tables row
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.location_on_outlined,
                                text: _formatDistance(
                                  widget.cafe.distanceMeters,
                                ),
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _MetaChip(
                                icon: Icons.table_restaurant_outlined,
                                text:
                                    '${widget.cafe.availableTableCount}/${widget.cafe.totalTableCount} bàn',
                                color: _tableColor(
                                  widget.cafe.availableTableCount,
                                  widget.cafe.totalTableCount,
                                ),
                              ),
                              if (widget.cafe.isWaitingForGame &&
                                  widget.cafe.estimatedWaitMinutes != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _WaitPill(
                                  minutes:
                                      widget.cafe.estimatedWaitMinutes!,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SeatAvailabilityIndicator(
                            cafe: widget.cafe,
                            availability: widget.seatAvailability,
                            showDetailedInfo: widget.showFullDetails,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (hasDeposit) ...[
                            _DepositPill(
                              amount: _formatDepositBvc(
                                widget.cafe.depositAmount!,
                              ),
                              minutes: widget.cafe.depositMinutesLimit,
                            ),
                          ],
                        ],
                      ),
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

  Color _tableColor(int available, int total) {
    if (available == 0) return AppColors.error;
    if (available <= total * 0.3) return AppColors.warningDark;
    return AppColors.success;
  }

  String _formatDepositBvc(double amount) {
    return '${amount.toStringAsFixed(0)} BVC';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _CafeImage extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;

  const _CafeImage({required this.imageUrl, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            SafeNetworkImage(
              url: imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                right: 4,
                bottom: 4,
                child: _SelectedBadge(),
              ),
          ],
        ),
      ),
    );
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
            size: AppSpacing.sm,
            color: AppColors.black,
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.sm + 1, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _WaitPill extends StatelessWidget {
  final int minutes;
  const _WaitPill({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_bottom,
            size: AppSpacing.sm,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: 2),
          Text(
            '~$minutes phút',
            style: const TextStyle(
              color: AppColors.warningDark,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositPill extends StatelessWidget {
  final String amount;
  final int? minutes;

  const _DepositPill({required this.amount, this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.payments_outlined,
            size: AppSpacing.sm,
            color: AppColors.primary,
          ),
          const SizedBox(width: 2),
          Text(
            'Cọc $amount',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          if (minutes != null) ...[
            Text(
              ' / $minutes phút',
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
