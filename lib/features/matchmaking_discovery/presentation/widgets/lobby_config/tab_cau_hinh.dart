import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'bottom_button.dart';
import 'compact_slider.dart';

/// Tab 3 của LobbyConfigPage — số người, chế độ, advanced settings.
class LobbyConfigTabCauHinh extends StatelessWidget {
  final int maxPlayers;
  final int minPlayers;
  final int selectedMaxPlayers;
  final bool isPublic;
  final bool showAdvanced;
  final double minimumKarma;
  final double searchRadiusKm;
  final ValueChanged<int> onMaxPlayersChanged;
  final ValueChanged<bool> onPublicChanged;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<double> onKarmaChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onNext;

  const LobbyConfigTabCauHinh({
    super.key,
    required this.maxPlayers,
    required this.minPlayers,
    required this.selectedMaxPlayers,
    required this.isPublic,
    required this.showAdvanced,
    required this.minimumKarma,
    required this.searchRadiusKm,
    required this.onMaxPlayersChanged,
    required this.onPublicChanged,
    required this.onToggleAdvanced,
    required this.onKarmaChanged,
    required this.onRadiusChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = List.generate(
      maxPlayers - minPlayers + 1,
      (i) => minPlayers + i,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player count
                Text(
                  'Số người chơi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Bao gồm bạn (host). Tối thiểu $minPlayers người.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: counts.map((count) {
                    final isSelected = count == selectedMaxPlayers;
                    return GestureDetector(
                      onTap: () => onMaxPlayersChanged(count),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: AppRadius.radiusSmAll,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Visibility
                Text(
                  'Chế độ phòng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onPublicChanged(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isPublic
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: AppRadius.radiusMdAll,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.public,
                                  color: isPublic
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Công khai',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: isPublic ? FontWeight.bold : FontWeight.normal,
                                    color: isPublic
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onPublicChanged(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: !isPublic
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: AppRadius.radiusMdAll,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: !isPublic
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Riêng tư',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: !isPublic ? FontWeight.bold : FontWeight.normal,
                                    color: !isPublic
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Advanced toggle
                GestureDetector(
                  onTap: onToggleAdvanced,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.radiusFullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showAdvanced ? Icons.settings : Icons.settings_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          showAdvanced ? 'Ẩn nâng cao' : 'Tuỳ chọn nâng cao',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Icon(
                          showAdvanced ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (showAdvanced) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: AppRadius.radiusMdAll,
                    ),
                    child: Column(
                      children: [
                        LobbyConfigCompactSlider(
                          icon: Icons.star,
                          label: 'Karma tối thiểu',
                          valueLabel: '${minimumKarma.toInt()} điểm',
                          value: minimumKarma,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: onKarmaChanged,
                        ),
                        const Divider(height: AppSpacing.lg),
                        LobbyConfigCompactSlider(
                          icon: Icons.radar,
                          label: 'Bán kính tìm kiếm',
                          valueLabel: '${searchRadiusKm.toStringAsFixed(1)} km',
                          value: searchRadiusKm,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          onChanged: onRadiusChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        LobbyConfigBottomButton(
          label: 'Xem thông tin cọc',
          onPressed: onNext,
        ),
      ],
    );
  }
}