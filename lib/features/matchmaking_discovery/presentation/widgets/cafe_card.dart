import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import 'seat_availability_indicator.dart';

/// Rich card hiển thị thông tin quán cafe.
///
/// Layout:
///   ┌─────────────────────────────────────────────────────┐
///   │ [IMAGE]  Cafe Name                          ⭐ 4.0  │
///   │         📍 1.2 km · 🪑 4/4 bàn trống               │
///   │         [Seat availability bar]                     │
///   ├─────────────────────────────────────────────────────┤
///   │ 📍 22 Lê Tấn Bê, An Lạc, HCM        [Đặt chỗ ngay] │
///   └─────────────────────────────────────────────────────┘
class CafeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDeposit = cafe.depositAmount != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Main content row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    _CafeImage(
                      imageUrl: cafe.imageUrl,
                      isSelected: isSelected,
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Info column
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
                                  cafe.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cafe.rating > 0) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _RatingPill(rating: cafe.rating),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Distance + Tables row
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.location_on_outlined,
                                text: _formatDistance(cafe.distanceMeters),
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _MetaChip(
                                icon: Icons.table_restaurant_outlined,
                                text: '${cafe.availableTableCount}/${cafe.totalTableCount} bàn',
                                color: _tableColor(cafe.availableTableCount, cafe.totalTableCount),
                              ),
                              if (cafe.isWaitingForGame && cafe.estimatedWaitMinutes != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _WaitPill(minutes: cafe.estimatedWaitMinutes!),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Seat availability indicator
                          SeatAvailabilityIndicator(
                            cafe: cafe,
                            availability: seatAvailability,
                            showDetailedInfo: showFullDetails,
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Deposit badge (if available)
                          if (hasDeposit) ...[
                            _DepositPill(
                              amount: _formatDepositBvc(cafe.depositAmount!),
                              minutes: cafe.depositMinutesLimit,
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

/// Hình ảnh quán cafe với border xoắn theo trạng thái.
class _CafeImage extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;

  const _CafeImage({required this.imageUrl, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: AppRadius.radiusSmAll,
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
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill hiển thị rating ⭐.
class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: AppSpacing.sm, color: AppColors.warning),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Meta chip nhỏ: icon + text.
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
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Pill thời gian chờ game.
class _WaitPill extends StatelessWidget {
  final int minutes;
  const _WaitPill({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusXsAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: AppSpacing.sm,
            color: AppColors.warningDark,
          ),
          const SizedBox(width: 2),
          Text(
            '~$minutes phút',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill tiền cọc.
class _DepositPill extends StatelessWidget {
  final String amount;
  final int? minutes;

  const _DepositPill({required this.amount, this.minutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_outlined,
            size: AppSpacing.sm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 2),
          Text(
            'Cọc $amount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (minutes != null) ...[
            Text(
              ' / $minutes phút',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
