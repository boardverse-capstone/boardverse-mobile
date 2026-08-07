import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Info row đơn giản — icon + text, dùng cho CafeDetail.
class CafeInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const CafeInfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}