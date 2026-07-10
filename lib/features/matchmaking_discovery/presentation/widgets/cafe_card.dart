import 'package:flutter/material.dart';

import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import 'seat_availability_indicator.dart';

/// Card widget hiển thị thông tin quán cafe
/// Tích hợp seat availability indicator
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

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Image + Basic Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cafe Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      cafe.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cafe.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${cafe.distanceKm.toStringAsFixed(1)} km',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cafe.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Seat Availability
              SeatAvailabilityIndicator(
                cafe: cafe,
                availability: seatAvailability,
                showDetailedInfo: showFullDetails,
              ),

              // Deposit Info (BR-06)
              if (cafe.depositAmount != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cọc: ${_formatCurrency(cafe.depositAmount!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (cafe.depositMinutesLimit != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Giữ ${cafe.depositMinutesLimit} phút)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Opening Hours
              if (cafe.openingHours != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cafe.openingHours!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],

              // Booking Button
              if (onBookingTap != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cafe.seatStatus == CafeSeatStatus.full
                        ? null
                        : onBookingTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      disabledForegroundColor: theme.colorScheme.outline,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cafe.seatStatus == CafeSeatStatus.full
                          ? 'Hết ghế'
                          : 'Đặt chỗ ngay',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
