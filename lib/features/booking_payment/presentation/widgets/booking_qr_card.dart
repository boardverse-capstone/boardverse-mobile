import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import 'booking_ui_helpers.dart';
import 'info_row.dart';

/// Card hiển thị QR check-in cho Host + deadline.
///
/// BR-04: quán tự chỉ định bàn, nên UI không có `tableNumber`.
class BookingQrCard extends StatelessWidget {
  final BookingEntity booking;

  const BookingQrCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = booking.remainingGraceTime;
    final isExpired = booking.isLocallyExpired;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppElevation.shadowXxs,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.radiusSmAll,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: AppIcons.md,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Mã QR Check-in',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppColorsDark.surfaceElevated
                          : AppColors.surface,
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: QrImageView(
                      data: booking.qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.transparent,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Mã đơn',
                    value: booking.id,
                    iconColor: AppColors.secondary,
                    copyable: true,
                  ),
                  InfoRow(
                    icon: AppIcons.cafe,
                    label: 'Quán',
                    value: booking.cafeName,
                    iconColor: AppColors.secondary,
                  ),
                  InfoRow(
                    icon: AppIcons.boardGame,
                    label: 'Game',
                    value: booking.gameName,
                    iconColor: AppColors.primary,
                  ),
                  InfoRow(
                    icon: AppIcons.schedule,
                    label: 'Giờ hẹn',
                    value: BookingUiHelpers.formatDateTime(
                        booking.scheduledTime,
                        pattern: 'HH:mm — dd/MM/yyyy'),
                  ),
                  InfoRow(
                    icon: AppIcons.users,
                    label: 'Số ghế',
                    value: booking.seatCount.toString(),
                  ),
                  InfoRow(
                    icon: AppIcons.money,
                    label: 'Cọc',
                    value: BookingUiHelpers.formatVnd(booking.depositAmount),
                    iconColor: AppColors.warning,
                  ),
                ],
              ),
            ),
            if (isExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.radiusLg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off_rounded,
                        size: AppIcons.md, color: AppColors.error),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Đã quá hạn check-in',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.radiusLg),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: AppIcons.sm, color: AppColors.info),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            'Vui lòng đến quán trước '
                            '${DateFormat('HH:mm').format(booking.depositDeadline)} '
                            'để được phục vụ',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.tagRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: AppIcons.xs, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            'Còn ${remaining.inMinutes} phút',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
