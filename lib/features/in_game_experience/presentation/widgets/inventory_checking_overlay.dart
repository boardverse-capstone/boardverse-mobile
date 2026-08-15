import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

/// Neo-brutalism inventory checking overlay.
class InventoryCheckingOverlay extends StatelessWidget {
  const InventoryCheckingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Nhân viên đang tiến hành kiểm tra\nlinh kiện hộp game...',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Vui lòng chờ trong giây lát',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}