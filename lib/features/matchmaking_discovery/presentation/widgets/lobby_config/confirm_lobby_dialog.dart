import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../reservation/domain/entities/entities.dart';
import 'dialog_row.dart';

/// Dialog xác nhận tạo lobby — hiển thị thông tin + quote + buffer.
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

    return AlertDialog(
      title: const Text('Xác nhận tạo phòng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiểm tra thông tin trước khi đặt cọc:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            LobbyConfigDialogRow(icon: Icons.extension, label: 'Game', value: gameName),
            LobbyConfigDialogRow(icon: Icons.local_cafe, label: 'Quán', value: cafeName),
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cọc cần trả:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${quotePreview!.finalDeposit} BVC',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Buffer: ${formatBuffer(bufferMinutes)} để tuyển người',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Quay lại chỉnh sửa'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Đặt cọc ngay'),
        ),
      ],
    );
  }
}