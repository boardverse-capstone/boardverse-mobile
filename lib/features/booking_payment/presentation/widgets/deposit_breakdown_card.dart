import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../cubit/booking_summary_state.dart';

/// Card hiển thị breakdown giá đặt cọc — dùng ở `BookingSummaryPage`.
class DepositBreakdownCard extends StatelessWidget {
  final Breakdown breakdown;

  const DepositBreakdownCard({super.key, required this.breakdown});

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
    final pricingLabel = switch (breakdown.pricingModelLabel) {
      'flatEntry' => 'Phí cố định (vé vào cổng)',
      _ => 'Tính theo khối thời gian',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết cọc',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _row(
              theme,
              icon: Icons.access_time,
              label: 'Giá giờ đầu',
              value: _formatVnd(breakdown.firstHourPrice),
            ),
            _row(
              theme,
              icon: Icons.recommend,
              label: 'Cọc khuyến nghị',
              value: _formatVnd(breakdown.recommendedDeposit),
              highlight: true,
            ),
            _row(
              theme,
              icon: Icons.shield_outlined,
              label: 'Cọc tối đa (BR-03)',
              value: _formatVnd(breakdown.maxDeposit),
            ),
            const Divider(height: 16),
            Text(
              'Mô hình giá: $pricingLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}