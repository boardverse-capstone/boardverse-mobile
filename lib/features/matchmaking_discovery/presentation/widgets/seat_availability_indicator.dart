import 'package:flutter/material.dart';

import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';

/// Widget hiển thị trạng thái ghế của quán
/// Tuân thủ BR-01: Seat-based management
class SeatAvailabilityIndicator extends StatelessWidget {
  final CafeEntity? cafe;
  final SeatAvailabilityEntity? availability;
  final bool isLoading;
  final bool showDetailedInfo;
  final VoidCallback? onTap;

  const SeatAvailabilityIndicator({
    super.key,
    this.cafe,
    this.availability,
    this.isLoading = false,
    this.showDetailedInfo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return _buildLoadingIndicator(theme);
    }

    if (availability != null) {
      return _buildDetailedIndicator(context, theme);
    }

    if (cafe != null) {
      return _buildCafeIndicator(context, theme);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text('Đang kiểm tra...', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCafeIndicator(BuildContext context, ThemeData theme) {
    final status = cafe!.seatStatus;
    final (color, icon, label) = _getStatusInfo(status, cafe!.availableSeats);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedIndicator(BuildContext context, ThemeData theme) {
    final status = availability!.overallStatus;
    final (color, icon, label) = _getOverallStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${availability!.availableSeats}/${availability!.totalSeats} ghế',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (showDetailedInfo) ...[
              const SizedBox(height: 8),
              _buildSeatBreakdown(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeatBreakdown(ThemeData theme) {
    return Column(
      children: [
        _buildSeatRow(
          theme,
          'Đang giữ chờ',
          availability!.holdingSeats,
          Colors.orange,
        ),
        _buildSeatRow(
          theme,
          'Đã đặt cọc',
          availability!.reservedSeats,
          Colors.blue,
        ),
        _buildSeatRow(
          theme,
          'Đang sử dụng',
          availability!.inUseSeats,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildSeatRow(ThemeData theme, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusInfo(
    CafeSeatStatus status,
    int available,
  ) {
    switch (status) {
      case CafeSeatStatus.available:
        return (Colors.green, Icons.event_seat, '$available ghế trống');
      case CafeSeatStatus.limited:
        return (Colors.orange, Icons.warning_amber, 'Còn $available ghế');
      case CafeSeatStatus.full:
        return (Colors.red, Icons.block, 'Hết ghế');
    }
  }

  (Color, IconData, String) _getOverallStatusInfo(SeatOverallStatus status) {
    switch (status) {
      case SeatOverallStatus.plenty:
        return (Colors.green, Icons.event_seat, 'Nhiều ghế trống');
      case SeatOverallStatus.moderate:
        return (Colors.blue, Icons.event_seat, 'Vừa đủ chỗ');
      case SeatOverallStatus.limited:
        return (Colors.orange, Icons.warning_amber, 'Ít ghế trống');
      case SeatOverallStatus.unavailable:
        return (Colors.red, Icons.block, 'Hết ghế');
    }
  }
}
