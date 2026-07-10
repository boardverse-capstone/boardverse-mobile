import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/booking_entity.dart';

/// Card hiển thị QR check-in cho Host + deadline.
///
/// BR-04: quán tự chỉ định bàn, nên UI không có `tableNumber`.
class BookingQrCard extends StatelessWidget {
  final BookingEntity booking;

  const BookingQrCard({super.key, required this.booking});

  String _formatVnd(double v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${f.format(v).trim()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = booking.remainingGraceTime;
    final isExpired = booking.isLocallyExpired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mã QR Check-in',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: QrImageView(
                data: booking.qrPayload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(theme, 'Mã đơn', booking.id),
            _infoRow(theme, 'Quán', booking.cafeName),
            _infoRow(theme, 'Game', booking.gameName),
            _infoRow(
              theme,
              'Giờ hẹn',
              DateFormat('HH:mm — dd/MM/yyyy').format(booking.scheduledTime),
            ),
            _infoRow(theme, 'Số ghế', booking.seatCount.toString()),
            _infoRow(theme, 'Cọc', _formatVnd(booking.depositAmount)),
            const Divider(height: 24),
            if (isExpired)
              Text(
                'Đã quá hạn check-in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Vui lòng đến quán trước '
                '${DateFormat('HH:mm').format(booking.depositDeadline)} '
                'để được phục vụ',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            if (!isExpired)
              Text(
                'Còn ${remaining.inMinutes} phút',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}