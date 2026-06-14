import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/booking_qr_entity.dart';

class BookingQrCard extends StatelessWidget {
  final BookingQrEntity booking;

  const BookingQrCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Đặt lịch thành công!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đến quán đúng giờ hẹn và xuất trình mã QR này',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // QR Code Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _QrCodeWidget(data: booking.qrPayload),
            ),
            const SizedBox(height: 16),

            // Booking ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mã đặt chỗ: ${booking.bookingId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Booking Details
            _BookingDetailRow(
              icon: Icons.local_cafe,
              label: 'Quán',
              value: booking.cafeName,
            ),
            const SizedBox(height: 12),
            _BookingDetailRow(
              icon: Icons.extension,
              label: 'Game',
              value: booking.gameName,
            ),
            const SizedBox(height: 12),
            _BookingDetailRow(
              icon: Icons.schedule,
              label: 'Giờ hẹn',
              value: _formatDateTime(booking.scheduledTime),
            ),
            const SizedBox(height: 12),
            _BookingDetailRow(
              icon: Icons.table_restaurant,
              label: 'Bàn',
              value: 'Bàn số ${booking.tableNumber}',
            ),
            const SizedBox(height: 12),
            _BookingDetailRow(
              icon: Icons.people,
              label: 'Người chơi',
              value: booking.playerNames,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} lúc ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _BookingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
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
    );
  }
}

class _QrCodeWidget extends StatelessWidget {
  final String data;

  const _QrCodeWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    // Simple visual representation of QR code
    return CustomPaint(
      size: const Size(200, 200),
      painter: _QrCodePainter(data),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final String data;

  _QrCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final random = Random(data.hashCode);
    final cellSize = size.width / 25;
    final margin = cellSize * 2;

    // Draw QR pattern (simplified visual representation)
    // Corner squares
    _drawPositionPattern(canvas, paint, margin, margin, cellSize);
    _drawPositionPattern(
      canvas,
      paint,
      size.width - margin - cellSize * 7,
      margin,
      cellSize,
    );
    _drawPositionPattern(
      canvas,
      paint,
      margin,
      size.height - margin - cellSize * 7,
      cellSize,
    );

    // Random data cells
    for (var i = 0; i < 200; i++) {
      final x = random.nextDouble() * (size.width - margin * 2) + margin;
      final y = random.nextDouble() * (size.height - margin * 2) + margin;

      // Skip position patterns area
      final inPattern = _isInPositionPattern(x, y, margin, size.width);
      if (!inPattern && random.nextDouble() > 0.5) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: cellSize * 0.8,
            height: cellSize * 0.8,
          ),
          paint,
        );
      }
    }
  }

  void _drawPositionPattern(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double cellSize,
  ) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7), paint);

    // Inner white
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5),
      whitePaint,
    );

    // Center square
    canvas.drawRect(
      Rect.fromLTWH(
        x + cellSize * 2,
        y + cellSize * 2,
        cellSize * 3,
        cellSize * 3,
      ),
      paint,
    );
  }

  bool _isInPositionPattern(double x, double y, double margin, double width) {
    // Check if in any position pattern area
    final inTopLeft =
        x < margin + 7 * (width / 25) && y < margin + 7 * (width / 25);
    final inTopRight =
        x > width - margin - 7 * (width / 25) && y < margin + 7 * (width / 25);
    final inBottomLeft =
        x < margin + 7 * (width / 25) && y > width - margin - 7 * (width / 25);
    return inTopLeft || inTopRight || inBottomLeft;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
