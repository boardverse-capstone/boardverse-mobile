import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';

/// Widget nút đặt chỗ với logic disable khi không đủ ghế (BR-05)
/// Tự động kiểm tra và disable khi số ghế yêu cầu không đủ
class BookingButton extends StatelessWidget {
  final int requiredSeats;
  final CafeEntity? cafe;
  final SeatAvailabilityEntity? availability;
  final bool isLoading;
  final bool isCheckingSeats;
  final VoidCallback? onBookingPressed;
  final VoidCallback? onCheckSeatsPressed;
  final String? errorMessage;

  const BookingButton({
    super.key,
    required this.requiredSeats,
    this.cafe,
    this.availability,
    this.isLoading = false,
    this.isCheckingSeats = false,
    this.onBookingPressed,
    this.onCheckSeatsPressed,
    this.errorMessage,
  });

  bool _hasEnoughSeats() {
    if (availability != null) {
      return availability!.availableSeats >= requiredSeats;
    }
    if (cafe != null) {
      return cafe!.availableSeats >= requiredSeats;
    }
    return false;
  }

  bool _canBook() {
    if (availability != null) {
      return availability!.hasEnoughSeats(requiredSeats);
    }
    if (cafe != null) {
      return cafe!.availableSeats >= requiredSeats &&
          cafe!.seatStatus != CafeSeatStatus.full;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEnoughSeats = _hasEnoughSeats();
    final canBook = _canBook();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          Container(
            padding: AppSpacing.paddingAllSm,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: AppRadius.radiusXsAll,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.onErrorContainer,
                  size: AppSpacing.lg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (availability != null || cafe != null) ...[
          _buildSeatInfoSummary(context, hasEnoughSeats),
          const SizedBox(height: AppSpacing.sm),
        ],
        FilledButton.icon(
          onPressed: _getButtonAction(hasEnoughSeats, canBook),
          icon: _getButtonIcon(hasEnoughSeats),
          label: Text(_getButtonLabel(hasEnoughSeats, canBook)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusSmAll,
            ),
            backgroundColor: _getButtonColor(theme, canBook, hasEnoughSeats),
          ),
        ),
        if (!hasEnoughSeats && errorMessage == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vui lòng chọn quán có đủ $requiredSeats ghế trống',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  VoidCallback? _getButtonAction(bool hasEnough, bool canBook) {
    if (isLoading || isCheckingSeats) return null;
    if (!hasEnough) return onCheckSeatsPressed;
    if (canBook) return onBookingPressed;
    return null;
  }

  Widget _getButtonIcon(bool hasEnough) {
    if (isLoading || isCheckingSeats) {
      return const SizedBox(
        width: AppSpacing.lg,
        height: AppSpacing.lg,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (!hasEnough) {
      return const Icon(Icons.search);
    }
    return const Icon(Icons.book_online);
  }

  String _getButtonLabel(bool hasEnough, bool canBook) {
    if (isLoading) return 'Đang xử lý...';
    if (isCheckingSeats) return 'Đang kiểm tra ghế...';
    if (!hasEnough) return 'Tìm quán khác';
    if (canBook) return 'Đặt chỗ ngay';
    return 'Không thể đặt';
  }

  Color _getButtonColor(ThemeData theme, bool canBook, bool hasEnough) {
    if (isLoading || isCheckingSeats) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    if (canBook) {
      return theme.colorScheme.primary;
    }
    if (!hasEnough) {
      return AppColors.warning;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  Widget _buildSeatInfoSummary(BuildContext context, bool hasEnough) {
    final theme = Theme.of(context);
    final availableCount = availability?.availableSeats ?? cafe!.availableSeats;
    final totalCount = availability?.totalSeats ?? cafe!.totalSeats;
    final color = hasEnough ? AppColors.success : AppColors.warning;

    return Container(
      padding: AppSpacing.paddingAllSm,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusXsAll,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            hasEnough ? Icons.check_circle : Icons.warning_amber,
            color: color,
            size: AppSpacing.xl,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasEnough
                      ? 'Đủ ghế cho nhóm của bạn'
                      : 'Không đủ ghế trống',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '$availableCount/$totalCount ghế trống • Yêu cầu: $requiredSeats ghế',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}