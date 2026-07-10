import 'package:flutter/material.dart';

/// Badge "Vắng" hiển thị cho booking đã đặt cọc nhưng không đến check-in.
class NoShowBadge extends StatelessWidget {
  const NoShowBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
          const SizedBox(width: 4),
          Text(
            'Vắng',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}