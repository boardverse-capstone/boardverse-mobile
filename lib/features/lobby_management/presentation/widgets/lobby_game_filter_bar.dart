import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import 'lobby_game_picker_sheet.dart';

/// Filter bar cho phép lọc lobby theo game, bán kính và karma.
class LobbyGameFilterBar extends StatelessWidget {
  final BoardGameEntity? selectedGame;
  final double radiusKm;
  final double minKarma;
  final ValueChanged<BoardGameEntity?> onGameSelected;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onKarmaChanged;
  final VoidCallback onClear;

  const LobbyGameFilterBar({
    super.key,
    required this.selectedGame,
    required this.radiusKm,
    required this.minKarma,
    required this.onGameSelected,
    required this.onRadiusChanged,
    required this.onKarmaChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GameSelector(
            selectedGame: selectedGame,
            theme: theme,
            colors: colors,
            onTap: () => _showGamePicker(context),
            onClear: onClear,
          ),
          if (selectedGame != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RadiusSlider(
              radiusKm: radiusKm,
              colors: colors,
              theme: theme,
              onChanged: onRadiusChanged,
            ),
            _KarmaSlider(
              minKarma: minKarma,
              colors: colors,
              theme: theme,
              onChanged: onKarmaChanged,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showGamePicker(BuildContext context) async {
    final state = context.read<MatchmakingCubit>().state;
    final games = state is MatchmakingSearchResults ? state.games : <BoardGameEntity>[];

    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LobbyGamePickerSheet(games: games),
    );

    if (picked != null) {
      onGameSelected(picked);
    }
  }
}

class _GameSelector extends StatelessWidget {
  final BoardGameEntity? selectedGame;
  final ThemeData theme;
  final ColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _GameSelector({
    required this.selectedGame,
    required this.theme,
    required this.colors,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selectedGame != null
              ? colors.primaryContainer.withValues(alpha: 0.5)
              : colors.surface,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.extension,
              color: selectedGame != null ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                selectedGame?.name ?? 'Chọn game để lọc',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selectedGame != null
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            if (selectedGame != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(Icons.chevron_right, color: colors.outline),
          ],
        ),
      ),
    );
  }
}

class _RadiusSlider extends StatelessWidget {
  final double radiusKm;
  final ColorScheme colors;
  final ThemeData theme;
  final ValueChanged<double> onChanged;

  const _RadiusSlider({
    required this.radiusKm,
    required this.colors,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(AppIcons.location, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text('Bán kính:', style: theme.textTheme.bodySmall),
            const Spacer(),
            Text(
              radiusKm < 1
                  ? '${(radiusKm * 1000).toInt()} m'
                  : '${radiusKm.toStringAsFixed(0)} km',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            thumbColor: colors.primary,
            trackHeight: 4,
          ),
          child: Slider(
            value: radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _KarmaSlider extends StatelessWidget {
  final double minKarma;
  final ColorScheme colors;
  final ThemeData theme;
  final ValueChanged<double> onChanged;

  const _KarmaSlider({
    required this.minKarma,
    required this.colors,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(AppIcons.karma, size: 16, color: colors.tertiary),
            const SizedBox(width: AppSpacing.xs),
            Text('Karma tối thiểu:', style: theme.textTheme.bodySmall),
            const Spacer(),
            Text(
              '${minKarma.toInt()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.tertiary,
            thumbColor: colors.tertiary,
            trackHeight: 4,
          ),
          child: Slider(
            value: minKarma,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
