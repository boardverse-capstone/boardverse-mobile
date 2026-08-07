import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../match_summary_rating/presentation/cubit/rating_cubit.dart';
import '../../../match_summary_rating/presentation/cubit/rating_state.dart';
import '../../../match_summary_rating/presentation/widgets/player_rating_card.dart';

/// Phase E — Lobby Karma Rating page.
///
/// Wrapper đơn giản quanh `RatingCubit` của `match_summary_rating`:
/// - Inject đúng `lobbyId` thay vì hard-code `session_001`.
/// - Hiển thị UI Karma Rating tối giản (đánh giá tag + comment) phù hợp với
///   lobby (không cần Elo/match result flow như `RatingPage` đầy đủ).
/// - Sau khi submit xong → pop về root.
class LobbyRatingPage extends StatefulWidget {
  final String lobbyId;
  final String? reservationId;

  const LobbyRatingPage({
    super.key,
    required this.lobbyId,
    this.reservationId,
  });

  @override
  State<LobbyRatingPage> createState() => _LobbyRatingPageState();
}

class _LobbyRatingPageState extends State<LobbyRatingPage> {
  late final RatingCubit _ratingCubit;

  @override
  void initState() {
    super.initState();
    _ratingCubit = getIt<RatingCubit>();
    _ratingCubit.startRatingFlow(widget.lobbyId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocProvider.value(
      value: _ratingCubit,
      child: BlocConsumer<RatingCubit, RatingState>(
        listener: (context, state) {
          if (state is MatchResultEntry) {
            // Lobby flow không cần Elo → skip.
            _ratingCubit.skipMatchResult();
          } else if (state is RatingComplete) {
            Navigator.of(context).pop(true);
          } else if (state is RatingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Đánh giá Karma'),
              leading: IconButton(
                tooltip: 'Đóng',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RatingState state) {
    if (state is RatingLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RatingFailure) {
      return _FailurePanel(
        message: state.message,
        onRetry: () => _ratingCubit.startRatingFlow(widget.lobbyId),
      );
    }

    if (state is KarmaRating) {
      return _KarmaRatingView(
        state: state,
        onToggleTag: (playerId, tagId) =>
            _ratingCubit.toggleKarmaTag(playerId, tagId),
        onSubmit: () => _ratingCubit.submitKarmaRatings(),
      );
    }

    if (state is RatingComplete) {
      return const _SuccessPanel();
    }

    return const Center(child: CircularProgressIndicator());
  }
}

class _KarmaRatingView extends StatelessWidget {
  final KarmaRating state;
  final void Function(String playerId, String tagId) onToggleTag;
  final VoidCallback onSubmit;

  const _KarmaRatingView({
    required this.state,
    required this.onToggleTag,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final canSubmit = state.playerRatings.values.any((t) => t.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: AppRadius.radiusLgAll,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rate,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá trải nghiệm',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Chọn tag mô tả từng thành viên (Karma rating).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Player list
        ...state.playersToRate.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: PlayerRatingCard(
              player: p,
              availableTags: state.availableTags,
              onTagToggle: (playerId, tagId) => onToggleTag(playerId, tagId),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Submit
        FilledButton.icon(
          onPressed: canSubmit ? onSubmit : null,
          icon: const Icon(Icons.check),
          label: const Text('Gửi đánh giá'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Bỏ qua'),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: AppRadius.radiusMdAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Karma rating giúp cộng đồng BoardVerse an toàn hơn. '
                  'Đánh giá của bạn là ẩn danh.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FailurePanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailurePanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: AppSpacing.md),
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
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 80,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cảm ơn bạn đã đánh giá!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Karma của bạn sẽ được cập nhật sau vài phút.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}