import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Một dòng hiển thị cặp (icon + label) — value, dùng trong các card
/// thông tin booking, deposit breakdown, payment summary, v.v.
///
/// Cung cấp 2 kiểu:
/// - [InfoRow] — value là text đơn giản, hỗ trợ multiline/wrap.
/// - [InfoRow.copyable] — kèm nút copy vào clipboard (dùng cho mã đơn).
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Color? iconColor;
  final bool copyable;
  final CrossAxisAlignment columnCross;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.iconColor,
    this.copyable = false,
    this.columnCross = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final fg = iconColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: columnCross == CrossAxisAlignment.start
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.10),
              borderRadius: AppRadius.radiusXxsAll,
            ),
            child: Icon(icon, size: AppIcons.md, color: fg),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: columnCross,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: valueStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Sao chép',
              iconSize: AppIcons.md,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép "$value"'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
                // ignore: deprecated_member_use
                // Clipboard.setData(ClipboardData(text: value));
              },
              icon: Icon(Icons.copy_rounded, color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }
}
