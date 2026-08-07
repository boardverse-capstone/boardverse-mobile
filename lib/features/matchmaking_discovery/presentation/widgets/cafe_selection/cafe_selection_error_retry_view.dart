import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Error + retry + cập nhật vị trí view dùng trong LobbyCafeSelectionPage.
class CafeSelectionErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onUpdateLocation;
  const CafeSelectionErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: AppSpacing.huge + AppSpacing.xs,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => onUpdateLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text('Cập nhật vị trí'),
            ),
          ],
        ),
      ),
    );
  }
}