import 'package:flutter/material.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';

/// Loading scaffold cho LobbyPage.
class LobbyLoadingScaffold extends StatelessWidget {
  const LobbyLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phòng chờ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đang vào phòng...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Failure scaffold cho LobbyPage.
class LobbyFailureScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LobbyFailureScaffold({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng chờ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.error,
                  size: AppIcons.massive,
                  color: colors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Không thể vào phòng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LobbyGradientButton(
                isActive: true,
                label: 'Thử lại',
                icon: AppIcons.refresh,
                onTap: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient button dùng chung cho Lobby.
class LobbyGradientButton extends StatelessWidget {
  final bool isActive;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const LobbyGradientButton({
    super.key,
    required this.isActive,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [colors.primary, colors.primary.withAlpha(204)],
              )
            : null,
        color: isActive ? null : colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.white : colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
