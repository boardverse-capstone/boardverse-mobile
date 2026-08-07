import 'package:flutter/material.dart';

/// Section title dùng trong [CafeDetailPage] — heading nhỏ + primary color.
class CafeSectionTitle extends StatelessWidget {
  final String title;

  const CafeSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}