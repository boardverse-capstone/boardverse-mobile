import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class PlayModeSelectionPage extends StatelessWidget {
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;

  const PlayModeSelectionPage({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn chế độ chơi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextCard(
                gameName: gameName,
                cafeName: cafeName,
                theme: theme,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bạn muốn chơi cùng ai?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn chế độ phù hợp với nhóm của bạn để bắt đầu trải nghiệm BoardVerse.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _PlayModeCard(
                      icon: AppIcons.user,
                      title: 'Chơi một mình',
                      description: 'Đặt bàn trực tiếp tại quán',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chức năng đặt bàn đơn đang phát triển',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PlayModeCard(
                      icon: AppIcons.users,
                      title: 'Chơi cùng nhóm',
                      description: 'Tạo hoặc tham gia phòng chờ online',
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _LobbyConfigPlaceholder(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String gameName;
  final String cafeName;
  final ThemeData theme;

  const _ContextCard({
    required this.gameName,
    required this.cafeName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? AppColorsDark.cardGradientOrange
              : AppColors.cardGradientOrange,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppElevation.shadowMd,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Icon(
              AppIcons.boardGame,
              size: AppIcons.xxl,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      AppIcons.cafe,
                      size: AppIcons.sm,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        cafeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PlayModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isPrimary ? colors.primaryContainer : colors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isPrimary ? colors.primary : colors.outlineVariant,
              width: isPrimary ? 1.5 : 1,
            ),
            boxShadow: isPrimary
                ? AppElevation.shadowMd
                : AppElevation.shadowXs,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  borderRadius: AppRadius.radiusMdAll,
                ),
                child: Icon(
                  icon,
                  size: AppIcons.xl,
                  color: isPrimary ? colors.onPrimary : colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPrimary
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isPrimary ? colors.onPrimaryContainer : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyConfigPlaceholder extends StatelessWidget {
  const _LobbyConfigPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cấu hình phòng')),
      body: const Center(child: Text('Module 2 - Lobby Config')),
    );
  }
}
