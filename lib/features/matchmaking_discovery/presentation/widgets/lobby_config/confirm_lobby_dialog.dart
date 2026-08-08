import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../reservation/domain/entities/entities.dart';
import 'dialog_row.dart';

/// Neo-brutalism Dialog xác nhận tạo lobby.
class LobbyConfigConfirmDialog extends StatelessWidget {
  final String cafeName;
  final String gameName;
  final DateTime selectedDate;
  final TimeSlot selectedTimeSlot;
  final TimeOfDay? preferredStartTime;
  final int maxPlayers;
  final bool isPublic;
  final double minimumKarma;
  final double searchRadiusKm;
  final ReservationQuoteEntity? quotePreview;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;
  final String Function(TimeSlot) getSlotLabel;
  final String Function(int) formatBuffer;
  final int bufferMinutes;

  const LobbyConfigConfirmDialog({
    super.key,
    required this.cafeName,
    required this.gameName,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.preferredStartTime,
    required this.maxPlayers,
    required this.isPublic,
    required this.minimumKarma,
    required this.searchRadiusKm,
    required this.quotePreview,
    required this.formatDate,
    required this.formatTime,
    required this.getSlotLabel,
    required this.formatBuffer,
    required this.bufferMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
      ),
      title: const Text(
        'XÁC NHẬN TẠO PHÒNG',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiểm tra thông tin trước khi đặt cọc:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            LobbyConfigDialogRow(
              icon: Icons.extension,
              label: 'Game',
              value: gameName,
            ),
            LobbyConfigDialogRow(
              icon: Icons.local_cafe,
              label: 'Quán',
              value: cafeName,
            ),
            LobbyConfigDialogRow(
              icon: Icons.calendar_today,
              label: 'Ngày',
              value: formatDate(selectedDate),
            ),
            LobbyConfigDialogRow(
              icon: Icons.access_time,
              label: 'Phiên',
              value: getSlotLabel(selectedTimeSlot),
            ),
            if (preferredStartTime != null)
              LobbyConfigDialogRow(
                icon: Icons.schedule,
                label: 'Giờ',
                value: formatTime(preferredStartTime!),
              ),
            LobbyConfigDialogRow(
              icon: Icons.people,
              label: 'Số người',
              value: '$maxPlayers người',
            ),
            LobbyConfigDialogRow(
              icon: isPublic ? Icons.public : Icons.lock,
              label: 'Chế độ',
              value: isPublic ? 'Công khai' : 'Riêng tư',
            ),

            if (quotePreview != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: AppSpacing.paddingAllSm,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CỌC CẦN TRẢ:',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${quotePreview!.finalDeposit} BVC',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_bottom,
                      color: AppColors.warningDark,
                      size: 14,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Buffer: ${formatBuffer(bufferMinutes)} để tuyển người',
                      style: const TextStyle(
                        color: AppColors.warningDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'QUAY LẠI',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.black,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context, true),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'ĐẶT CỌC NGAY',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
