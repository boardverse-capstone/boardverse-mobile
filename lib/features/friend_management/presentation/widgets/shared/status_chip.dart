import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';

/// Neo-brutalism Status chip widget for displaying friendship status.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 12,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}