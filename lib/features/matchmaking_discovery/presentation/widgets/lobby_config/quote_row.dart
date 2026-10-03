import 'package:flutter/material.dart';

/// Neo-brutalism Quote row — label/value.
class LobbyConfigQuoteRow extends StatelessWidget {
  final String label;
  final String value;

  /// Optional color override cho `value`. Mặc định theo `onSurface`
  /// (đậm, dễ đọc). Dùng khi cần highlight giá trị cảnh báo (vd: hệ
  /// số rủi ro > 1.0 → tô cam warning để player chú ý).
  final Color? valueColor;

  const LobbyConfigQuoteRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
